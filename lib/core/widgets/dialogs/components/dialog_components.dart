import 'package:flutter/material.dart';
import 'package:sellweb/core/widgets/ui/expandable_list_container.dart';
import '../../../widgets/inputs/money_input_text_field.dart';

/// Componentes de UI estandarizados para diálogos siguiendo Material Design 3
class DialogComponents {
  DialogComponents._();

  /// Sección de información con contenedor estilizado
  static Widget infoSection({
    required String title,
    required Widget content,
    IconData? icon,
    Color? backgroundColor,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainer,
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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              title.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final decoration = BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color:borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.1),width: 1));

    // Si hay pocos elementos o no se requiere expansión, usar el diseño simple
    if (items.length <= maxVisibleItems) {
      return Container(
        decoration: decoration,
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                item,
                if (showDividers && index < items.length - 1)
                  Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ],
            );
          }).toList(),
        ),
      );
    }

    // Para listas largas, usar ExpandableListContainer
    return Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: ExpandableListContainer<Widget>(
          items: items,
          isMobile: isMobile,
          theme: theme,
          title: title,
          maxVisibleItems: maxVisibleItems,
          expandText: expandText,
          collapseText: collapseText,
          showDividers: showDividers,
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          borderColor:
              borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
          borderRadius: borderRadius,
          itemBuilder: (context, item, index, isLast) {
            return Column(
              children: [
                item,
                if (showDividers && !isLast)
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
              ],
            );
          },
        ),
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
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ExpandableListContainer<T>(
      items: items,
      itemBuilder: (context, item, index, isLast) {
        final builtItem = itemBuilder(context, item, index, isLast);

        // Si no queremos divisores, devolver el item directamente
        if (!showDividers) return builtItem;

        // Si queremos divisores, envolverlo en un Column con Divider
        return Column(
          children: [
            builtItem,
            if (!isLast)
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      borderColor:
          borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
      borderRadius: borderRadius,
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
          horizontal: 24,
          vertical: 12,
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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                onPressed: onSuffixPressed,
                icon: Icon(suffixIcon),
              )
            : null,
        border: const OutlineInputBorder(),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
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
                        : Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
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
      ),
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

  /// Espaciado estándar entre secciones
  static const Widget sectionSpacing = SizedBox(height: 24);

  /// Espaciado pequeño entre elementos
  static const Widget itemSpacing = SizedBox(height: 12);

  /// Espaciado mínimo entre elementos relacionados
  static const Widget minSpacing = SizedBox(height: 8);
}

// =============================================================================
// EJEMPLOS DE USO DE LAS LISTAS EXPANDIBLES EN DIÁLOGOS
// =============================================================================

/// Ejemplos de uso de las nuevas funcionalidades de listas expandibles en DialogComponents
class DialogListExamples {
  /// Ejemplo: Lista de productos expandible en un diálogo
  static Widget buildProductsDialog({
    required List<Map<String, dynamic>> products,
    required BuildContext context,
  }) {
    return AlertDialog(
      title: const Text('Catálogo de Productos'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usando el método expandableDataList para datos tipados
            DialogComponents.expandableDataList<Map<String, dynamic>>(
              items: products,
              title: 'Productos disponibles',
              maxVisibleItems: 4,
              expandText: 'Ver más productos',
              collapseText: 'Mostrar menos',
              showDividers: true,
              context: context,
              itemBuilder: (context, product, index, isLast) {
                return ListTile(
                  leading: const Icon(Icons.inventory),
                  title: Text(product['name'] ?? 'Producto'),
                  subtitle: Text('\$${product['price'] ?? 0}'),
                  trailing: Text('Stock: ${product['stock'] ?? 0}'),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          context: context,
        ),
      ],
    );
  }
}