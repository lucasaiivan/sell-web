import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

/// Widget: Tarjeta de Distribución por Categorías
///
/// **Responsabilidad:**
/// - Mostrar gráfico de dona con distribución de ventas por categoría
/// - Visualizar porcentajes y montos por categoría
/// - Abrir modal con análisis detallado
class CategoryDistributionCard extends StatelessWidget {
  final List<Map<String, dynamic>> salesByCategory;
  final double totalSales;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const CategoryDistributionCard({
    super.key,
    required this.salesByCategory,
    required this.totalSales,
    this.color = const Color(0xFFEC4899),
    this.isZero = false,
    this.subtitle,
  });

  // Paleta de colores para las categorías
  static const List<Color> _categoryColors = [
    Color(0xFF3B82F6), // Azul
    Color(0xFF10B981), // Verde
    Color(0xFFF59E0B), // Naranja
    Color(0xFFEF4444), // Rojo
    Color(0xFF8B5CF6), // Púrpura
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Rosa
    Color(0xFF84CC16), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    final hasData = !isZero && salesByCategory.isNotEmpty;
    // Limitar a 5 categorías para el gráfico
    final displayCategories = salesByCategory.take(5).toList();

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || salesByCategory.isEmpty,
      icon: Icons.pie_chart_rounded,
      title: 'Categorías',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showCategoryModal(context) : null,
      child: hasData
          ? Row(
              children: [
                // Gráfico de dona - tamaño dinámico
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableSize = constraints.biggest.shortestSide;
                      // Evitar errores con tamaños muy pequeños
                      if (availableSize < 40) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildDonutChart(
                          context,
                          displayCategories,
                          availableSize - 8, // Restar padding
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Leyenda compacta
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildLegend(context, displayCategories),
                  ),
                ),
              ],
            )
          : const Center(child: AnalyticsEmptyState(message: 'Sin datos')),
    );
  }

  Widget _buildDonutChart(
    BuildContext context,
    List<Map<String, dynamic>> categories,
    double size,
  ) {
    final sections = <PieChartSectionData>[];
    // Calcular radios basados en el tamaño disponible
    final radius = size * 0.24; // ~24% del diámetro (más grande)
    final centerRadius = size * 0.22; // ~22% del diámetro

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final percentage = category['percentage'] as double? ?? 0.0;
      final categoryColor = _categoryColors[i % _categoryColors.length];

      sections.add(
        PieChartSectionData(
          color: categoryColor,
          value: percentage,
          // Mostrar porcentaje si es >= 10%
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          titleStyle: TextStyle(
            fontSize: (size * 0.09).clamp(9.0, 13.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
              ),
            ],
          ),
          radius: radius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          ),
        ),
      );
    }

    // Si hay "otros" agregar sección gris
    if (salesByCategory.length > 5) {
      double othersPercentage = 0;
      for (int i = 5; i < salesByCategory.length; i++) {
        othersPercentage += salesByCategory[i]['percentage'] as double? ?? 0.0;
      }
      if (othersPercentage > 0) {
        sections.add(
          PieChartSectionData(
            color: Colors.grey.shade400,
            value: othersPercentage,
            title: othersPercentage >= 10
                ? '${othersPercentage.toStringAsFixed(0)}%'
                : '',
            titleStyle: TextStyle(
              fontSize: (size * 0.09).clamp(9.0, 13.0),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
            ),
            radius: radius * 0.95,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
        );
      }
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: centerRadius,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<Map<String, dynamic>> categories,
  ) {
    final theme = Theme.of(context);
    // Limitar a 4 categorías a simple vista
    final displayCount = categories.length.clamp(0, 4);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categories.take(displayCount).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final categoryName = category['category'] as String? ?? 'Sin nombre';
          final percentage = category['percentage'] as double? ?? 0.0;
          final categorySales = category['totalSales'] as double? ?? 0.0;
          final categoryColor = _categoryColors[index % _categoryColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicador de color mejorado
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Información de categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        categoryName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyHelper.formatCurrency(categorySales),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de porcentaje mejorado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (salesByCategory.length > displayCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  '+${salesByCategory.length - displayCount} categorías',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDistributionModal(
        salesByCategory: salesByCategory,
        totalSales: totalSales,
      ),
    );
  }
}

/// Modal: Análisis Detallado por Categoría
class CategoryDistributionModal extends StatelessWidget {
  final List<Map<String, dynamic>> salesByCategory;
  final double totalSales;

  const CategoryDistributionModal({
    super.key,
    required this.salesByCategory,
    required this.totalSales,
  });

  static const _accentColor = Color(0xFFEC4899);

  static const List<Color> _categoryColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topCategories = salesByCategory.take(8).toList();

    return AnalyticsModal(
      title: 'Ventas por Categoría',
      accentColor: _accentColor,
      icon: Icons.pie_chart_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gráfico grande
            SizedBox(
              height: 220,
              child: _buildDetailedDonutChart(context, topCategories),
            ),
            const SizedBox(height: 24),

            // Resumen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      context,
                      'Total Ventas',
                      CurrencyHelper.formatCurrency(totalSales),
                      Icons.attach_money_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      context,
                      'Categorías',
                      salesByCategory.length.toString(),
                      Icons.category_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lista de categorías
            Text(
              'Detalle por Categoría',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...salesByCategory.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return _buildCategoryItem(context, category, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedDonutChart(
    BuildContext context,
    List<Map<String, dynamic>> categories,
  ) {
    final theme = Theme.of(context);
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final percentage = category['percentage'] as double? ?? 0.0;
      final categoryColor = _categoryColors[i % _categoryColors.length];

      sections.add(
        PieChartSectionData(
          color: categoryColor,
          value: percentage,
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 45,
          borderSide: BorderSide(
            color: theme.colorScheme.surface,
            width: 3,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 50,
            sectionsSpace: 3,
            startDegreeOffset: -90,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${salesByCategory.length}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _accentColor,
              ),
            ),
            Text(
              'categorías',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Map<String, dynamic> category,
    int index,
  ) {
    final theme = Theme.of(context);
    final categoryName = category['category'] as String? ?? 'Sin nombre';
    final categorySales = category['totalSales'] as double? ?? 0.0;
    final percentage = category['percentage'] as double? ?? 0.0;
    final quantitySold = category['quantitySold'] as int? ?? 0;
    final categoryColor = _categoryColors[index % _categoryColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyHelper.formatCurrency(categorySales),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: categoryColor.withValues(alpha: 0.15),
                      color: categoryColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$quantitySold productos vendidos',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
