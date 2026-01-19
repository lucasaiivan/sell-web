import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/core.dart';

/// TextField reutilizable para ingreso de montos, con formato y estilo Material 3.
/// Permite personalizar el controlador, el valor inicial y la función onChanged.
/// Mantiene el mismo patrón de diseño visual que InputTextField para consistencia.
class MoneyInputTextField extends StatelessWidget {
  final AppMoneyTextEditingController controller;
  final void Function(double value)? onChanged;
  final void Function(String value)? onTextChanged;
  final void Function(double value)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool center;
  final double? fontSize;
  final TextInputType? keyboardType;
  final bool showCurrencyIcon;
  final EdgeInsetsGeometry? contentPadding;

  const MoneyInputTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onTextChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.nextFocusNode,
    this.labelText = '',
    this.hintText,
    this.helperText,
    this.errorText,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 2.0,
    this.inputFormatters,
    this.autofocus = false,
    this.style,
    this.textInputAction,
    this.validator,
    this.center = false,
    this.fontSize,
    this.keyboardType,
    this.showCurrencyIcon = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ??
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      inputFormatters: inputFormatters ?? [AppMoneyInputFormatter()],
      autofocus: autofocus,
      style: fontSize != null
          ? (style ?? theme.textTheme.titleLarge)?.copyWith(fontSize: fontSize)
          : (style ?? theme.textTheme.titleLarge),
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator,
      textAlign: center ? TextAlign.center : TextAlign.start,
      decoration: InputDecoration(
        labelText: labelText.isEmpty ? null : labelText,
        hintText: labelText.isEmpty ? (hintText ?? '0.0') : hintText,
        hintStyle: (style ?? theme.textTheme.titleLarge)?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: fontSize,
        ),
        helperText: helperText,
        errorText: errorText,
        prefixIcon: showCurrencyIcon ? const Icon(Icons.attach_money) : null,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        // Configuración de bordes y colores (mismo patrón que InputTextField)
        filled: true,
        fillColor: fillColor ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),

        // Borde normal
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: borderColor ?? colorScheme.outline,
            width: 1.0,
          ),
        ),

        // Borde cuando está habilitado
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: borderColor ?? colorScheme.outline,
            width: 1.0,
          ),
        ),

        // Borde cuando está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.0,
          ),
        ),

        // Borde cuando tiene error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.0,
          ),
        ),

        // Borde cuando está enfocado y tiene error
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0,
          ),
        ),

        // Borde cuando está deshabilitado
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
      ),
      onChanged: (value) {
        // Forzar actualización del controlador para asegurar sincronía
        controller.value = controller.value.copyWith(text: value);
        if (onChanged != null) {
          // Usar el getter doubleValue del controlador, que siempre está formateado correctamente
          onChanged!(controller.doubleValue);
        }
        if (onTextChanged != null) {
          onTextChanged!(value);
        }
      },
      onFieldSubmitted: (value) {
        if (onSubmitted != null) {
          onSubmitted!(controller.doubleValue);
        }
      },
      onEditingComplete: () {
        // Si se especifica un callback personalizado, ejecutarlo
        if (onEditingComplete != null) {
          onEditingComplete!();
        }
        // Si se especifica un nodo de enfoque siguiente, mover el foco
        else if (nextFocusNode != null) {
          nextFocusNode!.requestFocus();
        }
        // Si no hay callback ni nodo siguiente, dejar el comportamiento por defecto
        else {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }
}
