import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/ui_constants.dart';

/// Modal bottom sheet base que implementa Material Design 3 con apariencia consistente
///
/// Proporciona una estructura estándar para todos los bottom sheets de la aplicación:
/// - Handle bar de arrastre
/// - Header con título, subtítulo opcional e icono
/// - **Buscador integrado en header** (opcional)
/// - Contenido principal (body)
/// - Acciones/botones en la parte inferior (opcional)
class BaseBottomSheet extends StatefulWidget {
  const BaseBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.icon,
    this.actions,
    this.maxHeightFactor = 0.85,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.iconColor,
    this.headerExtra,
    this.onSearch,
    this.searchHint = 'Buscar...',
    this.searchController,
    this.initialSearchMode = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final IconData? icon;
  final List<Widget>? actions;
  final double maxHeightFactor;
  final bool showCloseButton;
  final bool showDragHandle;
  final Color? iconColor;
  final Widget? headerExtra;
  
  /// Callback para búsqueda. Si se proporciona, se habilita el botón de búsqueda en el header.
  final ValueChanged<String>? onSearch;
  
  /// Texto hint para el buscador
  final String searchHint;
  
  /// Controlador opcional parea el buscador
  final TextEditingController? searchController;

  /// Si es true, inicia con el buscador abierto
  final bool initialSearchMode;

  @override
  State<BaseBottomSheet> createState() => _BaseBottomSheetState();
}

class _BaseBottomSheetState extends State<BaseBottomSheet> {
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _isSearching = widget.initialSearchMode;
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearch?.call('');
      } else {
        // Un pequeño delay para foco automático si fuera necesario
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * widget.maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          if (widget.showDragHandle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header dinámico (Título o Buscador)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? _buildSearchHeader(context, theme, colorScheme)
                : _buildStandardHeader(context, theme, colorScheme),
          ),

          const Divider(height: 1),

          // Body - contenido principal
          Expanded(
            child: hasActions
                ? Stack(
                    children: [
                      // Contenido ocupando todo el espacio
                      Positioned.fill(
                        child: widget.body,
                      ),
                      // Footer con botones
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildFooter(context, colorScheme),
                      ),
                    ],
                  )
                : widget.body,
          ),
        ],
      ),
    );
  }

  Widget _buildStandardHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      key: const ValueKey('standardHeader'),
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: widget.iconColor ?? colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Acciones del header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onSearch != null)
                IconButton(
                  onPressed: _toggleSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                ),
                
              if (widget.headerExtra != null)
                widget.headerExtra!
              else if (widget.showCloseButton)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      key: const ValueKey('searchHeader'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleSearch,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    width: UIConstants.borderThickness,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    width: UIConstants.borderThickness,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: UIConstants.activeBorderThickness,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              onChanged: widget.onSearch,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                setState(() {
                  _searchController.clear();
                });
                widget.onSearch?.call('');
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withValues(alpha: 0.0),
            colorScheme.surface.withValues(alpha: 0.7),
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: widget.actions!.length == 1
          ? widget.actions![0]
          : Row(
              children: [
                for (int i = 0; i < widget.actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: widget.actions![i]),
                ],
              ],
            ),
    );
  }
}

/// Helper function para mostrar un BaseBottomSheet
Future<T?> showBaseBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget body,
  IconData? icon,
  List<Widget>? actions,
  double maxHeightFactor = 0.85,
  bool showCloseButton = true,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = true,
  ValueChanged<String>? onSearch,
  String searchHint = 'Buscar...',
  TextEditingController? searchController,
  bool initialSearchMode = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => BaseBottomSheet(
      title: title,
      subtitle: subtitle,
      body: body,
      icon: icon,
      actions: actions,
      maxHeightFactor: maxHeightFactor,
      showCloseButton: showCloseButton,
      showDragHandle: showDragHandle,
      onSearch: onSearch,
      searchHint: searchHint,
      searchController: searchController,
      initialSearchMode: initialSearchMode,
    ),
  );
}
