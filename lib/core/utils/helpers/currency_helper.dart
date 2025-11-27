/// Helper: Formateo de moneda inteligente
///
/// **Responsabilidad:**
/// - Formatear valores monetarios de manera inteligente
/// - Mostrar números enteros cuando no hay centavos
/// - Mostrar decimales solo cuando hay residuos
///
/// **Formato:**
/// - 700 $ (sin centavos)
/// - 200,99 $ (con centavos)
class CurrencyHelper {
  /// Formatea un valor monetario de manera inteligente
  ///
  /// **Parámetros:**
  /// - `value`: Valor a formatear
  /// - `symbol`: Símbolo de moneda (por defecto '\$')
  ///
  /// **Retorna:** String formateado según tenga o no centavos
  static String formatCurrency(double value, {String symbol = '\$'}) {
    final absValue = value.abs();
    final hasDecimals = absValue != absValue.truncateToDouble();
    final isNegative = value < 0;
    
    if (hasDecimals) {
      // Tiene centavos: mostrar con 2 decimales
      final integerPart = absValue.truncate();
      final decimalPart = ((absValue - integerPart) * 100).round();
      final formatted = '${_formatInteger(integerPart)},${decimalPart.toString().padLeft(2, '0')} $symbol';
      return isNegative ? '-$formatted' : formatted;
    } else {
      // Sin centavos: mostrar solo el entero
      final formatted = '${_formatInteger(absValue.truncate())} $symbol';
      return isNegative ? '-$formatted' : formatted;
    }
  }

  /// Formatea un número entero con separadores de miles
  static String _formatInteger(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    
    return buffer.toString();
  }
}
