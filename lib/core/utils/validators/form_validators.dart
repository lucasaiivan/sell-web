import '../../../core/constants/app_constants.dart';

/// Validadores para formularios y campos de entrada
class FormValidators {
  /// Valida un campo de email
  ///
  /// Retorna null si es válido, mensaje de error si no lo es
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El email es requerido';
    }

    if (!AppConstants.emailRegex.hasMatch(email)) {
      return 'Formato de email inválido';
    }

    if (email.length > 254) {
      return 'El email es demasiado largo';
    }

    return null;
  }

  /// Valida un campo de contraseña
  ///
  /// [password] La contraseña a validar
  /// [minLength] Longitud mínima (por defecto 6)
  /// [requireUppercase] Si requiere mayúsculas (por defecto false)
  /// [requireNumbers] Si requiere números (por defecto false)
  /// [requireSpecialChars] Si requiere caracteres especiales (por defecto false)
  static String? validatePassword(
    String? password, {
    int minLength = 6,
    bool requireUppercase = false,
    bool requireNumbers = false,
    bool requireSpecialChars = false,
  }) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (password.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(password)) {
      return 'La contraseña debe contener al menos una mayúscula';
    }

    if (requireNumbers && !RegExp(r'[0-9]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un número';
    }

    if (requireSpecialChars && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un carácter especial';
    }

    return null;
  }

  /// Valida que dos contraseñas coincidan
  static String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Confirme la contraseña';
    }

    if (password != confirmation) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida un número de teléfono
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'El teléfono es requerido';
    }

    // Remover espacios y caracteres especiales para validar
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (!AppConstants.phoneRegex.hasMatch(cleanPhone)) {
      return 'Formato de teléfono inválido';
    }

    return null;
  }

  /// Valida un campo requerido
  static String? validateRequired(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida longitud mínima de un campo
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Campo'}) {
    if (value == null || value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Valida longitud máxima de un campo
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'Campo'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }
    return null;
  }

  /// Valida que un campo contenga solo letras
  static String? validateOnlyLetters(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return '$fieldName solo puede contener letras';
    }
    return null;
  }

  /// Valida que un campo contenga solo números
  static String? validateOnlyNumbers(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '$fieldName solo puede contener números';
    }
    return null;
  }

  /// Valida que un valor esté dentro de un rango
  static String? validateRange(
    String? value,
    double min,
    double max, {
    String fieldName = 'Valor',
  }) {
    if (value == null || value.isEmpty) return null;

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return '$fieldName debe ser un número válido';
    }

    if (doubleValue < min || doubleValue > max) {
      return '$fieldName debe estar entre $min y $max';
    }

    return null;
  }

  /// Valida un campo de precio/moneda
  static String? validatePrice(String? value, {double? minValue, double? maxValue}) {
    if (value == null || value.isEmpty) {
      return 'El precio es requerido';
    }

    if (!AppConstants.priceRegex.hasMatch(value)) {
      return 'Formato de precio inválido';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Precio inválido';
    }

    if (price < 0) {
      return 'El precio no puede ser negativo';
    }

    if (minValue != null && price < minValue) {
      return 'El precio mínimo es \$${minValue.toStringAsFixed(2)}';
    }

    if (maxValue != null && price > maxValue) {
      return 'El precio máximo es \$${maxValue.toStringAsFixed(2)}';
    }

    return null;
  }

  /// Valida un campo de stock/cantidad
  static String? validateStock(String? value, {int? minValue, int? maxValue}) {
    if (value == null || value.isEmpty) {
      return 'El stock es requerido';
    }

    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Stock inválido';
    }

    if (stock < 0) {
      return 'El stock no puede ser negativo';
    }

    if (minValue != null && stock < minValue) {
      return 'El stock mínimo es $minValue';
    }

    if (maxValue != null && stock > maxValue) {
      return 'El stock máximo es $maxValue';
    }

    return null;
  }

  /// Valida una URL
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final urlRegex = RegExp(
      r'^https?://(?:[-\w.])+(?:\:[0-9]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:[\w.])*)?)?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(url)) {
      return 'URL inválida';
    }

    return null;
  }

  /// Combina múltiples validadores
  ///
  /// Ejecuta cada validador y retorna el primer error encontrado
  static String? combineValidators(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Valida una fecha en formato string
  static String? validateDate(String? dateString, {String format = 'dd/MM/yyyy'}) {
    if (dateString == null || dateString.isEmpty) {
      return 'La fecha es requerida';
    }

    try {
      // Aquí podrías usar DateFormatter.parseDate si lo necesitas
      // Por ahora, validación básica de formato dd/MM/yyyy
      final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
      if (!dateRegex.hasMatch(dateString)) {
        return 'Formato de fecha inválido (dd/MM/yyyy)';
      }

      final parts = dateString.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return 'Fecha inválida';
      }

      return null;
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}
