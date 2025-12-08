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

  const TrendData({
    required this.granularity,
    required this.dataPoints,
    required this.trendPercentage,
    required this.maxValue,
    required this.minValue,
    required this.totalSales,
    required this.totalTransactions,
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
    );
  }

  /// Indica si hay datos disponibles
  bool get hasData => dataPoints.isNotEmpty && totalTransactions > 0;

  /// Obtiene el rango de valores (max - min)
  double get valueRange => maxValue - minValue;

  @override
  List<Object?> get props => [
        granularity,
        dataPoints,
        trendPercentage,
        maxValue,
        minValue,
        totalSales,
        totalTransactions,
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
