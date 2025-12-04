import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import '../../domain/entities/date_filter.dart';
import '../models/sales_analytics_model.dart';

/// DataSource: Analíticas Remoto
///
/// **Responsabilidad:**
/// - Consultar Firestore con estrategia inteligente según período
/// - Usar streaming para períodos cortos, consulta única para largos
/// - Sin límite arbitrario: carga todos los documentos del rango
@lazySingleton
class AnalyticsRemoteDataSource {
  final IFirestoreDataSource _dataSource;

  AnalyticsRemoteDataSource(this._dataSource);

  /// Obtiene transacciones con estrategia adaptativa según el filtro
  ///
  /// **Estrategia:**
  /// - Hoy/Ayer: Stream en tiempo real (pocos documentos, actualización instantánea)
  /// - Otros filtros: Stream del rango completo (sin límite artificial)
  ///
  /// Las métricas siempre se calculan con TODOS los datos del rango.
  /// El límite de visualización se maneja en la UI, no aquí.
  Stream<SalesAnalyticsModel> getTransactions(
    String accountId, {
    DateFilter? dateFilter,
  }) {
    try {
      final path = FirestorePaths.accountTransactions(accountId);
      final collection = _dataSource.collection(path);
      Query<Map<String, dynamic>> query = collection;

      // Aplicar filtro de fecha
      if (dateFilter != null) {
        final (startDate, endDate) = dateFilter.getDateRange();

        if (kDebugMode) {
          debugPrint('📊 [Analytics] Filtro: ${dateFilter.name} '
              '(~${dateFilter.estimatedDays} días)');
        }

        query = query
            .where('creation',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('creation', isLessThan: Timestamp.fromDate(endDate))
            .orderBy('creation', descending: true);
      } else {
        // Sin filtro = hoy por defecto (para evitar cargar todo el historial)
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        query = query
            .where('creation',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .orderBy('creation', descending: true);
      }

      return _dataSource.streamDocuments(query).map((querySnapshot) {
        final tickets = querySnapshot.docs.map((doc) {
          return TicketModel.fromMap(doc.data());
        }).toList();

        if (kDebugMode) {
          debugPrint('📊 [Analytics] ${tickets.length} tickets en rango');
        }

        return SalesAnalyticsModel.fromTickets(tickets);
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [Analytics] Error: $e');
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }
}
