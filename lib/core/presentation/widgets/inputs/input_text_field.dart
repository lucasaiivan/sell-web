import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/constants/ui_constants.dart';

/// TextField reutilizable con diseño Material 3, bordes redondeados y color de relleno.
/// Proporciona una base consistente para campos de texto en toda la aplicación.
/// Implementa feedback visual: fondo con opacidad cuando está vacío, transparente cuando tiene datos.
class InputTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final bool expandHeight;

  const InputTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.borderRadius = UIConstants.defaultRadius,
    this.style,
    this.contentPadding,
    this.expandHeight = false,
  });

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  late TextEditingController _effectiveController;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _hasValue = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_updateHasValue);
  }

  @override
  void didUpdateWidget(InputTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController.removeListener(_updateHasValue);
      _effectiveController = widget.controller ?? TextEditingController();
      _hasValue = _effectiveController.text.isNotEmpty;
      _effectiveController.addListener(_updateHasValue);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_updateHasValue);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _updateHasValue() {
    final newHasValue = _effectiveController.text.isNotEmpty;
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

    // Determinar el color del borde por defecto: más visible si está vacío, más sutil si tiene valor
    final defaultBorderColor = widget.borderColor ??
        (_hasValue
            ? colorScheme.outline.withValues(alpha: 0.4)
            : colorScheme.onSurface.withValues(alpha: 0.3));

    return TextFormField(
      controller: _effectiveController,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator, // ¡Restaurada la validación!
      style: widget.style ?? theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: (widget.style ?? theme.textTheme.bodyLarge)?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        // Configuración de bordes y colores
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
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted, // TextFormField usa onFieldSubmitted
      onTap: widget.onTap,
    );
  }
}

/// Variante de InputTextField para formularios con validación
/// Implementa feedback visual: fondo con opacidad cuando está vacío, transparente cuando tiene datos.
class FormInputTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final bool expandHeight;

  const FormInputTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.borderRadius = UIConstants.defaultRadius,
    this.style,
    this.contentPadding,
    this.expandHeight = false,
  });

  @override
  State<FormInputTextField> createState() => _FormInputTextFieldState();
}

class _FormInputTextFieldState extends State<FormInputTextField> {
  late TextEditingController _effectiveController;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _hasValue = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_updateHasValue);
  }

  @override
  void didUpdateWidget(FormInputTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController.removeListener(_updateHasValue);
      _effectiveController = widget.controller ?? TextEditingController();
      _hasValue = _effectiveController.text.isNotEmpty;
      _effectiveController.addListener(_updateHasValue);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_updateHasValue);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _updateHasValue() {
    final newHasValue = _effectiveController.text.isNotEmpty;
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
      controller: _effectiveController,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLines: widget.expandHeight ? null : widget.maxLines,
      minLines: widget.expandHeight ? 1 : widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      style: widget.style ?? theme.textTheme.bodyLarge,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: (widget.style ?? theme.textTheme.bodyLarge)?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Configuración de bordes y colores usando los mismos estilos que InputTextField
        filled: true,
        fillColor: effectiveFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: 1.0,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: 1.0,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.0,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.0,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            width: 0,
          ),
        ),
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
    );
  }
}
