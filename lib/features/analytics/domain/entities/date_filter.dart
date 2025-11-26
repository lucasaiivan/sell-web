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
  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateFilter.today:
        return (today, today.add(const Duration(days: 1)));

      case DateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, today);

      case DateFilter.thisMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        return (firstDayOfMonth, today.add(const Duration(days: 1)));

      case DateFilter.lastMonth:
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
        return (firstDayOfLastMonth, firstDayOfThisMonth);

      case DateFilter.thisYear:
        final firstDayOfYear = DateTime(now.year, 1, 1);
        return (firstDayOfYear, today.add(const Duration(days: 1)));

      case DateFilter.lastYear:
        final firstDayOfLastYear = DateTime(now.year - 1, 1, 1);
        final firstDayOfThisYear = DateTime(now.year, 1, 1);
        return (firstDayOfLastYear, firstDayOfThisYear);
    }
  }
}
