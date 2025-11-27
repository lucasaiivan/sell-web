import 'package:intl/intl.dart';

/// Helper: Formateo de moneda inteligente optimizado
///
/// **Responsabilidad:**
/// - Formatear valores monetarios de manera inteligente
/// - Mostrar números enteros cuando no hay centavos
/// - Mostrar decimales solo cuando hay residuos
///
/// **Formato:**
/// - 700 $ (sin centavos)
/// - 200,99 $ (con centavos)
/// 
/// **Optimización:** 
/// - Usa [NumberFormat] nativo optimizado internamente
/// - Complejidad: O(log n) vs O(n) del algoritmo manual
/// - Lazy-initialized formatter para reutilización (singleton pattern)
class CurrencyHelper {
  // Formatter reutilizable (evita recrear en cada llamada)
  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'es_AR');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00', 'es_AR');

  /// Formatea un valor monetario de manera inteligente
  ///
  /// **Parámetros:**
  /// - `value`: Valor a formatear
  /// - `symbol`: Símbolo de moneda (por defecto '\$')
  ///
  /// **Retorna:** String formateado según tenga o no centavos
  /// 
  /// **Complejidad:** O(log n) donde n = cantidad de dígitos
  /// 
  /// **Ejemplos:**
  /// ```dart
  /// formatCurrency(1000.0)    // '1.000 $'
  /// formatCurrency(1000.50)   // '1.000,50 $'
  /// formatCurrency(-500.99)   // '-500,99 $'
  /// ```
  static String formatCurrency(double value, {String symbol = '\$'}) {
    final absValue = value.abs();
    final hasDecimals = absValue != absValue.truncateToDouble();
    
    String formatted;
    if (hasDecimals) {
      // Usar formatter con decimales
      formatted = _decimalFormatter.format(absValue);
    } else {
      // Usar formatter sin decimales
      formatted = _integerFormatter.format(absValue);
    }
    
    // Aplicar símbolo de moneda y signo negativo
    final result = '$formatted $symbol';
    return value < 0 ? '-$result' : result;
  }

  /// Formatea un valor sin símbolo de moneda (útil para inputs)
  /// 
  /// **Uso:** Internamente por controllers de TextField
  static String formatValue(double value) {
    final absValue = value.abs();
    final hasDecimals = absValue != absValue.truncateToDouble();
    
    final formatted = hasDecimals
        ? _decimalFormatter.format(absValue)
        : _integerFormatter.format(absValue);
    
    return value < 0 ? '-$formatted' : formatted;
  }
}
