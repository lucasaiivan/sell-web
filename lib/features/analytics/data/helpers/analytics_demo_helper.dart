import 'package:sellweb/core/services/demo_account/demo_account_service.dart';
import 'package:sellweb/core/services/demo_account/generators/sales_demo_generator.dart';
import 'package:sellweb/features/analytics/data/models/sales_analytics_model.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';

/// Helper para generar SalesAnalytics desde tickets demo
///
/// **Responsabilidad:**
/// - Delegar generación de tickets a DemoAccountService
/// - Calcular métricas completas (totales, promedios, top products, etc.)
/// - Generar estructura SalesAnalytics lista para consumir en UI
class AnalyticsDemoHelper {
  /// Genera SalesAnalytics completo con datos demo del último año
  /// 
  /// Genera 500 transacciones distribuidas en el último año con mayor
  /// concentración en los últimos 60 días, garantizando datos suficientes
  /// para demostración completa de todas las analíticas
  static SalesAnalytics generateDemoAnalytics() {
    // Obtener tickets anuales desde el servicio centralizado
    final tickets = DemoAccountService().getTickets(scope: DemoTicketScope.annual);
    
    // Usar SalesAnalyticsModel.fromTickets() que tiene toda la lógica
    // de cálculo de métricas, incluyendo ganancias y productos de lenta rotación
    return SalesAnalyticsModel.fromTickets(tickets);
  }
}
