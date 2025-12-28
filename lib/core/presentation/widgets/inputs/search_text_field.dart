import 'package:flutter/material.dart';

/// Widget base reutilizable para campos de búsqueda
/// 
/// **Características:**
/// - Puede funcionar como TextField interactivo o como botón de búsqueda (read-only)
/// - Contador de resultados opcional
/// - Botón de limpiar automático
/// - Diseño adaptativo con Material Design 3
/// - Personalización completa de colores y estilos
/// 
/// **Uso como TextField:**
/// ```dart
/// SearchTextField(
///   controller: _controller,
///   focusNode: _focusNode,
///   hintText: 'Buscar...',
///   onChanged: (query) => print(query),
/// )
/// ```
/// 
/// **Uso como Botón:**
/// ```dart
/// SearchTextField(
///   hintText: 'Buscar productos',
///   readOnly: true,
///   onTap: () => showSearchDialog(),
/// )
/// ```
class SearchTextField extends StatelessWidget {
  /// Controlador del campo de texto (opcional si es read-only)
  final TextEditingController? controller;

  /// FocusNode del campo de texto (opcional si es read-only)
  final FocusNode? focusNode;

  /// Texto de placeholder
  final String hintText;

  /// Callback cuando cambia el texto
  final ValueChanged<String>? onChanged;

  /// Callback cuando se presiona el botón de limpiar
  final VoidCallback? onClear;

  /// Callback cuando se presiona el campo (útil para modo botón)
  final VoidCallback? onTap;

  /// Si el campo debe tener autofocus
  final bool autofocus;

  /// Contador de resultados de búsqueda (opcional)
  final int? searchResultsCount;

  /// Mostrar contador de resultados
  final bool showResultsCounter;

  /// Si el campo es de solo lectura (modo botón)
  final bool readOnly;

  /// Ícono principal (por defecto: search)
  final IconData icon;

  /// Ícono trailing opcional (solo en modo read-only)
  final IconData? trailingIcon;

  /// Widget personalizado para mostrar cuando hay carga
  final Widget? loadingWidget;

  /// Si está en estado de carga
  final bool isLoading;

  /// Color de fondo personalizado
  final Color? backgroundColor;

  /// Color del borde cuando está enfocado
  final Color? focusedBorderColor;

  /// Altura del campo
  final double? height;

  /// Ancho del campo
  final double? width;

  /// Constructor simplificado para usar como botón de acción
  ///
  /// Solo muestra el ícono y el texto, ideal para disparar modales de búsqueda.
  factory SearchTextField.button({
    VoidCallback? onTap,
    String label = 'Buscar...',
    IconData icon = Icons.search_rounded,
    bool isLoading = false,
    Widget? loadingWidget,
    double? height,
    double? width,
    Color? backgroundColor,
    Key? key,
  }) {
    return SearchTextField(
      key: key,
      hintText: label,
      readOnly: true,
      onTap: onTap,
      icon: icon,
      isLoading: isLoading,
      loadingWidget: loadingWidget,
      height: height,
      width: width,
      backgroundColor: backgroundColor,
      showResultsCounter: false,
      trailingIcon: null, // Sin icono al final para cumplir con "solo icon y text"
    );
  }

  const SearchTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
    this.onTap,
    this.autofocus = false,
    this.searchResultsCount,
    this.showResultsCounter = true,
    this.readOnly = false,
    this.icon = Icons.search_rounded,
    this.trailingIcon,
    this.loadingWidget,
    this.isLoading = false,
    this.backgroundColor,
    this.focusedBorderColor,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Usar controlador interno si no se proporciona uno (para modo read-only)
    final effectiveController = controller ?? TextEditingController();
    final effectiveFocusNode = focusNode ?? FocusNode();

    // Color de fondo adaptativo - por defecto usa el estilo de botón
    final bgColor = backgroundColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5);

    // Altura efectiva
    final effectiveHeight = height ?? 44.0;

    // Border radius adaptativo - por defecto usa bordes redondeados (estilo botón)
    final borderRadius = effectiveHeight / 3;

    Widget content = Container(
      width: width,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: !readOnly && effectiveFocusNode.hasFocus
              ? (focusedBorderColor ?? colorScheme.primary.withValues(alpha: 0.2))
              : colorScheme.outline.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: readOnly ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono principal
          Padding(
            padding: EdgeInsets.only(
              left: readOnly ? 16 : 12,
              right: readOnly ? 12 : 8,
            ),
            child: isLoading && loadingWidget != null
                ? loadingWidget!
                : Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
          ),

          // Campo de texto o Texto estático
          Expanded(
            child: readOnly
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Text(
                      effectiveController.text.isNotEmpty
                          ? effectiveController.text
                          : hintText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: effectiveController.text.isNotEmpty
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : TextField(
                    controller: effectiveController,
                    focusNode: effectiveFocusNode,
                    autofocus: autofocus,
                    readOnly: readOnly,
                    maxLines: 1,
                    onChanged: onChanged,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
          ),

          // Contador de resultados
          if (showResultsCounter &&
              searchResultsCount != null &&
              effectiveController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: searchResultsCount == 0
                      ? colorScheme.errorContainer.withValues(alpha: 0.3)
                      : colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: searchResultsCount == 0
                        ? colorScheme.error.withValues(alpha: 0.3)
                        : colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  searchResultsCount == 0
                      ? 'Sin resultados'
                      : '$searchResultsCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: searchResultsCount == 0
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

          // Botón de limpiar o ícono trailing
          if (!readOnly && effectiveController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                icon: Icon(
                  Icons.clear_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: () {
                  effectiveController.clear();
                  onClear?.call();
                },
              ),
            )
          else if (readOnly && trailingIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                trailingIcon,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            )
          else if (!readOnly)
            const SizedBox(width: 8),
        ],
      ),
    );

    // Si es read-only, envolver en InkWell para hacerlo clickeable
    if (readOnly && onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: colorScheme.primary.withValues(alpha: 0.05),
            highlightColor: colorScheme.primary.withValues(alpha: 0.02),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
