import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/utils/fuctions.dart';

/// TextField reutilizable para ingreso de montos, con formato y estilo Material 3.
/// Permite personalizar el controlador, el valor inicial y la función onChanged.
class MoneyInputTextField extends StatelessWidget {
  final AppMoneyTextEditingController controller;
  final void Function(double value)? onChanged;
  final String labelText;
  final Color? fillColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextStyle? style;

  const MoneyInputTextField({
    super.key,
    required this.controller,
    this.onChanged,
    this.labelText = 'Monto',
    this.fillColor,
    this.inputFormatters,
    this.autofocus = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters ?? [AppMoneyInputFormatter()],
      autofocus: autofocus,
      style: style ?? theme.textTheme.titleLarge,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fillColor ?? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      ),
      onChanged: (value) {
        // Forzar actualización del controlador para asegurar sincronía
        controller.value = controller.value.copyWith(text: value);
        if (onChanged != null) {
          // Usar el getter doubleValue del controlador, que siempre está formateado correctamente
          onChanged!(controller.doubleValue);
        }
      },
    );
  }
}
