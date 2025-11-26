import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import '../../domain/entities/date_filter.dart';
import '../models/sales_analytics_model.dart';

/// DataSource: Analíticas Remoto
///
/// **Responsabilidad:**
/// - Consultar Firestore para obtener datos de tickets
/// - Filtrar tickets por rango de fechas
/// - Calcular métricas y retornar modelo
///
/// **Colección consultada:** ACCOUNTS/{accountId}/TRANSACTIONS
/// **Inyección DI:** @lazySingleton
@lazySingleton
class AnalyticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  AnalyticsRemoteDataSource(this._firestore);

  /// Obtiene las transacciones desde Firestore con filtro de fecha opcional
  ///
  /// [accountId] ID de la cuenta
  /// [dateFilter] Filtro de fecha opcional (null = todas las transacciones)
  ///
  /// Throws [Exception] si falla la consulta
  ///
  /// **NOTA sobre Performance:**
  /// Para cuentas con muchos tickets, considerar implementar:
  /// - Paginación con límite de documentos
  /// - Caché local con timestamp de última actualización
  /// - Agregación server-side cuando Firestore lo soporte
  Future<SalesAnalyticsModel> getTransactions(
    String accountId, {
    DateFilter? dateFilter,
  }) async {
    try {
      print('📊 [Analytics] Iniciando consulta de transacciones');
      print('   AccountId: $accountId');
      print('   DateFilter: ${dateFilter?.name ?? "null (todas las transacciones)"}');

      Query<Map<String, dynamic>> query = _firestore
          .collection('/ACCOUNTS')
          .doc(accountId)
          .collection('TRANSACTIONS');

      // Aplicar filtro de fecha si existe
      if (dateFilter != null) {
        final (startDate, endDate) = dateFilter.getDateRange();
        
        // Log detallado para debugging
        print('📊 [Analytics] Aplicando filtro de fecha:');
        print('   Desde: $startDate');
        print('   Hasta: $endDate');
        print('   Timestamp Start: ${Timestamp.fromDate(startDate)}');
        print('   Timestamp End: ${Timestamp.fromDate(endDate)}');
        
        query = query
            .where('creation', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('creation', isLessThan: Timestamp.fromDate(endDate))
            .orderBy('creation', descending: true);
      } else {
        // Sin filtro, solo ordenar
        print('📊 [Analytics] Sin filtro de fecha, obteniendo todas las transacciones');
        query = query.orderBy('creation', descending: true);
      }

      print('📊 [Analytics] Ejecutando query a Firestore...');
      final querySnapshot = await query.get();
      
      print('📊 [Analytics] Documentos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ [Analytics] No se encontraron transacciones');
        print('   Verifica que:');
        print('   1. Las transacciones se estén guardando en /ACCOUNTS/$accountId/TRANSACTIONS/');
        print('   2. El campo "creation" sea de tipo Timestamp');
        print('   3. Los índices de Firestore estén correctamente configurados');
      }

      // Convertir documentos a TicketModel
      final tickets = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print('📝 [Analytics] Procesando doc: ${doc.id}, creation: ${data['creation']}');
          return TicketModel.fromMap(data);
        } catch (e) {
          print('❌ [Analytics] Error convirtiendo documento ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      print('✅ [Analytics] Tickets procesados correctamente: ${tickets.length}');

      // Calcular métricas y retornar modelo
      final analyticsModel = SalesAnalyticsModel.fromTickets(tickets);
      print('📊 [Analytics] Métricas calculadas:');
      print('   Total Transacciones: ${analyticsModel.totalTransactions}');
      print('   Total Ventas: ${analyticsModel.totalSales}');
      
      return analyticsModel;
    } catch (e, stackTrace) {
      print('❌ [Analytics] Error en consulta: $e');
      print('❌ [Analytics] StackTrace: $stackTrace');
      
      // Verificar si es un error de índice de Firestore
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        print('⚠️ [Analytics] Error de índice detectado:');
        print('   Asegúrate de que los índices de Firestore estén desplegados correctamente.');
        print('   Ejecuta: firebase deploy --only firestore:indexes');
      }
      
      rethrow;
    }
  }
}
