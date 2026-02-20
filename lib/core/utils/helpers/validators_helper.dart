/// Helper: Validadores de entrada
///
/// **Responsabilidad:**
/// - Proveer validadores reutilizables para campos de formulario
/// - Validación de formato de email, teléfono, etc.
///
/// **Funciones:**
/// - isValidEmail(): Valida formato de dirección de email
/// - isValidPhone(): Valida formato de número telefónico
class ValidatorsHelper {
  ValidatorsHelper._();

  /// Expresión regular para validar formato de email
  /// Basada en RFC 5322 simplificada
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Valida si una cadena tiene formato de email válido
  ///
  /// **Parámetros:**
  /// - `email`: String a validar
  ///
  /// **Retorna:** true si el formato es válido, false en caso contrario
  ///
  /// **Ejemplos:**
  /// ```dart
  /// ValidatorsHelper.isValidEmail('user@example.com') // true
  /// ValidatorsHelper.isValidEmail('invalid.email') // false
  /// ValidatorsHelper.isValidEmail('user@') // false
  /// ```
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }
    return _emailRegex.hasMatch(email.trim());
  }

  /// Valida si una cadena tiene formato de teléfono válido
  /// Acepta formatos: +54 9 11 1234-5678, 1112345678, +541112345678
  ///
  /// **Parámetros:**
  /// - `phone`: String a validar
  ///
  /// **Retorna:** true si el formato es válido, false en caso contrario
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return false;
    }
    // Eliminar espacios, guiones y paréntesis
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Debe tener al menos 10 dígitos (puede empezar con +)
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Valida que una cadena no esté vacía
  ///
  /// **Parámetros:**
  /// - `value`: String a validar
  ///
  /// **Retorna:** true si no está vacía, false en caso contrario
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Valida que una cadena tenga una longitud mínima
  ///
  /// **Parámetros:**
  /// - `value`: String a validar
  /// - `minLength`: Longitud mínima requerida
  ///
  /// **Retorna:** true si cumple con la longitud mínima
  static bool hasMinLength(String? value, int minLength) {
    if (value == null) return false;
    return value.trim().length >= minLength;
  }

  /// Valida que una cadena tenga una longitud máxima
  ///
  /// **Parámetros:**
  /// - `value`: String a validar
  /// - `maxLength`: Longitud máxima permitida
  ///
  /// **Retorna:** true si cumple con la longitud máxima
  static bool hasMaxLength(String? value, int maxLength) {
    if (value == null) return true;
    return value.trim().length <= maxLength;
  }
}
