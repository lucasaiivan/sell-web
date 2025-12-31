import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/features/auth/domain/usecases/validate_username_usecase.dart';
import 'package:sellweb/features/auth/domain/usecases/check_username_availability_usecase.dart';

/// Widget: Campo de texto para username con validación en tiempo real
///
/// **Características**:
/// - Auto-conversión a minúsculas
/// - Validación de caracteres permitidos en tiempo real
/// - Validación de longitud (máximo 30)
/// - Validación de reglas del punto (.)
/// - Verificación de disponibilidad (debounced)
/// - Indicadores visuales de disponibilidad
/// - Mensajes de error claros en español
///
/// **Ejemplo de uso**:
/// ```dart
/// UsernameTextField(
///   controller: _usernameController,
///   onUsernameValidated: (isValid, username) {
///     setState(() => _isValid = isValid);
///   },
///   validateUseCase: ValidateUsernameUseCase(),
///   checkAvailabilityUseCase: CheckUsernameAvailabilityUseCase(repository),
/// )
/// ```
class UsernameTextField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(bool isValid, String? username)? onUsernameValidated;
  final ValidateUsernameUseCase? validateUseCase;
  final CheckUsernameAvailabilityUseCase? checkAvailabilityUseCase;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final bool autofocus;
  final bool enabled;

  const UsernameTextField({
    super.key,
    required this.controller,
    this.onUsernameValidated,
    this.validateUseCase,
    this.checkAvailabilityUseCase,
    this.focusNode,
    this.label,
    this.hint,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<UsernameTextField> createState() => _UsernameTextFieldState();
}

class _UsernameTextFieldState extends State<UsernameTextField> {
  final _validatedUseCase = ValidateUsernameUseCase();
  Timer? _debounce;
  String? _errorText;
  bool? _isAvailable;
  bool _isCheckingAvailability = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;

    // Validación inmediata de formato
    final validationUseCase = widget.validateUseCase ?? _validatedUseCase;
    final validationResult = validationUseCase.call(text);

    setState(() {
      _isAvailable = null;
      _errorText = validationResult.fold(
        (failure) => failure.message,
        (_) => null,
      );
    });

    // Si la validación de formato falló, no verificar disponibilidad
    if (validationResult.isLeft()) {
      widget.onUsernameValidated?.call(false, null);
      return;
    }

    final validatedUsername = validationResult.getOrElse((_) => '');

    // Debounce para verificar disponibilidad
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkAvailability(validatedUsername);
    });
  }

  Future<void> _checkAvailability(String username) async {
    if (widget.checkAvailabilityUseCase == null) {
      // Si no hay usecase, asumir que es válido
      widget.onUsernameValidated?.call(true, username);
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
    });

    final result = await widget.checkAvailabilityUseCase!.call(username);

    if (!mounted) return;

    setState(() {
      _isCheckingAvailability = false;
      result.fold(
        (failure) {
          _isAvailable = null;
          _errorText = failure.message;
        },
        (isAvailable) {
          _isAvailable = isAvailable;
          if (!isAvailable) {
            _errorText = 'El nombre de usuario ya está en uso';
          }
        },
      );
    });

    // Callback con resultado final
    final isValid = _errorText == null && (_isAvailable ?? false);
    widget.onUsernameValidated?.call(isValid, isValid ? username : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        // Solo permitir caracteres válidos
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
        // Convertir automáticamente a minúsculas
        LowercaseTextInputFormatter(),
        // Limitar a 30 caracteres
        LengthLimitingTextInputFormatter(30),
      ],
      decoration: InputDecoration(
        labelText: widget.label ?? 'Nombre de usuario',
        hintText: widget.hint ?? 'ej: mi_tienda',
        helperText: 'Máximo 30 caracteres. Solo a-z, 0-9, . y _',
        errorText: _errorText,
        prefixIcon: Icon(
          Icons.alternate_email_rounded,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: _buildSuffixIcon(theme),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (_isCheckingAvailability) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_isAvailable == null || _errorText != null) {
      return null;
    }

    if (_isAvailable == true) {
      return Icon(
        Icons.check_circle_rounded,
        color: theme.colorScheme.primary,
        size: 24,
      );
    }

    return Icon(
      Icons.cancel_rounded,
      color: theme.colorScheme.error,
      size: 24,
    );
  }
}

/// Formatter: Convierte texto a minúsculas automáticamente
class LowercaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
