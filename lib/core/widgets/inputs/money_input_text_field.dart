import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/utils/fuctions.dart';

/// TextField reutilizable para ingreso de montos, con formato y estilo Material 3.
/// Permite personalizar el controlador, el valor inicial y la función onChanged.
class MoneyInputTextField extends StatelessWidget {
  final AppMoneyTextEditingController controller;
  final void Function(double value)? onChanged;
  final void Function(String value)? onTextChanged;
  final void Function(double value)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String labelText;
  final String? errorText;
  final Color? fillColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const MoneyInputTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onTextChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.nextFocusNode,
    this.labelText = 'Monto',
    this.errorText,
    this.fillColor,
    this.inputFormatters,
    this.autofocus = false,
    this.style,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters ?? [AppMoneyInputFormatter()],
      autofocus: autofocus,
      style: style ?? theme.textTheme.titleLarge,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: false,
        fillColor: fillColor ??
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
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
