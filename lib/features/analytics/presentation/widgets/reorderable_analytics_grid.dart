import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';

/// Widget: Grid de Analytics Reordenable
///
/// **Responsabilidad:**
/// - Envolver el grid de tarjetas en un ReorderableBuilder
/// - Permitir drag-and-drop para reordenar tarjetas
/// - Mantener animaciones fluidas durante el reordenamiento
/// - Notificar al padre cuando cambia el orden
///
/// **IMPORTANTE:** Este widget es STATELESS respecto al orden.
/// El orden de los children lo controla el padre completamente.
/// Cuando se hace drag-and-drop, se notifica al padre con los
/// índices old/new y el padre es responsable de actualizar el orden.
///
/// **Uso:**
/// ```dart
/// ReorderableAnalyticsGrid(
///   layoutType: 'desktop',
///   crossAxisCount: 6,
///   gap: 14.0,
///   children: [...],
///   onReorder: (oldIndex, newIndex) => handleReorder(oldIndex, newIndex),
/// )
/// ```
class ReorderableAnalyticsGrid extends StatefulWidget {
  /// Tipo de layout para persistencia: 'mobile', 'tablet', 'desktop'
  final String layoutType;

  /// Número de columnas del grid
  final int crossAxisCount;

  /// Espacio entre tarjetas
  final double gap;

  /// Tarjetas hijas con keys únicas (ya en el orden deseado)
  final List<Widget> children;

  /// Callback cuando se reordena - recibe la lista de índices en el nuevo orden
  /// Ejemplo: si se mueve el elemento 0 a posición 2, recibe [1, 2, 0, 3, ...]
  final void Function(List<int> reorderedIndices)? onReorder;

  /// Ancho máximo del grid (constraint)
  final double? maxWidth;

  /// Si está habilitado el drag-and-drop
  final bool enableReordering;

  /// Aspecto ratio de cada celda (ancho/alto)
  final double childAspectRatio;

  const ReorderableAnalyticsGrid({
    super.key,
    required this.layoutType,
    required this.crossAxisCount,
    required this.children,
    this.gap = 12.0,
    this.onReorder,
    this.maxWidth,
    this.enableReordering = true,
    this.childAspectRatio = 1.2,
  });

  @override
  State<ReorderableAnalyticsGrid> createState() =>
      _ReorderableAnalyticsGridState();
}

class _ReorderableAnalyticsGridState extends State<ReorderableAnalyticsGrid> {
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridContent =
        widget.enableReordering ? _buildReorderableGrid() : _buildStaticGrid();

    if (widget.maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth!),
          child: gridContent,
        ),
      );
    }

    return gridContent;
  }

  /// Construye el grid con capacidad de reordenamiento
  Widget _buildReorderableGrid() {
    // Crear lista de índices simple para el ReorderableBuilder
    final indices = List.generate(widget.children.length, (i) => i);

    return ReorderableBuilder<int>(
      scrollController: _scrollController,
      enableDraggable: widget.enableReordering,
      enableLongPress: true,
      longPressDelay: const Duration(milliseconds: 300),
      onReorder: (ReorderedListFunction<int> reorderedListFunction) {
        // Aplicar la función para obtener el nuevo orden de índices
        final newOrder = reorderedListFunction(indices);

        // Verificar que hubo un cambio real
        bool hasChanged = false;
        for (int i = 0; i < indices.length; i++) {
          if (indices[i] != newOrder[i]) {
            hasChanged = true;
            break;
          }
        }

        // Notificar al padre con la lista completa de índices reordenados
        if (hasChanged) {
          widget.onReorder?.call(newOrder);
        }
      },
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      children: widget.children,
      builder: (children) {
        return GridView(
          key: _gridViewKey,
          controller: _scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            mainAxisSpacing: widget.gap,
            crossAxisSpacing: widget.gap,
            childAspectRatio: widget.childAspectRatio,
          ),
          children: children,
        );
      },
    );
  }

  /// Construye el grid estático (sin reordenamiento)
  Widget _buildStaticGrid() {
    return GridView(
      key: _gridViewKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.gap,
        crossAxisSpacing: widget.gap,
        childAspectRatio: widget.childAspectRatio,
      ),
      children: widget.children,
    );
  }
}
