import 'package:flutter/material.dart';
import '../../../widgets/inputs/money_input_text_field.dart';

/// Componentes de UI estandarizados para diálogos siguiendo Material Design 3
class DialogComponents {
  DialogComponents._();

  /// Sección de información con contenedor estilizado
  static Widget infoSection({
    String title = '',
    required Widget content,
    IconData? icon,
    Color? backgroundColor,
    Color? accentColor, 
    Widget? rightIcon,
    required BuildContext context,
  }) {

    final theme = Theme.of(context);
    final effectiveAccentColor = accentColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // icon : ícono de la sección
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: effectiveAccentColor,
                ), 
              ],
              // text : título de la sección
              title.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: effectiveAccentColor,
                      ),
                    ),
              const Spacer(),
              // iconbutton : botones personalizados de accion
              if (rightIcon != null) rightIcon,
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  /// Lista de elementos con divisores estilizados y funcionalidad de expandir/colapsar
  ///
  /// Características:
  /// - Automáticamente usa ExpandableListContainer para listas largas (> maxVisibleItems)
  /// - Diseño responsivo que se adapta a móvil/tablet/desktop
  /// - Soporte para títulos opcionales y textos personalizados de expansión
  /// - Divisores configurables entre elementos
  /// - Estilo consistente con Material Design 3
  /// - Opciones de UI: outlined (por defecto) o filled
  static Widget itemList({
    required List<Widget> items,
    bool showDividers = true,
    String? title,
    int maxVisibleItems = 5,
    String? expandText,
    String? collapseText,
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 12,
    bool useFillStyle = false, // Nueva opción para estilo fill
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Configuración de estilo basada en useFillStyle
    final BoxDecoration decoration; 
    final Color dividerColor;

    if (useFillStyle) {
      // Estilo fill: contenedor con background sólido y sin borde 
      dividerColor = theme.colorScheme.outline.withValues(alpha: 0.1);
      decoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    } else {
      // Estilo outlined: contenedor transparente con borde
      dividerColor = lineColor;
      decoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? lineColor, width: 1),
      );
    }

    // Para listas largas, usar ExpandableListContainer
    return Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      padding: padding, // Solo se aplicará si se proporciona explícitamente
      child: ExpandableListContainer<Widget>(
        items: items,
        isMobile: isMobile,
        theme: theme,
        title: title,
        maxVisibleItems: maxVisibleItems,
        expandText: expandText,
        collapseText: collapseText,
        showDividers: showDividers,
        backgroundColor: backgroundColor,
        borderColor: borderColor ?? lineColor,
        borderRadius: borderRadius,
        useFillStyle: useFillStyle,
        itemBuilder: (context, item, index, isLast) {
          // Para el estilo fill, agregar padding interno a cada item
          final Widget wrappedItem = useFillStyle
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,
                  ),
                  child: item,
                )
              : item;

          return Column(
            children: [
              wrappedItem,
              if (showDividers && !isLast)
                Divider(
                  thickness: useFillStyle ? 0.5 : 1,
                  color: dividerColor,
                  height: useFillStyle ? 1 : 0,
                  indent:useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0),
                  endIndent:useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Lista tipada con funcionalidad expandible para datos específicos
  static Widget expandableDataList<T>({
    required List<T> items,
    required Widget Function(
            BuildContext context, T item, int index, bool isLast)
        itemBuilder,
    String? title,
    int maxVisibleItems = 5,
    String? expandText,
    String? collapseText,
    bool showDividers = true,
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 12,
    bool useFillStyle = false, // Nueva opción para estilo fill
    EdgeInsetsGeometry? padding,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: padding,
      child: ExpandableListContainer<T>(
        items: items,
        itemBuilder: (context, item, index, isLast) {
          final builtItem = itemBuilder(context, item, index, isLast);

          // Para el estilo fill, agregar padding interno
          final Widget wrappedItem = useFillStyle
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,
                  ),
                  child: builtItem,
                )
              : builtItem;

          // Si no queremos divisores, devolver el item directamente
          if (!showDividers) return wrappedItem;

          // Si queremos divisores, envolverlo en un Column con Divider
          final dividerColor = useFillStyle
              ? theme.colorScheme.outline.withValues(alpha: 0.1)
              : theme.colorScheme.outline.withValues(alpha: 0.2);

          return Column(
            children: [
              wrappedItem,
              if (!isLast)
                Divider(
                  height: useFillStyle ? 1 : 1,
                  thickness: useFillStyle ? 0.5 : 1,
                  color: dividerColor,
                  indent:
                      useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0),
                  endIndent:
                      useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0),
                ),
            ],
          );
        },
        isMobile: isMobile,
        theme: theme,
        title: title,
        maxVisibleItems: maxVisibleItems,
        expandText: expandText,
        collapseText: collapseText,
        showDividers: false, // Manejamos los divisores manualmente
        backgroundColor: backgroundColor ??
            (useFillStyle
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surface),
        borderColor:
            borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: borderRadius,
        useFillStyle: useFillStyle,
      ),
    );
  }

  /// Fila de información con label y valor
  static Widget infoRow({
    required String label,
    required String value,
    IconData? icon,
    TextStyle? valueStyle,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Botón de acción primario estilizado
  static Widget primaryActionButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isDestructive = false,
    bool isLoading = false,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : icon == null
              ? null
              : Icon(icon),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor:
            isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
        foregroundColor: isDestructive
            ? theme.colorScheme.onError
            : theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal:12,
          vertical: 8,
        ),
      ),
    );
  }

  /// Botón de acción secundario estilizado
  static Widget secondaryActionButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    required BuildContext context,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    );
  }

  /// Campo de texto estilizado para diálogos
  static Widget textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction ?? TextInputAction.next,
      obscureText: obscureText,
      validator: validator,
      minLines: 1,
      maxLines: maxLines > 1 ? maxLines : null,
      expands: maxLines > 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                onPressed: onSuffixPressed,
                icon: Icon(suffixIcon),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onEditingComplete: () {
        // Si se especifica un callback personalizado, ejecutarlo
        if (onEditingComplete != null) {
          onEditingComplete();
        }
        // Si se especifica un nodo de enfoque siguiente, mover el foco
        else if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
        // Si no hay callback ni nodo siguiente, dejar el comportamiento por defecto
        else {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }

  /// Campo de dinero estilizado para diálogos
  static Widget moneyField({
    required dynamic controller, // AppMoneyTextEditingController
    required String label,
    String? hint,
    String? errorText,
    Color? fillColor,
    void Function(double value)? onChanged,
    void Function(double value)? onSubmitted,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool autofocus = false,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    required BuildContext context,
  }) {
    // Import necesario para MoneyInputTextField
    return MoneyInputTextField(
      controller: controller,
      labelText: label,
      errorText: errorText,
      fillColor: fillColor,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      nextFocusNode: nextFocusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      validator: validator,
    );
  }

  /// Contenedor de total/resumen destacado y botones de acción 'ingreso/egreso'
  static Widget summaryContainer({
    String? label,
    required String value,
    IconData? icon,
    Color? backgroundColor,
    Widget? child,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: icon == null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  label == null
                      ? const SizedBox.shrink()
                      : Opacity(
                        opacity: 0.7,
                        child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                              
                            ),
                          ),
                      ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 30, 

                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Botones de acción
        child == null ? const SizedBox.shrink() : SizedBox(height: 16),
        child ?? const SizedBox.shrink(),
      ],
    );
  }

  /// Badge/chip informativo con responsividad mejorada
  static Widget infoBadge({
    required String text,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? borderRadius,
    EdgeInsetsGeometry? margin,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsividad basada en el ancho de pantalla
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 840;

    // Ajustes responsivos para padding
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isMobile ? 8 : (isTablet ? 10 : 12),
      vertical: isMobile ? 4 : 6,
    );

    // Ajustes responsivos para el tamaño del icono
    final double iconSize = isMobile ? 14 : 16;

    // Ajustes responsivos para el espaciado entre icono y texto
    final double iconSpacing = isMobile ? 4 : 6;

    // Radio de esquinas personalizable con fallback responsivo
    final double effectiveBorderRadius =
        borderRadius ?? (isMobile ? 16 : (isTablet ? 18 : 20));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: margin,
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth > 0
                ? constraints.maxWidth * 0.8
                : double.infinity,
          ),
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: textColor ?? theme.colorScheme.onSecondaryContainer,
                ),
                SizedBox(width: iconSpacing),
              ],
              Flexible(
                child: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor ?? theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 11 : (isTablet ? 12 : null),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Divisor estilizado para diálogos siguiendo Material Design 3
  static Widget divider({
    double? thickness,
    Color? color,
    double? height,
    double? indent,
    double? endIndent,
    bool useFillStyle = false,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final effectiveThickness = thickness ?? (useFillStyle ? 0.5 : 1.0);
    final effectiveHeight = height ?? (useFillStyle ? 1.0 : 0.0);
    final effectiveColor = color ??
        (useFillStyle
            ? theme.colorScheme.outline.withValues(alpha: 0.1)
            : theme.colorScheme.outline.withValues(alpha: 0.2));

    final effectiveIndent = indent ??
        (useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0));
    final effectiveEndIndent = endIndent ??
        (useFillStyle && isMobile ? 12 : (useFillStyle ? 16 : 0));

    return Divider(
      thickness: effectiveThickness,
      height: effectiveHeight,
      color: effectiveColor,
      indent: effectiveIndent,
      endIndent: effectiveEndIndent,
    );
  }

  /// Espaciado estándar entre secciones
  static const Widget sectionSpacing = SizedBox(height: 24);

  /// Espaciado pequeño entre elementos
  static const Widget itemSpacing = SizedBox(height: 16);

  /// Espaciado mínimo entre elementos relacionados
  static const Widget minSpacing = SizedBox(height: 8);
}

/// Widget reutilizable para mostrar listas expandibles dentro de un contenedor estilizado.
///
/// Incluye ejemplos de uso con diferentes tipos de datos.
///
/// Características del widget principal:
/// - Contenedor con bordes redondeados y estilo Material Design 3
/// - Lista de elementos con separadores opcionales
/// - Funcionalidad de expandir/colapsar con límite configurable
/// - Diseño responsivo para móvil y desktop
/// - Título personalizable
/// - Soporte para widgets personalizados en cada elemento

// =============================================================================
// WIDGET PRINCIPAL: ExpandableListContainer
// =============================================================================

/// Widget reutilizable para mostrar listas expandibles dentro de un contenedor estilizado.
class ExpandableListContainer<T> extends StatefulWidget {
  /// Lista de elementos a mostrar
  final List<T> items;

  /// Función para construir cada elemento de la lista
  final Widget Function(BuildContext context, T item, int index, bool isLast)
      itemBuilder;

  /// Título de la sección (opcional)
  final String? title;

  /// Número máximo de elementos visibles inicialmente
  final int maxVisibleItems;

  /// Si es una vista móvil
  final bool isMobile;

  /// Tema de la aplicación
  final ThemeData theme;

  /// Texto para el botón "Ver más"
  final String? expandText;

  /// Texto para el botón "Ver menos"
  final String? collapseText;

  /// Si mostrar separadores entre elementos
  final bool showDividers;

  /// Color de fondo del contenedor (opcional, usa el por defecto si es null)
  final Color? backgroundColor;

  /// Color del borde (opcional, usa el por defecto si es null)
  final Color? borderColor;

  /// Radio de los bordes del contenedor
  final double borderRadius;

  /// Si usar el estilo fill en lugar de outlined
  final bool useFillStyle;

  const ExpandableListContainer({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isMobile,
    required this.theme,
    this.title,
    this.maxVisibleItems = 5,
    this.expandText,
    this.collapseText,
    this.showDividers = true,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
    this.useFillStyle = false,
  });

  @override
  State<ExpandableListContainer<T>> createState() =>
      _ExpandableListContainerState<T>();
}

class _ExpandableListContainerState<T>
    extends State<ExpandableListContainer<T>> {
  bool showAllItems = false;

  @override
  Widget build(BuildContext context) {
    final hasMoreItems = widget.items.length > widget.maxVisibleItems;
    final itemsToShow = showAllItems
        ? widget.items
        : widget.items.take(widget.maxVisibleItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección (si se proporciona)
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: (widget.isMobile
                    ? widget.theme.textTheme.bodyMedium
                    : widget.theme.textTheme.bodyLarge)
                ?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: widget.isMobile ? 8 : 12),
        ],

        // Contenedor estilizado con la lista
        Column(
          children: [
            // Items de la lista
            ...itemsToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == itemsToShow.length - 1;

              return widget.itemBuilder(context, item, index, isLast);
            }),

            // Botón "Ver más" si hay más elementos
            if (hasMoreItems && !showAllItems) ...[
              if (widget.showDividers)
                Divider(
                  thickness: widget.useFillStyle ? 0.5 : 1,
                  color: widget.useFillStyle
                      ? widget.theme.colorScheme.outline.withValues(alpha: 0.1)
                      : widget.theme.colorScheme.outline.withValues(alpha: 0.2),
                  height: widget.useFillStyle ? 1 : 0,
                  indent: widget.useFillStyle && widget.isMobile
                      ? 12
                      : (widget.useFillStyle ? 16 : 0),
                  endIndent: widget.useFillStyle && widget.isMobile
                      ? 12
                      : (widget.useFillStyle ? 16 : 0),
                ),
              InkWell(
                onTap: () => setState(() => showAllItems = true),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 16,vertical: widget.isMobile ? 8 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.expandText ?? 'Ver más',
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.expand_more_rounded,
                        color: widget.theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Botón "Ver menos" si se están mostrando todos
            if (showAllItems && hasMoreItems) ...[
              if (widget.showDividers)
                Divider(
                  thickness: widget.useFillStyle ? 0.5 : 1,
                  color: widget.useFillStyle
                      ? widget.theme.colorScheme.outline.withValues(alpha: 0.1)
                      : widget.theme.colorScheme.outline.withValues(alpha: 0.2),
                  height: widget.useFillStyle ? 1 : 0,
                  indent: widget.useFillStyle && widget.isMobile
                      ? 12
                      : (widget.useFillStyle ? 16 : 0),
                  endIndent: widget.useFillStyle && widget.isMobile
                      ? 12
                      : (widget.useFillStyle ? 16 : 0),
                ),
              InkWell(
                onTap: () => setState(() => showAllItems = false),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.borderRadius),
                  bottomRight: Radius.circular(widget.borderRadius),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 8 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Mostrando ${widget.items.length} elementos',
                          style: widget.theme.textTheme.titleSmall),
                      SizedBox(width: 8),
                      Icon(
                        Icons.expand_less_rounded,
                        color: widget.theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
