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
  /// **Estrategia de carga:**
  /// - `Hoy`: Carga últimos 7 días para mostrar tendencia semanal
  /// - `Ayer`: Carga últimos 7 días (hasta hoy) para contexto completo
  /// - `Otros filtros`: Carga rango completo sin límite artificial
  ///
  /// **Nota:** Para filtros de día único se cargan más días para permitir
  /// visualización de tendencia semanal en el gráfico de días.
  Stream<SalesAnalyticsModel> getTransactions(
    String accountId, {
    DateFilter? dateFilter,
  }) {
    try {
      final path = FirestorePaths.accountTransactions(accountId);
      final collection = _dataSource.collection(path);
      Query<Map<String, dynamic>> query = collection;

      if (dateFilter != null) {
        final (startDate, endDate) = _getDateRangeForFilter(dateFilter);

        query = query
            .where('creation',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('creation', isLessThan: Timestamp.fromDate(endDate))
            .orderBy('creation', descending: true);

        if (kDebugMode) {
          debugPrint('📊 [Analytics] Filtro: ${dateFilter.name} '
              '(${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month})');
        }
      } else {
        // Sin filtro = hoy por defecto
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
          debugPrint('📊 [Analytics] ${tickets.length} tickets cargados');
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

  /// Calcula el rango de fechas según el filtro seleccionado
  ///
  /// **Para filtros de día único (hoy/ayer):**
  /// - Retorna últimos 7 días para permitir visualización de tendencia
  ///
  /// **Para otros filtros:**
  /// - Retorna el rango estándar definido por el filtro
  (DateTime, DateTime) _getDateRangeForFilter(DateFilter filter) {
    final now = DateTime.now();

    // Estrategia especial para filtros de día único
    if (filter == DateFilter.today || filter == DateFilter.yesterday) {
      if (filter == DateFilter.today) {
        // "Hoy": cargar [hace6, hace5, hace4, hace3, hace2, hace1, hoy]
        final today = DateTime(now.year, now.month, now.day);
        return (
          today.subtract(const Duration(days: 6)), // Inicio: hace 6 días
          today.add(const Duration(days: 1)), // Fin: mañana (exclusivo)
        );
      } else {
        // "Ayer": cargar [hace6 antes de ayer ... hoy] = 7 días incluyendo hoy
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        return (
          yesterday.subtract(
              const Duration(days: 6)), // Inicio: hace 6 días desde ayer
          DateTime(now.year, now.month, now.day + 1), // Fin: mañana (exclusivo)
        );
      }
    }

    // Otros filtros: delegar al rango estándar del filtro
    return filter.getDateRange();
  }
}
