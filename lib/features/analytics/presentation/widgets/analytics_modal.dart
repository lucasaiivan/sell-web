import 'package:flutter/material.dart';

/// Widget: Modal Base para Analytics
///
/// **Responsabilidad:**
/// - Proporcionar una base visual consistente para todos los modales de analytics
/// - Unificar el patrón de diseño: handle, header con icono, contenido
/// - Manejar animaciones y transiciones suaves
/// - Soportar contenido dinámico y listas
///
/// **Uso:**
/// Todos los modales de analytics deben usar este widget como base
/// para mantener un aspecto visual coherente y reducir duplicación.
class AnalyticsModal extends StatelessWidget {
  /// Color de acento del modal (usado en header y decoraciones)
  final Color accentColor;

  /// Icono principal del header
  final IconData icon;

  /// Título del modal
  final String title;

  /// Subtítulo opcional (descripción)
  final String? subtitle;

  /// Widget adicional en el header (ej: estadísticas)
  final Widget? headerAction;

  /// Widget informativo opcional (aparece debajo del header)
  final Widget? infoWidget;

  /// Contenido principal del modal
  final Widget child;

  /// Altura máxima como factor del alto de pantalla (0.0 - 1.0)
  final double maxHeightFactor;

  /// Si el contenido debe expandirse para llenar el espacio disponible
  final bool expandContent;

  const AnalyticsModal({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerAction,
    this.infoWidget,
    this.maxHeightFactor = 0.85,
    this.expandContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar con animación sutil
          _ModalHandle(colorScheme: colorScheme),

          // Header mejorado
          _ModalHeader(
            accentColor: accentColor,
            icon: icon,
            title: title,
            subtitle: subtitle,
            headerAction: headerAction,
          ),

          // Divider con gradiente sutil
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.outlineVariant.withValues(alpha: 0.0),
                  colorScheme.outlineVariant.withValues(alpha: 0.5),
                  colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Widget informativo opcional
          if (infoWidget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: infoWidget!,
            ),

          // Contenido principal
          if (expandContent) Flexible(child: child) else child,

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Handle del modal con diseño mejorado
class _ModalHandle extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ModalHandle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Header del modal con diseño Material 3 mejorado
class _ModalHeader extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? headerAction;

  const _ModalHeader({
    required this.accentColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Row(
        children: [
          // Icono con contenedor decorado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Acción del header o botón de cerrar por defecto
          headerAction ??
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
        ],
      ),
    );
  }
}

/// Widget: Card de información/tip para modales
/// Usado para mostrar consejos o información contextual
class AnalyticsInfoCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const AnalyticsInfoCard({
    super.key,
    required this.icon,
    required this.message,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  /// Preset: Consejo/Tip (amarillo/ámbar)
  factory AnalyticsInfoCard.tip({
    required String message,
    IconData icon = Icons.lightbulb_outline_rounded,
  }) {
    return AnalyticsInfoCard(
      icon: icon,
      message: message,
      backgroundColor: const Color(0xFFFEF3C7),
      iconColor: const Color(0xFFF59E0B),
      textColor: const Color(0xFF92400E),
    );
  }

  /// Preset: Información (azul)
  factory AnalyticsInfoCard.info({
    required String message,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return AnalyticsInfoCard(
      icon: icon,
      message: message,
      backgroundColor: const Color(0xFFDBEAFE),
      iconColor: const Color(0xFF2563EB),
      textColor: const Color(0xFF1E40AF),
    );
  }

  /// Preset: Alerta (rojo)
  factory AnalyticsInfoCard.alert({
    required String message,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return AnalyticsInfoCard(
      icon: icon,
      message: message,
      backgroundColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFEF4444),
      textColor: const Color(0xFF991B1B),
    );
  }

  /// Preset: Éxito (verde)
  factory AnalyticsInfoCard.success({
    required String message,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    return AnalyticsInfoCard(
      icon: icon,
      message: message,
      backgroundColor: const Color(0xFFD1FAE5),
      iconColor: const Color(0xFF10B981),
      textColor: const Color(0xFF065F46),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores por defecto adaptados al tema
    final effectiveBackgroundColor = backgroundColor ??
        (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : const Color(0xFFF3F4F6));
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: effectiveIconColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: effectiveIconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: effectiveTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget: Item de lista para modales con diseño premium
/// Usado para mostrar items en listas de modales con posición/ranking
class AnalyticsListItem extends StatelessWidget {
  /// Posición en el ranking (1, 2, 3...)
  final int? position;

  /// Widget leading (avatar, icono, etc.)
  final Widget leading;

  /// Título principal
  final String title;

  /// Subtítulo o descripción
  final String? subtitle;

  /// Widget adicional en el subtítulo
  final Widget? subtitleWidget;

  /// Widgets en el trailing (derecha)
  final List<Widget>? trailingWidgets;

  /// Color de acento (usado para posiciones top 3)
  final Color? accentColor;

  /// Callback al hacer tap
  final VoidCallback? onTap;

  const AnalyticsListItem({
    super.key,
    this.position,
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailingWidgets,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores especiales para top 3
    Color? positionColor;
    if (position != null) {
      switch (position) {
        case 1:
          positionColor = const Color(0xFFFFD700); // Oro
          break;
        case 2:
          positionColor = const Color(0xFFC0C0C0); // Plata
          break;
        case 3:
          positionColor = const Color(0xFFCD7F32); // Bronce
          break;
      }
    }

    final isTopThree = position != null && position! <= 3;
    final effectiveAccentColor = positionColor ?? accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isTopThree && positionColor != null
            ? positionColor.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree && positionColor != null
              ? positionColor.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Leading con badge de posición
                if (position != null)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      leading,
                      // Badge de posición
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: effectiveAccentColor ?? colorScheme.primary,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$position',
                              style: TextStyle(
                                color: isTopThree
                                    ? Colors.black87
                                    : colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  leading,

                const SizedBox(width: 14),

                // Contenido central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null || subtitleWidget != null) ...[
                        const SizedBox(height: 3),
                        if (subtitleWidget != null)
                          subtitleWidget!
                        else
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ],
                  ),
                ),

                // Trailing widgets
                if (trailingWidgets != null && trailingWidgets!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: trailingWidgets!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget: Avatar de producto para listas
class AnalyticsProductAvatar extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color? borderColor;
  final double size;

  const AnalyticsProductAvatar({
    super.key,
    this.imageUrl,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.borderColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBorderColor = borderColor ?? colorScheme.outlineVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: effectiveBorderColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(colorScheme),
              )
            : _buildFallback(colorScheme),
      ),
    );
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        fallbackIcon,
        size: size * 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Widget: Badge/Chip para estadísticas
class AnalyticsBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AnalyticsBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget: Estado vacío para modales
class AnalyticsModalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const AnalyticsModalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor ?? colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
