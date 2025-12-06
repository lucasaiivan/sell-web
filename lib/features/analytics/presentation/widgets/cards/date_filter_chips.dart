import 'package:flutter/material.dart';
import '../../../domain/entities/date_filter.dart';

/// Widget: Chips de Filtro de Fecha
///
/// **Responsabilidad:**
/// - Mostrar opciones de filtro de fecha como chips seleccionables
/// - Notificar cambios de selección al parent
///
/// **Uso:**
/// ```dart
/// DateFilterChips(
///   selectedFilter: DateFilter.today,
///   onFilterChanged: (filter) => provider.setDateFilter(filter),
/// )
/// ```
class DateFilterChips extends StatelessWidget {
  /// Filtro actualmente seleccionado
  final DateFilter selectedFilter;

  /// Callback cuando cambia el filtro
  final ValueChanged<DateFilter> onFilterChanged;

  const DateFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
