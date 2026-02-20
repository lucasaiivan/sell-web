import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/core.dart';

/// TextField reutilizable para ingreso de montos, con formato y estilo Material 3.
/// Permite personalizar el controlador, el valor inicial y la función onChanged.
/// Mantiene el mismo patrón de diseño visual que InputTextField para consistencia.
/// Implementa feedback visual: fondo con opacidad cuando está vacío, transparente cuando tiene datos.
class MoneyInputTextField extends StatefulWidget {
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
  final bool enabled;

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
    this.borderRadius = UIConstants.defaultRadius,
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
    this.enabled = true,
  });

  @override
  State<MoneyInputTextField> createState() => _MoneyInputTextFieldState();
}

class _MoneyInputTextFieldState extends State<MoneyInputTextField> {
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _hasValue = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateHasValue);
  }

  @override
  void didUpdateWidget(MoneyInputTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateHasValue);
      _hasValue = widget.controller.text.isNotEmpty;
      widget.controller.addListener(_updateHasValue);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasValue);
    super.dispose();
  }

  void _updateHasValue() {
    final newHasValue = widget.controller.text.isNotEmpty;
    if (_hasValue != newHasValue) {
      setState(() {
        _hasValue = newHasValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar el color de fondo: transparente si tiene valor, con más opacidad si está vacío
    final effectiveFillColor = widget.fillColor ?? 
        (_hasValue 
            ? Colors.transparent 
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5));

    // Determinar el color del borde por defecto
    final defaultBorderColor = widget.borderColor ??
        (_hasValue
            ? colorScheme.outline.withValues(alpha: 0.4)
            : colorScheme.onSurface.withValues(alpha: 0.3));

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType ??
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      inputFormatters: widget.inputFormatters ?? [AppMoneyInputFormatter()],
      autofocus: widget.autofocus,
      style: widget.fontSize != null
          ? (widget.style ?? theme.textTheme.titleLarge)?.copyWith(fontSize: widget.fontSize)
          : (widget.style ?? theme.textTheme.titleLarge),
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      validator: widget.validator,
      textAlign: widget.center ? TextAlign.center : TextAlign.start,
      decoration: InputDecoration(
        labelText: widget.labelText.isEmpty ? null : widget.labelText,
        hintText: widget.labelText.isEmpty ? (widget.hintText ?? '0.0') : widget.hintText,
        hintStyle: (widget.style ?? theme.textTheme.titleLarge)?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: widget.fontSize,
        ),
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.showCurrencyIcon ? const Icon(Icons.attach_money) : null,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        // Configuración de bordes y colores (mismo patrón que InputTextField)
        filled: true,
        fillColor: effectiveFillColor,

        // Borde normal
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: 1.0,
          ),
        ),

        // Borde cuando está habilitado
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: 1.0,
          ),
        ),

        // Borde cuando está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.0,
          ),
        ),

        // Borde cuando tiene error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.0,
          ),
        ),

        // Borde cuando está enfocado y tiene error
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0,
          ),
        ),

        // Borde cuando está deshabilitado
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
      ),
      onChanged: (value) {
        // Forzar actualización del controlador para asegurar sincronía
        widget.controller.value = widget.controller.value.copyWith(text: value);
        if (widget.onChanged != null) {
          // Usar el getter doubleValue del controlador, que siempre está formateado correctamente
          widget.onChanged!(widget.controller.doubleValue);
        }
        if (widget.onTextChanged != null) {
          widget.onTextChanged!(value);
        }
      },
      onFieldSubmitted: (value) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(widget.controller.doubleValue);
        }
      },
      onEditingComplete: () {
        // Si se especifica un callback personalizado, ejecutarlo
        if (widget.onEditingComplete != null) {
          widget.onEditingComplete!();
        }
        // Si se especifica un nodo de enfoque siguiente, mover el foco
        else if (widget.nextFocusNode != null) {
          widget.nextFocusNode!.requestFocus();
        }
        // Si no hay callback ni nodo siguiente, dejar el comportamiento por defecto
        else {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }
}
