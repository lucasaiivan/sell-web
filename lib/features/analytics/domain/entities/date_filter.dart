/// Enum: Filtros de Fecha para Analíticas
///
/// **Opciones disponibles:**
/// - today: Hoy
/// - yesterday: Ayer
/// - thisMonth: Este mes
/// - lastMonth: El mes pasado
/// - thisYear: Este año
/// - lastYear: El año pasado
enum DateFilter {
  today('Hoy'),
  yesterday('Ayer'),
  thisMonth('Este mes'),
  lastMonth('Mes pasado'),
  thisYear('Este año'),
  lastYear('Año pasado');

  final String label;
  const DateFilter(this.label);

  /// Obtiene el rango de fechas para este filtro
  /// Retorna (fechaInicio, fechaFin) con fechaFin siendo el final del día
  ///
  /// **NOTA:** Para filtros de día único (today/yesterday), se incluye también
  /// el día anterior para permitir cálculo de comparaciones sin consultas adicionales
  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateFilter.today:
        // Incluir ayer para permitir comparación
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, today.add(const Duration(days: 1)));

      case DateFilter.yesterday:
        // Incluir anteayer para permitir comparación
        final twoDaysAgo = today.subtract(const Duration(days: 2));
        return (twoDaysAgo, today);

      case DateFilter.thisMonth:
        // Incluir mes anterior completo para permitir comparación
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        return (firstDayOfLastMonth, today.add(const Duration(days: 1)));

      case DateFilter.lastMonth:
        // Incluir el mes previo al mes pasado para permitir comparación
        final firstDayOfTwoMonthsAgo = DateTime(now.year, now.month - 2, 1);
        final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
        return (firstDayOfTwoMonthsAgo, firstDayOfThisMonth);

      case DateFilter.thisYear:
        final firstDayOfYear = DateTime(now.year, 1, 1);
        return (firstDayOfYear, today.add(const Duration(days: 1)));

      case DateFilter.lastYear:
        final firstDayOfLastYear = DateTime(now.year - 1, 1, 1);
        final firstDayOfThisYear = DateTime(now.year, 1, 1);
        return (firstDayOfLastYear, firstDayOfThisYear);
    }
  }

  /// Indica si este filtro debería usar streaming en tiempo real
  ///
  /// Los filtros de períodos cortos (hoy, ayer) se benefician del
  /// tiempo real. Los períodos largos usan consulta única para
  /// evitar sobrecarga de listeners.
  bool get shouldUseRealtime {
    switch (this) {
      case DateFilter.today:
      case DateFilter.yesterday:
        return true;
      case DateFilter.thisMonth:
      case DateFilter.lastMonth:
      case DateFilter.thisYear:
      case DateFilter.lastYear:
        return false;
    }
  }

  /// Número de días que abarca este filtro (aproximado)
  int get estimatedDays {
    switch (this) {
      case DateFilter.today:
        return 2; // Incluye ayer para comparación
      case DateFilter.yesterday:
        return 2; // Incluye anteayer para comparación
      case DateFilter.thisMonth:
        final now = DateTime.now();
        // Incluye mes actual + mes anterior
        final daysThisMonth = now.day;
        final daysLastMonth = DateTime(now.year, now.month, 0).day;
        return daysThisMonth + daysLastMonth;
      case DateFilter.lastMonth:
        // Incluye mes pasado + mes previo al pasado
        final now = DateTime.now();
        final daysLastMonth = DateTime(now.year, now.month, 0).day;
        final daysTwoMonthsAgo = DateTime(now.year, now.month - 1, 0).day;
        return daysLastMonth + daysTwoMonthsAgo;
      case DateFilter.thisYear:
        final now = DateTime.now();
        return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
      case DateFilter.lastYear:
        return 365;
    }
  }
}
