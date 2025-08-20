import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin que proporciona funcionalidad de validación
/// para formularios y campos de entrada
mixin ValidationMixin<T extends StatefulWidget> on State<T> {
  
  // ==========================================
  // PROPIEDADES PRIVADAS
  // ==========================================
  
  final Map<String, String?> _fieldErrors = {};
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, List<ValidationRule>> _fieldRules = {};
  bool _showValidationErrors = false;
  
  // ==========================================
  // GETTERS PÚBLICOS
  // ==========================================
  
  /// Indica si hay errores de validación
  bool get hasValidationErrors => _fieldErrors.values.any((error) => error != null);
  
  /// Indica si el formulario es válido
  bool get isFormValid => !hasValidationErrors;
  
  /// Obtiene todos los errores actuales
  Map<String, String?> get allErrors => Map.unmodifiable(_fieldErrors);
  
  /// Obtiene todos los valores actuales
  Map<String, dynamic> get allValues => Map.unmodifiable(_fieldValues);
  
  /// Indica si se deben mostrar los errores de validación
  bool get showValidationErrors => _showValidationErrors;
  
  // ==========================================
  // MÉTODOS DE CONFIGURACIÓN
  // ==========================================
  
  /// Registra las reglas de validación para un campo
  void setFieldRules(String fieldKey, List<ValidationRule> rules) {
    _fieldRules[fieldKey] = rules;
  }
  
  /// Registra múltiples campos con sus reglas
  void setFormRules(Map<String, List<ValidationRule>> rulesMap) {
    _fieldRules.addAll(rulesMap);
  }
  
  /// Configura si se deben mostrar errores automáticamente
  void setShowValidationErrors(bool show) {
    if (mounted) {
      setState(() {
        _showValidationErrors = show;
      });
    }
  }
  
  // ==========================================
  // MÉTODOS DE VALIDACIÓN
  // ==========================================
  
  /// Valida un campo específico
  String? validateField(String fieldKey, dynamic value) {
    final rules = _fieldRules[fieldKey] ?? [];
    
    for (final rule in rules) {
      final error = rule.validate(value);
      if (error != null) {
        return error;
      }
    }
    
    return null;
  }
  
  /// Valida todos los campos registrados
  bool validateAllFields() {
    bool isValid = true;
    
    for (final fieldKey in _fieldRules.keys) {
      final value = _fieldValues[fieldKey];
      final error = validateField(fieldKey, value);
      
      if (mounted) {
        setState(() {
          _fieldErrors[fieldKey] = error;
        });
      }
      
      if (error != null) {
        isValid = false;
      }
    }
    
    return isValid;
  }
  
  /// Actualiza el valor de un campo y lo valida
  void updateFieldValue(String fieldKey, dynamic value, {bool validateImmediately = true}) {
    if (mounted) {
      setState(() {
        _fieldValues[fieldKey] = value;
        
        if (validateImmediately) {
          _fieldErrors[fieldKey] = validateField(fieldKey, value);
        }
      });
    }
  }
  
  /// Limpia el error de un campo específico
  void clearFieldError(String fieldKey) {
    if (mounted) {
      setState(() {
        _fieldErrors[fieldKey] = null;
      });
    }
  }
  
  /// Limpia todos los errores
  void clearAllErrors() {
    if (mounted) {
      setState(() {
        _fieldErrors.clear();
      });
    }
  }
  
  /// Establece un error personalizado para un campo
  void setFieldError(String fieldKey, String error) {
    if (mounted) {
      setState(() {
        _fieldErrors[fieldKey] = error;
      });
    }
  }
  
  // ==========================================
  // MÉTODOS DE CONSULTA
  // ==========================================
  
  /// Obtiene el error de un campo específico
  String? getFieldError(String fieldKey) {
    if (!_showValidationErrors) return null;
    return _fieldErrors[fieldKey];
  }
  
  /// Obtiene el valor de un campo específico
  T? getFieldValue<T>(String fieldKey) {
    final value = _fieldValues[fieldKey];
    return value is T ? value : null;
  }
  
  /// Verifica si un campo tiene error
  bool hasFieldError(String fieldKey) {
    return _fieldErrors[fieldKey] != null;
  }
  
  /// Verifica si un campo está registrado
  bool isFieldRegistered(String fieldKey) {
    return _fieldRules.containsKey(fieldKey);
  }
  
  // ==========================================
  // MÉTODOS DE RESET Y LIMPIEZA
  // ==========================================
  
  /// Resetea un campo específico
  void resetField(String fieldKey) {
    if (mounted) {
      setState(() {
        _fieldValues.remove(fieldKey);
        _fieldErrors.remove(fieldKey);
      });
    }
  }
  
  /// Resetea todos los campos
  void resetAllFields() {
    if (mounted) {
      setState(() {
        _fieldValues.clear();
        _fieldErrors.clear();
        _showValidationErrors = false;
      });
    }
  }
  
  /// Resetea solo los valores manteniendo las reglas
  void resetValues() {
    if (mounted) {
      setState(() {
        _fieldValues.clear();
        _fieldErrors.clear();
      });
    }
  }
  
  // ==========================================
  // MÉTODOS DE UTILIDAD PARA WIDGETS
  // ==========================================
  
  /// Obtiene la decoración para un TextField
  InputDecoration getFieldDecoration(
    String fieldKey, {
    String? labelText,
    String? hintText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool showErrorText = true,
  }) {
    final error = showErrorText ? getFieldError(fieldKey) : null;
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: error,
      errorStyle: error != null
          ? TextStyle(color: Theme.of(context).colorScheme.error)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
    );
  }
  
  /// Widget que muestra un resumen de errores
  Widget buildErrorSummary({
    String title = 'Errores de validación:',
    bool showOnlyIfErrors = true,
  }) {
    final errors = _fieldErrors.values.where((error) => error != null).toList();
    
    if (showOnlyIfErrors && errors.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  // ==========================================
  // MÉTODOS DE VALIDACIÓN AVANZADA
  // ==========================================
  
  /// Valida el formulario y muestra errores si es necesario
  Future<bool> validateFormWithFeedback({
    bool showSnackBarOnError = true,
    String? errorMessage,
  }) async {
    setShowValidationErrors(true);
    final isValid = validateAllFields();
    
    if (!isValid && showSnackBarOnError && mounted) {
      final message = errorMessage ?? 'Por favor corrige los errores en el formulario';
      _showErrorSnackBar(message);
    }
    
    return isValid;
  }
  
  /// Ejecuta una acción solo si el formulario es válido
  Future<R?> executeIfValid<R>(
    Future<R> Function() action, {
    String? validationErrorMessage,
    bool showValidationErrors = true,
  }) async {
    if (showValidationErrors) {
      setShowValidationErrors(true);
    }
    
    final isValid = validateAllFields();
    
    if (!isValid) {
      if (validationErrorMessage != null && mounted) {
        _showErrorSnackBar(validationErrorMessage);
      }
      return null;
    }
    
    return await action();
  }
  
  /// Valida y ejecuta con loading automático
  Future<R?> validateAndExecute<R>(
    Future<R> Function() action, {
    String? validationErrorMessage,
    String? loadingMessage,
  }) async {
    setShowValidationErrors(true);
    final isValid = validateAllFields();
    
    if (!isValid) {
      if (validationErrorMessage != null && mounted) {
        _showErrorSnackBar(validationErrorMessage);
      }
      return null;
    }
    
    // Ejecutar directamente sin loading automático
    // El widget puede usar LoadingMixin por separado si lo necesita
    return await action();
  }
  
  // ==========================================
  // MÉTODOS HELPER PRIVADOS
  // ==========================================
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ==========================================
  // LIFECYCLE OVERRIDES
  // ==========================================
  
  @override
  void dispose() {
    _fieldErrors.clear();
    _fieldValues.clear();
    _fieldRules.clear();
    super.dispose();
  }
}

/// Clase base para reglas de validación
abstract class ValidationRule {
  const ValidationRule();
  
  /// Valida un valor y retorna un mensaje de error o null si es válido
  String? validate(dynamic value);
}

/// Regla que verifica que el campo no esté vacío
class RequiredRule extends ValidationRule {
  final String message;
  
  const RequiredRule({this.message = 'Este campo es requerido'});
  
  @override
  String? validate(dynamic value) {
    if (value == null || 
        (value is String && value.trim().isEmpty) ||
        (value is List && value.isEmpty)) {
      return message;
    }
    return null;
  }
}

/// Regla que verifica la longitud mínima
class MinLengthRule extends ValidationRule {
  final int minLength;
  final String message;
  
  const MinLengthRule(this.minLength, {String? message}) 
      : message = message ?? 'Debe tener al menos $minLength caracteres';
  
  @override
  String? validate(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.length < minLength) {
      return message;
    }
    return null;
  }
}

/// Regla que verifica la longitud máxima
class MaxLengthRule extends ValidationRule {
  final int maxLength;
  final String message;
  
  const MaxLengthRule(this.maxLength, {String? message}) 
      : message = message ?? 'No debe exceder $maxLength caracteres';
  
  @override
  String? validate(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.length > maxLength) {
      return message;
    }
    return null;
  }
}

/// Regla que verifica formato de email
class EmailRule extends ValidationRule {
  final String message;
  
  const EmailRule({this.message = 'Ingresa un email válido'});
  
  @override
  String? validate(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.isEmpty) return null; // Permite vacío, usar RequiredRule para requerir
    
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(str)) {
      return message;
    }
    return null;
  }
}

/// Regla que verifica formato de número
class NumericRule extends ValidationRule {
  final String message;
  final bool allowDecimals;
  
  const NumericRule({
    this.message = 'Debe ser un número válido',
    this.allowDecimals = true,
  });
  
  @override
  String? validate(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.isEmpty) return null;
    
    if (allowDecimals) {
      if (double.tryParse(str) == null) {
        return message;
      }
    } else {
      if (int.tryParse(str) == null) {
        return message;
      }
    }
    return null;
  }
}

/// Regla que verifica un rango numérico
class RangeRule extends ValidationRule {
  final num min;
  final num max;
  final String message;
  
  const RangeRule(this.min, this.max, {String? message}) 
      : message = message ?? 'Debe estar entre $min y $max';
  
  @override
  String? validate(dynamic value) {
    final num? number = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (number == null) return null; // Permite no numérico, usar NumericRule para validar
    
    if (number < min || number > max) {
      return message;
    }
    return null;
  }
}

/// Regla personalizada con función
class CustomRule extends ValidationRule {
  final String? Function(dynamic value) validator;
  
  const CustomRule(this.validator);
  
  @override
  String? validate(dynamic value) {
    return validator(value);
  }
}

/// Regla que compara con otro campo
class MatchFieldRule extends ValidationRule {
  final String fieldKey;
  final Map<String, dynamic> fieldValues;
  final String message;
  
  const MatchFieldRule(this.fieldKey, this.fieldValues, {String? message}) 
      : message = message ?? 'Los campos no coinciden';
  
  @override
  String? validate(dynamic value) {
    final otherValue = fieldValues[fieldKey];
    if (value != otherValue) {
      return message;
    }
    return null;
  }
}

/// Regla que verifica patrones con expresiones regulares
class PatternRule extends ValidationRule {
  final String pattern;
  final String message;
  
  const PatternRule(this.pattern, {required this.message});
  
  @override
  String? validate(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.isEmpty) return null;
    
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(str)) {
      return message;
    }
    return null;
  }
}

/// Mixin especializado para validación en tiempo real
mixin RealTimeValidationMixin<T extends StatefulWidget> on State<T> {
  
  Timer? _validationTimer;
  final Duration _validationDelay = const Duration(milliseconds: 500);
  
  /// Valida un campo con debounce
  void validateFieldWithDelay(String fieldKey, dynamic value) {
    _validationTimer?.cancel();
    _validationTimer = Timer(_validationDelay, () {
      if (this is ValidationMixin) {
        final validationMixin = this as ValidationMixin;
        validationMixin.updateFieldValue(fieldKey, value, validateImmediately: true);
      }
    });
  }
  
  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }
}
