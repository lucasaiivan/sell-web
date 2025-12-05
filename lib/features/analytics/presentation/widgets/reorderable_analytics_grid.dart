import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import '../../data/services/analytics_order_service.dart';

/// Widget: Grid de Analytics Reordenable con Persistencia
///
/// **Responsabilidad:**
/// - Envolver el grid de tarjetas en un ReorderableBuilder
/// - Permitir drag-and-drop para reordenar tarjetas
/// - Persistir el orden en SharedPreferences
/// - Mantener animaciones fluidas durante el reordenamiento
///
/// **Uso:**
/// ```dart
/// ReorderableAnalyticsGrid(
///   layoutType: 'desktop',
///   crossAxisCount: 6,
///   gap: 14.0,
///   children: [...],
/// )
/// ```
class ReorderableAnalyticsGrid extends StatefulWidget {
  /// Tipo de layout para persistencia: 'mobile', 'tablet', 'desktop'
  final String layoutType;

  /// Número de columnas del grid
  final int crossAxisCount;

  /// Espacio entre tarjetas
  final double gap;

  /// Tarjetas hijas con keys únicas
  final List<Widget> children;

  /// Callback cuando se reordena una tarjeta
  final void Function(List<int> newOrder)? onReorder;

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
  
  /// Lista interna de índices para manejar el reordenamiento
  late List<int> _orderedIndices;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderedIndices = List.generate(widget.children.length, (i) => i);
    _loadSavedOrder();
  }

  /// Carga el orden guardado desde SharedPreferences
  Future<void> _loadSavedOrder() async {
    final savedOrder = await AnalyticsOrderService.loadOrder(
      layoutType: widget.layoutType,
      expectedLength: widget.children.length,
    );
    
    if (mounted) {
      setState(() {
        if (savedOrder != null) {
          _orderedIndices = savedOrder;
        }
        _isLoading = false;
      });
    }
  }

  /// Guarda el orden actual en SharedPreferences
  Future<void> _saveOrder() async {
    await AnalyticsOrderService.saveOrder(
      layoutType: widget.layoutType,
      orderedIndices: _orderedIndices,
    );
  }

  @override
  void didUpdateWidget(ReorderableAnalyticsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los children cambian, validar el orden
    if (widget.children.length != oldWidget.children.length) {
      _orderedIndices = List.generate(widget.children.length, (i) => i);
      _loadSavedOrder();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Obtiene la lista de widgets ordenados según los índices actuales
  List<Widget> get _orderedChildren {
    return _orderedIndices.map((i) => widget.children[i]).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading mientras carga el orden
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final gridContent = widget.enableReordering
        ? _buildReorderableGrid()
        : _buildStaticGrid();

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
    return ReorderableBuilder<int>(
      scrollController: _scrollController,
      enableDraggable: widget.enableReordering,
      enableLongPress: true,
      longPressDelay: const Duration(milliseconds: 400),
      onReorder: (ReorderedListFunction<int> reorderedListFunction) {
        setState(() {
          _orderedIndices = reorderedListFunction(_orderedIndices);
        });
        
        // Guardar el nuevo orden
        _saveOrder();
        
        // Notificar al padre si tiene callback
        widget.onReorder?.call(_orderedIndices);
      },
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      children: _orderedChildren,
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
      children: _orderedChildren,
    );
  }
}

