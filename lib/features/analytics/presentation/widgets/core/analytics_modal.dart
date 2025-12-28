import 'package:flutter/material.dart';
import 'package:sellweb/core/presentation/modals/base_bottom_sheet.dart';

/// Widget: Modal Base para Analytics
///
/// **Responsabilidad:**
/// - Proporcionar una base visual consistente para todos los modales de analytics
/// - Unificar el patrón de diseño usando [BaseBottomSheet]
/// - Soportar contenido dinámico y listas
///
/// **Uso:**
/// Todos los modales de analytics deben usar este widget como base
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
  /// Reemplaza al botón de cerrar si se proporciona
  final Widget? headerAction;

  /// Widget informativo opcional (aparece debajo del header)
  final Widget? infoWidget;

  /// Contenido principal del modal
  final Widget child;

  /// Altura máxima como factor del alto de pantalla (0.0 - 1.0)
  final double maxHeightFactor;

  /// Si el contenido debe expandirse para llenar el espacio disponible
  final bool expandContent;

  /// Callback para búsqueda. Si se proporciona, se habilita el botón de búsqueda en el header.
  final ValueChanged<String>? onSearch;
  
  /// Texto hint para el buscador
  final String searchHint;
  
  /// Controlador opcional parea el buscador
  final TextEditingController? searchController;

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
    this.onSearch,
    this.searchHint = 'Buscar...',
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      // Usamos el color de acento para el icono
      iconColor: accentColor,
      headerExtra: headerAction,
      maxHeightFactor: maxHeightFactor,
      onSearch: onSearch,
      searchHint: searchHint,
      searchController: searchController,
      body: Column(
        children: [
          // Widget informativo opcional
          if (infoWidget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: infoWidget!,
            ),

          // Contenido principal
          if (expandContent)
            Expanded(child: child)
          else
            child,
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

  /// Icono o widget opcional que se muestra antes del título
  final Widget? titlePrefix;

  /// Widget opcional que se renderiza debajo del item (ej: barra de progreso)
  final Widget? child;

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
    this.child,
    this.titlePrefix,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                                color:
                                    effectiveAccentColor ?? colorScheme.primary,
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
                          Row(
                            children: [
                              if (titlePrefix != null) ...[
                                titlePrefix!,
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

                // Child opcional debajo del item (ej: barra de progreso)
                if (child != null) ...[
                  const SizedBox(height: 8),
                  child!,
                ],
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

/// Widget: Banner de feedback/información para modales
///
/// **Responsabilidad:**
/// - Mostrar mensajes informativos, consejos o alertas en los modales
/// - Diseño con borde y sin fondo para no ser intrusivo
/// - Reutilizable en todos los modales de analytics
///
class AnalyticsFeedbackBanner extends StatelessWidget {
  /// Icono a mostrar en el banner
  final Widget? icon;

  /// Mensaje de texto
  final String message;

  /// Color de acento (opcional, usa onSurfaceVariant por defecto)
  final Color? accentColor;

  /// Margen del contenedor (opcional)
  final EdgeInsetsGeometry? margin;

  const AnalyticsFeedbackBanner({
    super.key,
    this.icon,
    required this.message,
    this.accentColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedbackColor = accentColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: feedbackColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(
              color: feedbackColor,
              size: 20,
            ),
            child: icon ?? const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: 0.7,
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget: Tarjeta de resumen con dos métricas para modales
///
/// **Responsabilidad:**
/// - Mostrar dos métricas principales lado a lado
/// - Diseño consistente con gradiente y bordes
/// - Reutilizable en todos los modales de analytics
///
/// Clase auxiliar para representar una métrica
class AnalyticsMetric {
  final String value;
  final String label;

  const AnalyticsMetric({
    required this.value,
    required this.label,
  });
}

/// Widget: Tarjeta de Estado para Modales de Analytics
///
/// **Responsabilidad:**
/// - Mostrar indicadores de estado/tendencia con icono, valor y feedback
/// - Mostrar métricas adicionales (izquierda y derecha) opcionalmente
/// - Diseño flexible y reutilizable para múltiples propósitos
/// - Soportar valores numéricos, porcentajes, etiquetas, etc.
///
/// **Modos de uso:**
/// 1. Con mainValue/mainLabel: Muestra valor principal + feedback
/// 2. Con leftMetric/rightMetric: Muestra dos métricas lado a lado
class AnalyticsStatusCard extends StatelessWidget {
  /// Valor principal a mostrar (ej: "15.5%", "+\$1000", "87")
  /// Si es null, se usa el modo de dos métricas (leftMetric/rightMetric)
  final String? mainValue;

  /// Etiqueta o descripción del valor principal
  final String? mainLabel;

  /// Icono principal (en círculo decorativo)
  final IconData? icon;

  /// Color de acento para el card
  final Color statusColor;

  /// Icono para el área de feedback
  final IconData? feedbackIcon;

  /// Texto de feedback/descripción contextual
  final String? feedbackText;

  /// Métrica izquierda (opcional, para modo de dos métricas)
  final AnalyticsMetric? leftMetric;

  /// Métrica derecha (opcional, para modo de dos métricas)
  final AnalyticsMetric? rightMetric;

  /// Tamaño del icono principal (opcional)
  final double iconSize;

  /// Si el card debe mostrar signo + en valores positivos (opcional)
  final bool showPlusSign;

  const AnalyticsStatusCard({
    super.key,
    this.mainValue,
    this.mainLabel,
    this.icon,
    required this.statusColor,
    this.feedbackIcon,
    this.feedbackText,
    this.leftMetric,
    this.rightMetric,
    this.iconSize = 24,
    this.showPlusSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un único layout que permite mostrar:
    // - Icono + valor principal (si se pasa)
    // - Una fila de métricas (leftMetric/rightMetric) opcional
    // - Feedback opcional
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila: Icono + Valor principal (si se proporciona alguno)
          if (icon != null || mainValue != null || mainLabel != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: statusColor,
                      size: iconSize,
                    ),
                  ),
                if (icon != null) const SizedBox(width: 12),
                if (mainValue != null || mainLabel != null)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mainValue != null)
                          Text(
                            mainValue!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        if (mainLabel != null)
                          Text(
                            mainLabel!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),

          // Métricas: pueden mostrarse junto con el valor principal
          if (leftMetric != null || rightMetric != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (leftMetric != null)
                  Expanded(child: _buildMetricColumn(context, leftMetric!)),
                if (leftMetric != null && rightMetric != null)
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                if (rightMetric != null)
                  Expanded(child: _buildMetricColumn(context, rightMetric!)),
              ],
            ),
          ],

          // Feedback contextual
          if (feedbackText != null) const SizedBox(height: 12),
          if (feedbackText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (feedbackIcon != null)
                    Icon(
                      feedbackIcon,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  if (feedbackIcon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      feedbackText!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Construye una columna para mostrar una métrica
  Widget _buildMetricColumn(BuildContext context, AnalyticsMetric metric) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          metric.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          metric.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
