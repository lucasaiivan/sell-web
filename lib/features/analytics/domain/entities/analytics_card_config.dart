/// Modelo que representa una tarjeta de analíticas configurable
///
/// **Propósito:**
/// - Definir la configuración de cada tarjeta (tamaño, posición, etc.)
/// - Permitir reordenamiento por el usuario
/// - Soportar diferentes tipos de tarjetas (métrica, gráfico, lista)
class AnalyticsCardConfig {
  /// Identificador único de la tarjeta
  final String id;

  /// Número de columnas que ocupa la tarjeta
  final int crossAxisCellCount;

  /// Tipo de tarjeta para el builder
  final AnalyticsCardType type;

  /// Orden de visualización (menor = primero)
  final int order;

  /// Si está visible en el dashboard
  final bool isVisible;

  const AnalyticsCardConfig({
    required this.id,
    required this.crossAxisCellCount,
    required this.type,
    required this.order,
    this.isVisible = true,
  });

  /// Crea una copia con valores modificados
  AnalyticsCardConfig copyWith({
    String? id,
    int? crossAxisCellCount,
    AnalyticsCardType? type,
    int? order,
    bool? isVisible,
  }) {
    return AnalyticsCardConfig(
      id: id ?? this.id,
      crossAxisCellCount: crossAxisCellCount ?? this.crossAxisCellCount,
      type: type ?? this.type,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Tipos de tarjetas disponibles en el dashboard de analytics
enum AnalyticsCardType {
  billing,        // Facturación
  profit,         // Ganancia
  sales,          // Ventas (cantidad)
  averageTicket,  // Ticket promedio
  products,       // Productos vendidos
  profitability,  // Rentabilidad
  sellerRanking,  // Ranking de vendedores
  peakHours,      // Horas pico
  slowMoving,     // Productos de lenta rotación
  salesTrend,     // Tendencia de ventas
  categoryDist,   // Distribución por categorías
  weekdaySales,   // Ventas por día de la semana
  paymentMethods, // Medios de pago
  cashRegisters,  // Cajas activas
}

/// Extensión para obtener configuración por defecto de cada tipo
extension AnalyticsCardTypeExtension on AnalyticsCardType {
  /// Configuración por defecto para desktop (6 columnas)
  AnalyticsCardConfig get defaultDesktopConfig {
    switch (this) {
      case AnalyticsCardType.billing:
        return AnalyticsCardConfig(
          id: 'billing',
          crossAxisCellCount: 2,
          type: this,
          order: 0,
        );
      case AnalyticsCardType.profit:
        return AnalyticsCardConfig(
          id: 'profit',
          crossAxisCellCount: 2,
          type: this,
          order: 1,
        );
      case AnalyticsCardType.sales:
        return AnalyticsCardConfig(
          id: 'sales',
          crossAxisCellCount: 1,
          type: this,
          order: 2,
        );
      case AnalyticsCardType.averageTicket:
        return AnalyticsCardConfig(
          id: 'averageTicket',
          crossAxisCellCount: 1,
          type: this,
          order: 3,
        );
      case AnalyticsCardType.products:
        return AnalyticsCardConfig(
          id: 'products',
          crossAxisCellCount: 2,
          type: this,
          order: 4,
        );
      case AnalyticsCardType.profitability:
        return AnalyticsCardConfig(
          id: 'profitability',
          crossAxisCellCount: 2,
          type: this,
          order: 5,
        );
      case AnalyticsCardType.sellerRanking:
        return AnalyticsCardConfig(
          id: 'sellerRanking',
          crossAxisCellCount: 2,
          type: this,
          order: 6,
        );
      case AnalyticsCardType.peakHours:
        return AnalyticsCardConfig(
          id: 'peakHours',
          crossAxisCellCount: 2,
          type: this,
          order: 7,
        );
      case AnalyticsCardType.slowMoving:
        return AnalyticsCardConfig(
          id: 'slowMoving',
          crossAxisCellCount: 2,
          type: this,
          order: 8,
        );
      case AnalyticsCardType.salesTrend:
        return AnalyticsCardConfig(
          id: 'salesTrend',
          crossAxisCellCount: 3,
          type: this,
          order: 9,
        );
      case AnalyticsCardType.categoryDist:
        return AnalyticsCardConfig(
          id: 'categoryDist',
          crossAxisCellCount: 3,
          type: this,
          order: 10,
        );
      case AnalyticsCardType.weekdaySales:
        return AnalyticsCardConfig(
          id: 'weekdaySales',
          crossAxisCellCount: 3,
          type: this,
          order: 11,
        );
      case AnalyticsCardType.paymentMethods:
        return AnalyticsCardConfig(
          id: 'paymentMethods',
          crossAxisCellCount: 3,
          type: this,
          order: 12,
        );
      case AnalyticsCardType.cashRegisters:
        return AnalyticsCardConfig(
          id: 'cashRegisters',
          crossAxisCellCount: 3,
          type: this,
          order: 13,
        );
    }
  }

  /// Configuración por defecto para tablet (4 columnas)
  AnalyticsCardConfig get defaultTabletConfig {
    switch (this) {
      case AnalyticsCardType.billing:
        return AnalyticsCardConfig(
          id: 'billing',
          crossAxisCellCount: 2,
          type: this,
          order: 0,
        );
      case AnalyticsCardType.profit:
        return AnalyticsCardConfig(
          id: 'profit',
          crossAxisCellCount: 2,
          type: this,
          order: 1,
        );
      case AnalyticsCardType.sales:
        return AnalyticsCardConfig(
          id: 'sales',
          crossAxisCellCount: 1,
          type: this,
          order: 2,
        );
      case AnalyticsCardType.averageTicket:
        return AnalyticsCardConfig(
          id: 'averageTicket',
          crossAxisCellCount: 1,
          type: this,
          order: 3,
        );
      default:
        return AnalyticsCardConfig(
          id: name,
          crossAxisCellCount: 2,
          type: this,
          order: index + 4,
        );
    }
  }
}
