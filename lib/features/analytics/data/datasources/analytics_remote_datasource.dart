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
      
      // Filtros
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      
      // Si el filtro incluye HOY (default o explícito), usamos stream para hoy
      // y future para histórico si es necesario.
      
      // CASO 1: Default (HOY) -> Muestra tendencia ultimos 7 dias
      // Estrategia: Stream HOY + Future (ayer - 6 dias)
      if (dateFilter == null || dateFilter == DateFilter.today) {
         // Rango histórico: hace 6 días hasta ayer a las 23:59:59
         final historyStart = startOfToday.subtract(const Duration(days: 6));
         final historyEnd = startOfToday; // Exclusivo (hasta las 00:00 de hoy)
         
         // Stream de hoy (Tiempo real)
         final todayQuery = collection
            .where('creation', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .orderBy('creation', descending: true);
            
         // Query histórico (One-time fetch)
         final historyQuery = collection
            .where('creation', isGreaterThanOrEqualTo: Timestamp.fromDate(historyStart))
            .where('creation', isLessThan: Timestamp.fromDate(historyEnd))
            .orderBy('creation', descending: true);

         // Combinar: Stream de hoy se combina con resultado estático de historial
         return _dataSource.streamDocuments(todayQuery).asyncMap((todaySnap) async {
            // Nota: Podríamos cachear el resultado de history para no pedirlo en cada evento del stream
            // Pero por simplicidad en esta iteración lo hacemos así. Idealmente history se pide una vez fuera.
            
            // TODO: Optimización futura -> Cachear historyTickets en memoria o Hive
            final historySnap = await _dataSource.getDocuments(historyQuery);
            
            final todayTickets = todaySnap.docs.map((doc) => TicketModel.fromMap(doc.data())).toList();
            final historyTickets = historySnap.docs.map((doc) => TicketModel.fromMap(doc.data())).toList();
            
            final allTickets = [...todayTickets, ...historyTickets];
            
            if (kDebugMode) {
              debugPrint('📊 [Analytics] Optimizado: ${todayTickets.length} hoy + ${historyTickets.length} estáticos');
            }
            
            return SalesAnalyticsModel.fromTickets(allTickets);
         });
      }
      
      // CASO 2: Filtros Históricos (Ayer, Esta semana, etc)
      // Estrategia: One-time fetch sin stream (los datos pasados no cambian)
      final (startDate, endDate) = _getDateRangeForFilter(dateFilter);
      final query = collection
            .where('creation', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('creation', isLessThan: Timestamp.fromDate(endDate))
            .orderBy('creation', descending: true);
            
      // Usamos Stream.fromFuture para mantener la firma del método, 
      // pero internamente es una sola lectura.
      return Stream.fromFuture(_dataSource.getDocuments(query)).map((snapshot) {
         final tickets = snapshot.docs.map((doc) => TicketModel.fromMap(doc.data())).toList();
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

  (DateTime, DateTime) _getDateRangeForFilter(DateFilter filter) {
     // Lógica simplificada ya que manejamos "Hoy" arriba
     if (filter == DateFilter.today) {
       // Este caso no se debería alcanzar por el if de arriba, pero por seguridad:
       final now = DateTime.now();
       return (
          DateTime(now.year, now.month, now.day), 
          now.add(const Duration(days: 1))
       );
     }
     if (filter == DateFilter.yesterday) {
        // Ayer: Rango extendido para tendencia de 7 días terminar en ayer
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        return (
          yesterday.subtract(const Duration(days: 6)), 
          DateTime(now.year, now.month, now.day) // Hasta inicio de hoy
        );
     }
     return filter.getDateRange();
  }
}
