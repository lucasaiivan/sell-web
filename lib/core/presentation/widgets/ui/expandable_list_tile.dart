
import 'package:flutter/material.dart';

/// {@template list_tile_app}
/// Widget de List Tile para la App, que soporta expansión y contenido personalizado.
/// Básicamente es una versión más flexible de [ExpandablePremiumListTile] que acepta un [child].
/// {@endtemplate}

/// Controlador para manejar el estado de [ListTileAppExpanded] programáticamente
class ListTileController {
  _ListTileAppExpandedState? _state;

  void attach(_ListTileAppExpandedState state) {
    _state = state;
  }

  void detach() {
    _state = null;
  }

  /// Expande el tile si está colapsado
  void expand() {
    _state?._expand();
  }

  /// Colapsa el tile si está expandido
  void collapse() {
    _state?._collapse();
  }

  /// Alterna el estado
  void toggle() {
    _state?._handleTap();
  }
}

class ListTileAppExpanded extends StatefulWidget {
  /// Icono principal
  final IconData? icon;

  /// Color del icono y elementos destacados
  final Color? iconColor;

  /// Título (String o Widget)
  final dynamic title;

  /// Subtítulo opcional
  final Widget? subtitle;

  /// Contenido a mostrar cuando está expandido
  final Widget child;

  /// Si es responsive para mobile
  final bool isMobile;

  /// Color de fondo
  final Color? backgroundColor;

  /// Estado inicial
  final bool initiallyExpanded;

  /// Padding del contenido expandido
  final EdgeInsets? contentPadding;

  /// Controlador opcional
  final ListTileController? controller;

  /// Callback cuando cambia el estado de expansión
  final ValueChanged<bool>? onExpansionChanged;

  /// Widget de acción opcional en el header
  final Widget? action;


  const ListTileAppExpanded({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    required this.child,
    this.subtitle,
    this.isMobile = false,
    this.backgroundColor,
    this.initiallyExpanded = false,
    this.contentPadding,
    this.controller,
    this.onExpansionChanged,
    this.action,
  });

  @override
  State<ListTileAppExpanded> createState() => _ListTileAppExpandedState();
}

class _ListTileAppExpandedState extends State<ListTileAppExpanded>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
    _iconTurns =
        _controller.drive(Tween<double>(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.easeIn)));
    if (_isExpanded) _controller.value = 1.0;
    
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(ListTileAppExpanded oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  void _expand() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
        _controller.forward();
        widget.onExpansionChanged?.call(_isExpanded);
      });
    }
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
        widget.onExpansionChanged?.call(_isExpanded);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Reutilizamos PremiumListTile para el encabezado (collapsed)

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.backgroundColor ??theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16), // UIConstants.defaultRadius
        border: Border.all(
          color: _isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.5),
          width: _isExpanded ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(widget.isMobile ? 12 : 14),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                    padding: EdgeInsets.all(widget.isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.isMobile ? 20 : 24,
                      color: widget.iconColor ?? theme.colorScheme.primary,
                    ),
                  ),
                    SizedBox(width: widget.isMobile ? 12 : 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.title is String
                            ? Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : widget.title,
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          DefaultTextStyle(
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                            child: widget.subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.action != null) ...[
                    widget.action!,
                    SizedBox(width: widget.isMobile ? 8 : 12),
                  ],
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Body
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller.view,
              builder: (BuildContext context, Widget? child) {
                return Align(
                  heightFactor: _heightFactor.value,
                  alignment: Alignment.topLeft,
                  child: child,
                );
              },
              child: Padding(
                padding: widget.contentPadding ?? EdgeInsets.fromLTRB(widget.isMobile ? 12 : 14, 0, widget.isMobile ? 12 : 14, widget.isMobile ? 12 : 14),
                child: Column(
                  children: [
                    Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
