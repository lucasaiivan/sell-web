import 'package:injectable/injectable.dart';
import '../../domain/entities/date_filter.dart';
import '../../domain/entities/trend_data.dart';
import '../../../sales/domain/entities/ticket_model.dart';

/// Service: Calculador de Tendencias
///
/// **Responsabilidad:**
/// - Calcular tendencias de ventas con granularidad adaptativa según el filtro
/// - Generar datos agrupados por horas, días o meses
/// - Calcular porcentajes de tendencia (comparación primera mitad vs segunda mitad)
///
/// **Estrategia por filtro:**
/// - Hoy/Ayer → Agrupar por HORAS (0-23)
/// - Este mes/Mes pasado → Agrupar por DÍAS del mes
/// - Este año/Año pasado → Agrupar por MESES (1-12)
@lazySingleton
class TrendCalculatorService {
  /// Calcula la tendencia para un conjunto de transacciones con el filtro dado
  ///
  /// **Parámetros:**
  /// - transactions: Lista de transacciones a analizar
  /// - filter: Filtro de fecha que determina la granularidad
  ///
  /// **Retorna:** Objeto TrendData con los datos calculados
  TrendData calculateTrend({
    required List<TicketModel> transactions,
    required DateFilter filter,
  }) {
    // Filtrar transacciones no anuladas
    final validTransactions = transactions.where((t) => !t.annulled).toList();

    if (validTransactions.isEmpty) {
      return TrendData.empty();
    }

    // Determinar granularidad según el filtro
    final granularity = _getGranularityForFilter(filter);

    // Calcular rango de fechas del filtro
    final range = _getDateRangeForFilter(filter);

    // Agrupar datos según granularidad
    final dataPoints = _groupDataByGranularity(
      transactions: validTransactions,
      granularity: granularity,
      filterRange: range,
      filter: filter,
    );

    // Calcular estadísticas
    final stats = _calculateStatistics(dataPoints);

    return TrendData(
      granularity: granularity,
      dataPoints: dataPoints,
      trendPercentage: stats.trendPercentage,
      maxValue: stats.maxValue,
      minValue: stats.minValue,
      totalSales: stats.totalSales,
      totalTransactions: stats.totalTransactions,
      activeDataPoints: stats.activeDataPoints,
      firstHalfSales: stats.firstHalfSales,
      secondHalfSales: stats.secondHalfSales,
    );
  }

  /// Determina la granularidad según el filtro aplicado
  TrendGranularity _getGranularityForFilter(DateFilter filter) {
    switch (filter) {
      case DateFilter.today:
      case DateFilter.yesterday:
        return TrendGranularity.hour;
      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
        return TrendGranularity.day;
      case DateFilter.thisYear:
      case DateFilter.lastYear:
        return TrendGranularity.month;
    }
  }

  /// Obtiene el rango de fechas para el filtro (solo el período específico)
  ({DateTime start, DateTime end}) _getDateRangeForFilter(DateFilter filter) {
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd;

    switch (filter) {
      case DateFilter.today:
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = rangeStart.add(const Duration(days: 1));
        break;
      case DateFilter.yesterday:
        rangeStart = DateTime(now.year, now.month, now.day - 1);
        rangeEnd = DateTime(now.year, now.month, now.day);
        break;
      case DateFilter.thisMonth:
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case DateFilter.lastMonth:
        rangeStart = DateTime(now.year, now.month - 1, 1);
        rangeEnd = DateTime(now.year, now.month, 1);
        break;
      case DateFilter.thisYear:
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year + 1, 1, 1);
        break;
      case DateFilter.lastYear:
        rangeStart = DateTime(now.year - 1, 1, 1);
        rangeEnd = DateTime(now.year, 1, 1);
        break;
    }

    return (start: rangeStart, end: rangeEnd);
  }

  /// Agrupa transacciones según la granularidad especificada
  List<TrendDataPoint> _groupDataByGranularity({
    required List<TicketModel> transactions,
    required TrendGranularity granularity,
    required ({DateTime start, DateTime end}) filterRange,
    required DateFilter filter,
  }) {
    switch (granularity) {
      case TrendGranularity.hour:
        return _groupByHour(transactions, filterRange);
      case TrendGranularity.day:
        return _groupByDay(transactions, filterRange);
      case TrendGranularity.month:
        return _groupByMonth(transactions, filterRange, filter);
    }
  }

  /// Agrupa transacciones por HORA del día (0-23)
  List<TrendDataPoint> _groupByHour(
    List<TicketModel> transactions,
    ({DateTime start, DateTime end}) range,
  ) {
    final now = DateTime.now();
    // Determinar la hora máxima a incluir
    // Si el rango incluye el día actual, solo hasta la hora actual
    final maxHour = _isToday(range.start) ? now.hour : 23;

    // Crear mapa de horas (0 hasta maxHour)
    final hourMap = <int, _GroupData>{};
    for (int hour = 0; hour <= maxHour; hour++) {
      hourMap[hour] = _GroupData();
    }

    // Agrupar transacciones por hora
    for (final transaction in transactions) {
      final date = transaction.creation.toDate();
      // Solo incluir transacciones dentro del rango
      if (date.isBefore(range.start) || date.isAfter(range.end)) continue;

      final hour = date.hour;
      // Solo incluir horas hasta la hora actual si es hoy
      if (hour <= maxHour && hourMap.containsKey(hour)) {
        hourMap[hour]!.totalSales += transaction.priceTotal;
        hourMap[hour]!.transactionCount++;
      }
    }

    // Convertir a lista de TrendDataPoint
    final dataPoints = <TrendDataPoint>[];
    for (int hour = 0; hour <= maxHour; hour++) {
      final data = hourMap[hour]!;
      final timestamp = range.start.add(Duration(hours: hour));

      dataPoints.add(TrendDataPoint(
        label: _formatHourLabel(hour),
        fullLabel: _formatHourFullLabel(hour),
        value: data.totalSales,
        transactionCount: data.transactionCount,
        timestamp: timestamp,
      ));
    }

    return dataPoints;
  }

  /// Agrupa transacciones por DÍA del mes
  List<TrendDataPoint> _groupByDay(
    List<TicketModel> transactions,
    ({DateTime start, DateTime end}) range,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Crear mapa de días
    final dayMap = <String, _GroupData>{};

    // Generar días del rango hasta hoy (no incluir días futuros)
    var currentDate = range.start;
    final effectiveEnd = range.end.isAfter(today.add(const Duration(days: 1)))
        ? today.add(const Duration(days: 1))
        : range.end;

    while (currentDate.isBefore(effectiveEnd)) {
      final key = _formatDateKey(currentDate);
      dayMap[key] = _GroupData();
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Agrupar transacciones por día
    for (final transaction in transactions) {
      final date = transaction.creation.toDate();
      if (date.isBefore(range.start) || date.isAfter(range.end)) continue;

      final key = _formatDateKey(date);
      if (dayMap.containsKey(key)) {
        dayMap[key]!.totalSales += transaction.priceTotal;
        dayMap[key]!.transactionCount++;
      }
    }

    // Convertir a lista de TrendDataPoint (ordenados por fecha)
    final dataPoints = <TrendDataPoint>[];
    final sortedKeys = dayMap.keys.toList()..sort();

    for (final key in sortedKeys) {
      final data = dayMap[key]!;
      final date = DateTime.parse(key);

      dataPoints.add(TrendDataPoint(
        label: _formatDayLabel(date),
        fullLabel: _formatDayFullLabel(date),
        value: data.totalSales,
        transactionCount: data.transactionCount,
        timestamp: date,
      ));
    }

    return dataPoints;
  }

  /// Agrupa transacciones por MES del año (1-12)
  List<TrendDataPoint> _groupByMonth(
    List<TicketModel> transactions,
    ({DateTime start, DateTime end}) range,
    DateFilter filter,
  ) {
    // Crear mapa de meses
    final monthMap = <int, _GroupData>{};

    // Determinar los meses del rango
    var currentDate = range.start;
    while (currentDate.isBefore(range.end)) {
      monthMap[currentDate.month] = _GroupData();
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    // Agrupar transacciones por mes
    for (final transaction in transactions) {
      final date = transaction.creation.toDate();
      if (date.isBefore(range.start) || date.isAfter(range.end)) continue;

      final month = date.month;
      if (monthMap.containsKey(month)) {
        monthMap[month]!.totalSales += transaction.priceTotal;
        monthMap[month]!.transactionCount++;
      }
    }

    // Convertir a lista de TrendDataPoint (ordenados por mes)
    final dataPoints = <TrendDataPoint>[];
    final sortedMonths = monthMap.keys.toList()..sort();

    for (final month in sortedMonths) {
      final data = monthMap[month]!;
      // Usar el año del range.start para el timestamp
      final timestamp = DateTime(range.start.year, month, 1);

      dataPoints.add(TrendDataPoint(
        label: _formatMonthLabel(month),
        fullLabel: _formatMonthFullLabel(month, range.start.year),
        value: data.totalSales,
        transactionCount: data.transactionCount,
        timestamp: timestamp,
      ));
    }

    return dataPoints;
  }

  /// Calcula estadísticas de los datos agrupados
  _Statistics _calculateStatistics(List<TrendDataPoint> dataPoints) {
    if (dataPoints.isEmpty) {
      return _Statistics(
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

    double totalSales = 0.0;
    int totalTransactions = 0;
    double maxValue = 0.0;
    double minValue = double.infinity;
    int activeDataPoints = 0;

    for (final point in dataPoints) {
      totalSales += point.value;
      totalTransactions += point.transactionCount;
      if (point.value > maxValue) maxValue = point.value;
      if (point.value < minValue) minValue = point.value;
      // Contar puntos con actividad (transacciones > 0)
      if (point.transactionCount > 0) activeDataPoints++;
    }

    // Si todos los valores son 0, ajustar minValue
    if (minValue == double.infinity) minValue = 0.0;

    // Calcular ventas por mitad y tendencia
    final halfResult = _calculateTrendWithHalves(dataPoints);

    return _Statistics(
      trendPercentage: halfResult.trendPercentage,
      maxValue: maxValue,
      minValue: minValue,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
      activeDataPoints: activeDataPoints,
      firstHalfSales: halfResult.firstHalfSales,
      secondHalfSales: halfResult.secondHalfSales,
    );
  }

  /// Calcula el porcentaje de tendencia y ventas por mitad
  ({double trendPercentage, double firstHalfSales, double secondHalfSales})
      _calculateTrendWithHalves(List<TrendDataPoint> dataPoints) {
    if (dataPoints.length < 2) {
      return (trendPercentage: 0.0, firstHalfSales: 0.0, secondHalfSales: 0.0);
    }

    final midPoint = dataPoints.length ~/ 2;

    double firstHalfTotal = 0.0;
    double secondHalfTotal = 0.0;

    for (int i = 0; i < midPoint; i++) {
      firstHalfTotal += dataPoints[i].value;
    }
    for (int i = midPoint; i < dataPoints.length; i++) {
      secondHalfTotal += dataPoints[i].value;
    }

    double trendPercentage;
    if (firstHalfTotal == 0) {
      trendPercentage = secondHalfTotal > 0 ? 100.0 : 0.0;
    } else {
      trendPercentage =
          ((secondHalfTotal - firstHalfTotal) / firstHalfTotal) * 100;
    }

    return (
      trendPercentage: trendPercentage,
      firstHalfSales: firstHalfTotal,
      secondHalfSales: secondHalfTotal,
    );
  }

  // === Helpers ===

  /// Verifica si una fecha es hoy
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // === Formateadores de etiquetas ===

  /// Formatea una fecha como clave (yyyy-MM-dd)
  String _formatDateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatHourLabel(int hour) {
    return '${hour.toString().padLeft(2, '0')}h';
  }

  String _formatHourFullLabel(int hour) {
    final nextHour = (hour + 1) % 24;
    return '${hour.toString().padLeft(2, '0')}:00 - ${nextHour.toString().padLeft(2, '0')}:00';
  }

  String _formatDayLabel(DateTime date) {
    return '${date.day}';
  }

  String _formatDayFullLabel(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} de $month';
  }

  String _formatMonthLabel(int month) {
    const monthsShort = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return monthsShort[month - 1];
  }

  String _formatMonthFullLabel(int month, int year) {
    const monthsFull = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${monthsFull[month - 1]} $year';
  }
}

/// Clase auxiliar para agrupar datos
class _GroupData {
  double totalSales = 0.0;
  int transactionCount = 0;
}

/// Clase auxiliar para estadísticas calculadas
class _Statistics {
  final double trendPercentage;
  final double maxValue;
  final double minValue;
  final double totalSales;
  final int totalTransactions;
  final int activeDataPoints;
  final double firstHalfSales;
  final double secondHalfSales;

  _Statistics({
    required this.trendPercentage,
    required this.maxValue,
    required this.minValue,
    required this.totalSales,
    required this.totalTransactions,
    required this.activeDataPoints,
    required this.firstHalfSales,
    required this.secondHalfSales,
  });
}
