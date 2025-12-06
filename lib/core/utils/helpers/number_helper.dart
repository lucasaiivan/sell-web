import 'package:intl/intl.dart';

/// Helper: Formateo de números enteros con separador de miles
///
/// **Responsabilidad:**
/// - Formatear números enteros con punto de miles
/// - Optimizado para números de transacciones, cantidades, etc.
///
/// **Formato:**
/// - 1000 → 1.000
/// - 5000000 → 5.000.000
/// - 42 → 42
class NumberHelper {
  // Formatter reutilizable (singleton pattern)
  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'es_AR');

  /// Formatea un número entero con separador de miles
  ///
  /// **Parámetros:**
  /// - `value`: Valor entero a formatear
  ///
  /// **Retorna:** String formateado con punto de miles
  ///
  /// **Ejemplos:**
  /// ```dart
  /// formatNumber(1000)    // '1.000'
  /// formatNumber(5000000) // '5.000.000'
  /// formatNumber(42)      // '42'
  /// ```
  static String formatNumber(int value) {
    return _integerFormatter.format(value);
  }
}
