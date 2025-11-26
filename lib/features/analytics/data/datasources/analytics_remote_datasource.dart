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
    Query<Map<String, dynamic>> query = _firestore
        .collection('/ACCOUNTS')
        .doc(accountId)
        .collection('TRANSACTIONS');

    // Aplicar filtro de fecha si existe
    if (dateFilter != null) {
      final (startDate, endDate) = dateFilter.getDateRange();
      query = query
          .where('creation', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('creation', isLessThan: Timestamp.fromDate(endDate));
    }

    // Ordenar por fecha de creación descendente
    query = query.orderBy('creation', descending: true);

    final querySnapshot = await query.get();

    // Convertir documentos a TicketModel
    final tickets = querySnapshot.docs.map((doc) {
      return TicketModel.fromMap(doc.data());
    }).toList();

    // Calcular métricas y retornar modelo
    return SalesAnalyticsModel.fromTickets(tickets);
  }
}
