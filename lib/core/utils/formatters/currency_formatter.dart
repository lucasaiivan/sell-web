import 'package:intl/intl.dart';

/// Utilidades para formatear valores monetarios
class CurrencyFormatter {
  /// Obtiene un double y devuelve un monto formateado
  ///
  /// [moneda] - Símbolo de moneda (por defecto "$")
  /// [value] - Valor a formatear
  /// [simplified] - Si true, usa abreviaciones K y M para números grandes
  static String formatPrice({
    String moneda = "\$",
    required double value,
    bool simplified = false,
  }) {
    // cantidad de decimales
    int decimalDigits = (value % 1) == 0 ? 0 : 2;

    // formater : formato de moneda
    var formatter = NumberFormat.currency(
      locale: 'es_AR',
      name: moneda,
      customPattern:
          value >= 0 ? '\u00a4###,###,##0.0' : '-\u00a4###,###,##0.0',
      decimalDigits: decimalDigits,
    );

    if (simplified) {
      return _formatSimplified(value, formatter);
    }

    return formatter.format(value.abs());
  }

  /// Formatea un número entero con abreviaciones 'K' y 'M'
  ///
  /// Si el número es menor que 10,000, se devuelve como está.
  /// Si el número es 10,000 o más, pero menos que 1,000,000, se divide por 1,000 y se agrega 'K'.
  /// Si el número es 1,000,000 o más, se divide por 1,000,000 y se agrega 'M'.
  static String formatAmount({required int value}) {
    final formatCurrency = NumberFormat('#,##0');

    if (value < 10000) {
      return formatCurrency.format(value);
    } else if (value < 1000000) {
      return '${formatCurrency.format(value / 1000)}K';
    } else {
      return '${formatCurrency.format(value / 1000000)}M';
    }
  }

  /// Formatea valores grandes con abreviaciones
  static String _formatSimplified(double value, NumberFormat formatter) {
    if (value < 10000) {
      return formatter.format(value);
    } else if (value < 1000000) {
      return '${formatter.format(value / 1000)}K';
    } else {
      return '${formatter.format(value / 1000000)}M';
    }
  }
}
