import 'package:equatable/equatable.dart';

/// Entity: Datos de Tendencia
///
/// **Responsabilidad:**
/// - Representar datos de tendencia calculados con granularidad específica
/// - Almacenar puntos de datos con su etiqueta y valor
///
/// **Granularidades soportadas:**
/// - Horas (para filtros de día: hoy, ayer)
/// - Días (para filtros de mes: este mes, mes pasado)
/// - Meses (para filtros de año: este año, año pasado)
class TrendData extends Equatable {
  /// Granularidad de los datos (hour, day, month)
  final TrendGranularity granularity;

  /// Puntos de datos para el gráfico
  /// Cada punto contiene: label (ej: "09:00", "15 Mar", "Enero"), value (ventas totales), count (transacciones)
  final List<TrendDataPoint> dataPoints;

  /// Porcentaje de tendencia calculado (positivo = crecimiento, negativo = decrecimiento)
  final double trendPercentage;

  /// Valor máximo en los datos (para escalado de gráficos)
  final double maxValue;

  /// Valor mínimo en los datos (para escalado de gráficos)
  final double minValue;

  /// Total de ventas del período
  final double totalSales;

  /// Total de transacciones del período
  final int totalTransactions;

  /// Cantidad de puntos de datos con ventas (no vacíos)
  final int activeDataPoints;

  /// Ventas totales de la primera mitad del período
  final double firstHalfSales;

  /// Ventas totales de la segunda mitad del período
  final double secondHalfSales;

  const TrendData({
    required this.granularity,
    required this.dataPoints,
    required this.trendPercentage,
    required this.maxValue,
    required this.minValue,
    required this.totalSales,
    required this.totalTransactions,
    this.activeDataPoints = 0,
    this.firstHalfSales = 0.0,
    this.secondHalfSales = 0.0,
  });

  /// Constructor vacío
  factory TrendData.empty() {
    return const TrendData(
      granularity: TrendGranularity.day,
      dataPoints: [],
      trendPercentage: 0.0,
      maxValue: 0.0,
      minValue: 0.0,
      totalSales: 0.0,
      totalTransactions: 0,
      activeDataPoints: 0,
      firstHalfSales: 0.0,
      secondHalfSales: 0.0,
    );
  }

  /// Indica si hay datos disponibles
  bool get hasData => dataPoints.isNotEmpty && totalTransactions > 0;

  /// Obtiene el rango de valores (max - min)
  double get valueRange => maxValue - minValue;

  /// Indica si la tendencia es estadísticamente significativa
  ///
  /// Se considera significativa cuando:
  /// - Hay al menos 2 transacciones
  /// - Hay al menos 2 puntos de datos activos
  /// - Ambas mitades tienen ventas (para evitar el caso 0 -> algo = 100%)
  bool get isTrendSignificant {
    // Mínimo de transacciones para considerar significativo
    if (totalTransactions < 2) return false;
    // Mínimo de puntos de datos con actividad
    if (activeDataPoints < 2) return false;
    // Si la primera mitad no tiene ventas, la comparación no es significativa
    // (excepto si la segunda tampoco tiene, en cuyo caso ambas son 0)
    if (firstHalfSales == 0 && secondHalfSales > 0) return false;
    return true;
  }

  /// Indica si hay datos insuficientes para un análisis confiable
  ///
  /// Retorna true cuando hay datos pero son muy pocos para sacar conclusiones
  bool get hasInsufficientData {
    return hasData && !isTrendSignificant;
  }

  /// Nivel de confiabilidad del análisis (0.0 - 1.0)
  ///
  /// Basado en cantidad de transacciones y distribución de datos
  double get confidenceLevel {
    if (!hasData) return 0.0;
    if (!isTrendSignificant) return 0.2;

    // Más transacciones = mayor confianza (hasta 20 para confianza máxima)
    final transactionScore = (totalTransactions / 20).clamp(0.0, 1.0);
    // Más puntos activos = mayor confianza
    final distributionScore =
        (activeDataPoints / dataPoints.length).clamp(0.0, 1.0);
    // Ambas mitades con ventas = mayor confianza
    final balanceScore =
        (firstHalfSales > 0 && secondHalfSales > 0) ? 1.0 : 0.5;

    return (transactionScore * 0.4 +
            distributionScore * 0.3 +
            balanceScore * 0.3)
        .clamp(0.3, 1.0);
  }

  @override
  List<Object?> get props => [
        granularity,
        dataPoints,
        trendPercentage,
        maxValue,
        minValue,
        totalSales,
        totalTransactions,
        activeDataPoints,
        firstHalfSales,
        secondHalfSales,
      ];
}

/// Punto de dato individual en la tendencia
class TrendDataPoint extends Equatable {
  /// Etiqueta del punto (ej: "09:00", "15 Mar", "Enero")
  final String label;

  /// Etiqueta completa para tooltips (ej: "09:00-10:00", "15 de Marzo", "Enero 2025")
  final String fullLabel;

  /// Valor de ventas totales en este punto
  final double value;

  /// Cantidad de transacciones en este punto
  final int transactionCount;

  /// Timestamp del punto (para ordenamiento y agrupación)
  final DateTime timestamp;

  const TrendDataPoint({
    required this.label,
    required this.fullLabel,
    required this.value,
    required this.transactionCount,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [label, fullLabel, value, transactionCount, timestamp];
}

/// Granularidad de los datos de tendencia
enum TrendGranularity {
  /// Por horas (0-23) - para filtros de día (hoy, ayer)
  hour('Hora', 'Horas'),

  /// Por días - para filtros de mes (este mes, mes pasado)
  day('Día', 'Días'),

  /// Por meses (1-12) - para filtros de año (este año, año pasado)
  month('Mes', 'Meses');

  final String singular;
  final String plural;

  const TrendGranularity(this.singular, this.plural);
}
