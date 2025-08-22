import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';

/// Utilidades para formateo de valores monetarios
class CurrencyFormatter {
  static NumberFormat? _currencyFormatter;

  /// Formateador de moneda estándar (lazy initialization)
  static NumberFormat get _standardFormatter {
    return _currencyFormatter ??= NumberFormat.currency(
      locale: AppConstants.defaultLocale,
      symbol: AppConstants.defaultCurrency,
      decimalDigits: AppConstants.defaultDecimalPlaces,
    );
  }


  /// Formatea un valor monetario según la configuración regional.
  ///
  /// [value] El valor numérico a formatear
  /// [symbol] El símbolo de moneda (por defecto '\$')
  /// [simplified] Si debe usar notación abreviada (K, M)
  ///
  /// Retorna el valor formateado como String.
  ///
  /// Ejemplo:
  /// ```dart
  /// formatCurrency(1234.56) // "\$1,234.56"
  /// formatCurrency(15000, simplified: true) // "\$15K"
  /// ```
  static String formatCurrency({
    required double value,
    String? symbol,
    bool simplified = false,
  }) {
    final currencySymbol = symbol ?? AppConstants.defaultCurrency;

    // Determinar cantidad de decimales basado en si el valor es entero
    int decimalDigits =
        (value % 1) == 0 ? 0 : AppConstants.defaultDecimalPlaces;

    if (simplified) {
      return _formatSimplifiedCurrency(value, currencySymbol);
    }

    // Crear formateador personalizado si se necesita símbolo específico
    if (symbol != null && symbol != AppConstants.defaultCurrency) {
      final customFormatter = NumberFormat.currency(
        locale: AppConstants.defaultLocale,
        symbol: currencySymbol,
        decimalDigits: decimalDigits,
      );
      return customFormatter.format(value);
    }

    // Usar formateador estándar
    return _standardFormatter.format(value);
  }

  /// Formatea un número entero a una cadena con abreviaturas 'K' y 'M'.
  ///
  /// Si el número es menor que 10,000, se devuelve como está.
  /// Si el número es 10,000 o más, pero menos que 1,000,000, se divide por 1,000 y se agrega 'K'.
  /// Si el número es 1,000,000 o más, se divide por 1,000,000 y se agrega 'M'.
  static String _formatSimplifiedCurrency(double value, String symbol) {
    if (value < 10000) {
      // Para números menores a 10K, formato estándar
      return formatCurrency(value: value, symbol: symbol, simplified: false);
    } else if (value < 1000000) {
      // Para números entre 10K y 1M, usar 'K'
      double simplified = value / 1000;
      String formattedValue = simplified.toStringAsFixed(
        simplified % 1 == 0 ? 0 : 1,
      );
      return '$symbol${formattedValue}K';
    } else {
      // Para números 1M o más, usar 'M'
      double simplified = value / 1000000;
      String formattedValue = simplified.toStringAsFixed(
        simplified % 1 == 0 ? 0 : 1,
      );
      return '$symbol${formattedValue}M';
    }
  }

  /// Formatea un porcentaje con el símbolo %
  ///
  /// [value] Valor entre 0 y 1 (ej: 0.15 para 15%)
  /// [decimalPlaces] Cantidad de decimales a mostrar
  ///
  /// Ejemplo:
  /// ```dart
  /// formatPercentage(0.15) // "15%"
  /// formatPercentage(0.1234, decimalPlaces: 2) // "12.34%"
  /// ```
  static String formatPercentage(double value, {int decimalPlaces = 0}) {
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimalPlaces)}%';
  }

  /// Convierte un string formateado de vuelta a double
  ///
  /// [formattedValue] String con formato de moneda (ej: "\$1,234.56")
  ///
  /// Retorna el valor numérico o null si no es válido
  static double? parseCurrency(String formattedValue) {
    try {
      // Remover símbolos de moneda y separadores
      String cleaned =
          formattedValue.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '');

      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Valida si un string representa un valor monetario válido
  static bool isValidCurrency(String value) {
    return AppConstants.priceRegex.hasMatch(value);
  }

  /// Formatea un valor para input de usuario (sin símbolo de moneda)
  ///
  /// Útil para campos de entrada donde el usuario ingresa solo números
  static String formatForInput(double value) {
    int decimalDigits =
        (value % 1) == 0 ? 0 : AppConstants.defaultDecimalPlaces;
    return value.toStringAsFixed(decimalDigits);
  }

  /// Resetea los formatters (útil para tests o cambios de configuración)
  static void reset() {
    _currencyFormatter = null;
  }
}
