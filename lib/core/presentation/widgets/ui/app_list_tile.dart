import 'package:flutter/material.dart';

/// {@template premium_list_tile}
/// Widget reutilizable de ListTile con diseño moderno.
///
/// Características:
/// - Icono principal con fondo coloreado y animación
/// - Título y subtítulo personalizables
/// - Badge de estado opcional (ej: "ACTIVA", "CERRADA")
/// - Trailing opcional (widget personalizado)
/// - Responsive design para mobile/desktop
/// - Animación al hacer tap
/// - Bordes y sombras sutiles
/// {@endtemplate}
class ListTileApp extends StatelessWidget {
  /// Icono principal que se muestra a la izquierda (opcional)
  final IconData? icon;

  /// Color del icono y elementos destacados (opcional)
  final Color? iconColor;

  /// Título principal del ListTile (puede ser String o Widget personalizado)
  final dynamic title;

  /// Subtítulo opcional (puede incluir iconos)
  final Widget? subtitle;

  /// Badge opcional que se muestra a la derecha del título
  /// Ejemplo: Badge(label: 'ACTIVA', color: Colors.green)
  final PremiumListTileBadge? badge;

  /// Widget personalizado para el trailing (derecha)
  final Widget? trailing;

  /// Callback al hacer tap en el ListTile
  final VoidCallback? onTap;

  /// Si es responsive para mobile
  final bool isMobile;

  /// Color de fondo del contenedor
  final Color? backgroundColor;

  /// Color del borde
  final Color? borderColor;

  /// Radio de los bordes
  final double? borderRadius;

  /// Padding interno
  final EdgeInsets? padding;

  /// {@macro premium_list_tile}
  const ListTileApp({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.isMobile = false,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding, required Column child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? 16.0;
    final effectivePadding = padding ?? EdgeInsets.all(isMobile ? 12 : 14);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color:   backgroundColor ?? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: Border.all(
          color: borderColor ??
              theme.dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                // Icono principal con fondo (opcional)
                if (icon != null) ...[
                  _buildIconContainer(theme),
                  SizedBox(width: isMobile ? 12 : 14),
                ],

                // Contenido principal (título y subtítulo)
                Expanded(
                  child: _buildContent(theme),
                ),

                const SizedBox(width: 8),

                // Badge de estado (opcional)
                if (badge != null) ...[
                  _buildBadge(theme),
                  const SizedBox(width: 12),
                ],

                // Trailing personalizado
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon!,
        size: isMobile ? 20 : 24,
        color: iconColor ?? theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título (String o Widget)
        if (title is String)
          Text(
            title,
            style: (theme.textTheme.titleMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          title,

        // Subtítulo (opcional)
        if (subtitle != null) ...[
          SizedBox(height: isMobile ? 4 : 6),
          DefaultTextStyle(
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                const TextStyle(),
            child: subtitle!,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(ThemeData theme) {
    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: badge!.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto de estado
          if (badge!.showDot)
            Container(
              width: isMobile ? 6 : 8,
              height: isMobile ? 6 : 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: badge!.color,
                shape: BoxShape.circle,
              ),
            ),
          // Texto del badge
          Text(
            badge!.label,
            style: (isMobile
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: badge!.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template premium_list_tile_badge}
/// Configuración para el badge de estado del PremiumListTile
/// {@endtemplate}
class PremiumListTileBadge {
  /// Texto del badge
  final String label;

  /// Color del badge
  final Color color;

  /// Mostrar punto de estado
  final bool showDot;

  /// {@macro premium_list_tile_badge}
  const PremiumListTileBadge({
    required this.label,
    required this.color,
    this.showDot = true,
  });
}

/// {@template expandable_premium_list_tile}
/// Widget reutilizable de ListTile expandible con diseño premium y animaciones.
///
/// Características:
/// - Todo lo del [ListTileApp] básico
/// - Expansión/colapso animado con ícono rotatorio
/// - Contenido expandible personalizable
/// - Animaciones suaves de borde y color
/// - Lista de items de información detallada
/// {@endtemplate}
class ExpandablePremiumListTile extends StatefulWidget {
  /// Icono principal que se muestra a la izquierda (opcional)
  final IconData? icon;

  /// Color del icono y elementos destacados (opcional)
  final Color? iconColor;

  /// Título principal del ListTile (puede ser String o Widget personalizado)
  final dynamic title;

  /// Subtítulo opcional (puede incluir iconos)
  final Widget? subtitle;

  /// Badge opcional que se muestra a la derecha del título
  final PremiumListTileBadge? badge;

  /// Lista de items de información para mostrar cuando está expandido
  /// Cada item debe tener: 'icon', 'label', 'value'
  final List<ExpandableInfoItem> expandedInfo;

  /// Widget personalizado para el trailing (derecha) antes del ícono de expansión
  final Widget? trailing;

  /// Si es responsive para mobile
  final bool isMobile;

  /// Color de fondo del contenedor
  final Color? backgroundColor;

  /// Color del borde cuando está colapsado
  final Color? borderColor;

  /// Color del borde cuando está expandido
  final Color? expandedBorderColor;

  /// Radio de los bordes
  final double? borderRadius;

  /// Padding interno
  final EdgeInsets? padding;

  /// Estado inicial (expandido/colapsado)
  final bool initiallyExpanded;

  /// Callback cuando cambia el estado de expansión
  final ValueChanged<bool>? onExpansionChanged;

  /// {@macro expandable_premium_list_tile}
  const ExpandablePremiumListTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    required this.expandedInfo,
    this.subtitle,
    this.badge,
    this.trailing,
    this.isMobile = false,
    this.backgroundColor,
    this.borderColor,
    this.expandedBorderColor,
    this.borderRadius,
    this.padding,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<ExpandablePremiumListTile> createState() =>
      _ExpandablePremiumListTileState();
}

class _ExpandablePremiumListTileState extends State<ExpandablePremiumListTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;
  
  // Cache para el contenido expandido (lazy loading)
  Widget? _cachedExpandedContent;
  bool _hasBuiltExpandedContent = false;

  static const _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(ExpandablePremiumListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidar cache si cambia la información expandida
    if (oldWidget.expandedInfo != widget.expandedInfo) {
      _cachedExpandedContent = null;
      _hasBuiltExpandedContent = false;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ?? 16.0;
    final effectivePadding =
        widget.padding ?? EdgeInsets.all(widget.isMobile ? 12 : 14);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Calcular color del borde solo cuando cambia la animación
        final borderColor = _isExpanded
            ? (widget.expandedBorderColor ??
                theme.colorScheme.primary.withValues(alpha: 0.3))
            : (widget.borderColor ??
                theme.dividerColor.withValues(alpha: 0.5));
        
        final borderWidth = _isExpanded ? 1.5 : 0.5;

        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado clickeable con RepaintBoundary
              RepaintBoundary(
                child: _buildHeader(theme, effectiveBorderRadius, effectivePadding),
              ),

              // Contenido expandible con lazy loading
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: RepaintBoundary(
                  child: _buildExpandedContentLazy(theme, effectivePadding),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    double borderRadius,
    EdgeInsets padding,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              // Icono principal con animación optimizada (opcional)
              if (widget.icon != null) ...[
                _buildAnimatedIcon(theme),
                SizedBox(width: widget.isMobile ? 12 : 14),
              ],

              // Contenido principal (título y subtítulo)
              Expanded(
                child: _buildContent(theme),
              ),

              const SizedBox(width: 8),

              // Badge de estado (opcional)
              if (widget.badge != null) ...[
                _buildBadge(theme),
                const SizedBox(width: 12),
              ],

              // Trailing personalizado (opcional)
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 12),
              ],

              // Icono de expansión animado
              RotationTransition(
                turns: _iconRotation,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: widget.isMobile ? 24 : 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(ThemeData theme) {
    // Usar AnimatedBuilder para evitar reconstrucciones innecesarias
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final alpha = _isExpanded ? 0.15 : 0.12;
        return Container(
          padding: EdgeInsets.all(widget.isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: (widget.iconColor ?? theme.colorScheme.primary).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        );
      },
      child: Icon(
        widget.icon!,
        size: widget.isMobile ? 20 : 24,
        color: widget.iconColor ?? theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título (String o Widget)
        if (widget.title is String)
          Text(
            widget.title,
            style: (widget.isMobile
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          widget.title,

        // Subtítulo (opcional)
        if (widget.subtitle != null) ...[
          SizedBox(height: widget.isMobile ? 4 : 6),
          DefaultTextStyle(
            style: (widget.isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                const TextStyle(),
            child: widget.subtitle!,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(ThemeData theme) {
    if (widget.badge == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 10,
        vertical: widget.isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: widget.badge!.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto de estado
          if (widget.badge!.showDot)
            Container(
              width: widget.isMobile ? 6 : 8,
              height: widget.isMobile ? 6 : 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: widget.badge!.color,
                shape: BoxShape.circle,
              ),
            ),
          // Texto del badge
          Text(
            widget.badge!.label,
            style: (widget.isMobile
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: widget.badge!.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Lazy loading del contenido expandido - solo se construye cuando es necesario
  Widget _buildExpandedContentLazy(ThemeData theme, EdgeInsets padding) {
    // Solo construir el contenido una vez y cachearlo
    if (!_hasBuiltExpandedContent) {
      _cachedExpandedContent = _buildExpandedContent(theme, padding);
      _hasBuiltExpandedContent = true;
    }
    
    return _cachedExpandedContent!;
  }

  Widget _buildExpandedContent(ThemeData theme, EdgeInsets padding) {
    // Pre-calcular valores que no cambian
    final dividerColor = theme.dividerColor.withValues(alpha: 0.3);
    final effectiveIconColor = widget.iconColor ?? theme.colorScheme.primary;
    final iconBackgroundColor = effectiveIconColor.withValues(alpha: 0.08);
    final iconColor = effectiveIconColor.withValues(alpha: 0.8);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        0,
        padding.right,
        padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divisor sutil con gradiente (simplificado para mejor rendimiento)
          Container(
            height: 1,
            margin: EdgeInsets.only(
              bottom: widget.isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  dividerColor,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Lista de información detallada (construida de una sola vez)
          ...widget.expandedInfo.map(
            (info) => _InfoRow(
              icon: info.icon,
              label: info.label,
              value: info.value,
              valueWidget: info.valueWidget,
              isMobile: widget.isMobile,
              iconBackgroundColor: iconBackgroundColor,
              iconColor: iconColor,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget separado y optimizado para cada fila de información
/// Esto permite que Flutter optimice mejor el rendering
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isMobile;
  final Color iconBackgroundColor;
  final Color iconColor;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.theme,
    required this.isMobile,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Row(
        children: [
          // Icono con fondo
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: isMobile ? 16 : 18,
              color: iconColor,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: (isMobile
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Valor (texto o widget personalizado)
          if (valueWidget != null)
            valueWidget!
          else if (value != null)
            Text(
              value!,
              style: (isMobile
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

/// {@template expandable_info_item}
/// Item de información para mostrar en el contenido expandido
/// {@endtemplate}
class ExpandableInfoItem {
  /// Icono del item
  final IconData icon;

  /// Etiqueta del item
  final String label;

  /// Valor del item (texto)
  final String? value;

  /// Widget personalizado para el valor (alternativa a [value])
  final Widget? valueWidget;

  /// {@macro expandable_info_item}
  const ExpandableInfoItem({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(
          value != null || valueWidget != null,
          'Debe proporcionar value o valueWidget',
        );
}
