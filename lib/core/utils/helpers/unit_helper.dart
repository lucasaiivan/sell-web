import 'dart:math';
import 'package:intl/intl.dart';

/// Utilidades para manejo de unidades de venta y validaciones de cantidad
///
/// Este helper centraliza la lógica de:
/// - Tipos de unidades (discretas vs fraccionarias)
/// - Validaciones de cantidad según tipo
/// - Conversiones y formateo de cantidades
/// - Límites máximos según tipo de unidad
class UnitHelper {
  // Unidades discretas (solo números enteros)
  static const List<String> discreteUnits = [
    'unidad',
    'caja',
    'paquete',
    'docena',
  ];

  // Unidades fraccionarias (permiten decimales)
  static const List<String> fractionalUnits = [
    'kilogramo',
    'gramo',
    'litro',
    'mililitro',
    'metro',
    'centímetro',
    'milímetro',
  ];

  // Todas las unidades soportadas
  static const List<String> allUnits = [
    'unidad',
    'kilogramo',
    'gramo',
    'litro',
    'mililitro',
    'metro',
    'centímetro',
    'milímetro',
    'caja',
    'paquete',
    'docena',
  ];

  /// Cantidad mínima permitida para cualquier tipo de unidad
  static const double minQuantity = 0.001;

  /// Cantidad máxima para unidades discretas (unidad, caja, paquete, docena)
  static const double maxQuantityDiscrete = 9999999.0;

  /// Cantidad máxima para unidades fraccionarias (kg, L, m, etc.)
  static const double maxQuantityFractional = 9999999.0;

  /// Determina si una unidad es fraccionaria (permite decimales)
  static bool isFractionalUnit(String unit) {
    return fractionalUnits.contains(unit.toLowerCase());
  }

  /// Determina si una unidad es discreta (solo enteros)
  static bool isDiscreteUnit(String unit) {
    return discreteUnits.contains(unit.toLowerCase());
  }

  /// Obtiene la cantidad máxima permitida según el tipo de unidad
  static double getMaxQuantity(String unit) {
    return isFractionalUnit(unit) ? maxQuantityFractional : maxQuantityDiscrete;
  }

  /// Valida si una cantidad es válida para el tipo de unidad
  ///
  /// Retorna `null` si es válido, o un mensaje de error si no lo es.
  static String? validateQuantity(double quantity, String unit) {
    // Validar mínimo
    if (quantity < minQuantity) {
      return 'La cantidad mínima es $minQuantity';
    }

    // Validar máximo según tipo
    final maxQty = getMaxQuantity(unit);
    if (quantity > maxQty) {
      return 'La cantidad máxima para $unit es $maxQty';
    }

    // Validar que unidades discretas sean enteros
    if (isDiscreteUnit(unit) && quantity != quantity.roundToDouble()) {
      return 'La unidad "$unit" solo acepta cantidades enteras';
    }

    return null; // Válido
  }

  /// Normaliza una cantidad según el tipo de unidad
  ///
  /// Para unidades discretas: redondea al entero más cercano
  /// Para unidades fraccionarias: redondea a 3 decimales
  static double normalizeQuantity(double quantity, String unit) {
    if (isDiscreteUnit(unit)) {
      return quantity.roundToDouble();
    }

    // Para fraccionarias: redondear a 3 decimales (0.001)
    return (quantity * 1000).roundToDouble() / 1000;
  }

  static final NumberFormat _numberFormat = NumberFormat('#,##0.###', 'es_AR');
  static final NumberFormat _numberFormatWithZeros =
      NumberFormat('0.000', 'es_AR');

  /// Formatea una cantidad para mostrar en UI
  ///
  /// Ejemplos:
  /// - Discretas: 1.0 → "1", 5.0 → "5"
  /// - Fraccionarias: 0.025 → "0,025", 2.5 → "2,5", 1.0 → "1"
  static String formatQuantity(double quantity, String unit) {
    if (isDiscreteUnit(unit)) {
      return _numberFormat.format(quantity.toInt());
    }

    // Eliminar ceros innecesarios
    if (quantity == quantity.roundToDouble()) {
      return _numberFormat.format(quantity.toInt());
    }

    return _numberFormat.format(quantity);
  }

  /// Convierte cantidad a unidad más apropiada para visualización
  ///
  /// Ejemplos conversión a menor (si fracción < 1):
  /// - 0.5 kg → {value: 500, unit: 'g'}
  /// - 0.250 L → {value: 250, unit: 'ml'}
  ///
  /// Ejemplos conversión a mayor (si cantidad >= umbral):
  /// - 1000 g → {value: 1, unit: 'kg'}
  /// - 1500 ml → {value: 1.5, unit: 'L'}
  /// - 100 cm → {value: 1, unit: 'm'}
  static Map<String, dynamic> convertToDisplayUnit(
      double quantity, String unit) {
    final unitLower = unit.toLowerCase();

    // 1. Lógica para convertir de unidad mayor a menor (si es < 1)
    if (quantity < 1.0 && quantity > 0) {
      switch (unitLower) {
        case 'kilogramo':
          return {'value': quantity * 1000, 'unit': 'gramo'};
        case 'litro':
          return {'value': quantity * 1000, 'unit': 'mililitro'};
        case 'metro':
          if (quantity >= 0.01) {
            return {'value': quantity * 100, 'unit': 'centímetro'};
          } else {
            return {'value': quantity * 1000, 'unit': 'milímetro'};
          }
      }
    }

    // 2. Lógica para convertir de unidad menor a mayor (si es grande)
    switch (unitLower) {
      case 'gramo':
        if (quantity >= 1000) {
          return {'value': quantity / 1000, 'unit': 'kilogramo'};
        }
        break;
      case 'mililitro':
        if (quantity >= 1000) {
          return {'value': quantity / 1000, 'unit': 'litro'};
        }
        break;
      case 'centímetro':
        if (quantity >= 100) {
          return {'value': quantity / 100, 'unit': 'metro'};
        }
        break;
      case 'milímetro':
        if (quantity >= 1000) {
          return {'value': quantity / 1000, 'unit': 'metro'};
        }
        break;
    }

    // Default: devolver tal cual
    return {'value': quantity, 'unit': unitLower};
  }

  /// Formatea cantidad con ceros para mostrar decimales consistentemente
  ///
  /// Ejemplos:
  /// - 0.5 kg → "0,500"
  /// - 0.025 L → "0,025"
  /// - 1.5 kg → "1,500"
  /// - 2.25 kg → "2,250"
  static String formatQuantityWithZeros(double quantity, String unit) {
    if (isDiscreteUnit(unit)) {
      return _numberFormat.format(quantity.toInt());
    }

    // Para unidades fraccionarias, siempre usar formato con 3 decimales
    // si no es un número entero
    if (quantity != quantity.roundToDouble()) {
      return _numberFormatWithZeros.format(quantity);
    }

    // Para números enteros, mostrar sin decimales
    return _numberFormat.format(quantity.toInt());
  }

  /// Formatea cantidad incluyendo el símbolo de la unidad
  ///
  /// [simplified] : Si es true (default), elimina ceros no significativos.
  static String formatQuantityWithSymbol(double quantity, String unit,
      {bool simplified = true}) {
    if (simplified) {
      final formatted = _numberFormat.format(quantity);
      final symbol = getUnitSymbol(unit);
      return symbol.isEmpty ? formatted : '$formatted $symbol';
    }
    final formatted = formatQuantityWithZeros(quantity, unit);
    final symbol = getUnitSymbol(unit);
    if (symbol.isEmpty) return formatted;
    return '$formatted $symbol';
  }

  /// Formatea una cantidad de forma adaptativa (ej: 0.5kg -> 500g)
  /// con su símbolo correspondiente.
  ///
  /// [simplified] : Si es true (default), elimina ceros no significativos (1,500 -> 1,5).
  ///                Si es false, mantiene 3 decimales fijos (1,500 -> 1,500).
  static String formatQuantityAdaptive(double quantity, String unit,
      {bool simplified = true}) {
    final converted = convertToDisplayUnit(quantity, unit);
    final val = converted['value'] as double;
    final u = converted['unit'] as String;

    // Si es discreta, formatear siempre como entero
    if (isDiscreteUnit(u)) {
      final symbol = getUnitSymbol(u);
      final formatted = _numberFormat.format(val.toInt());
      return symbol.isEmpty ? formatted : '$formatted $symbol';
    }

    final symbol = getUnitSymbol(u);

    // Si es modo simplificado
    if (simplified) {
      // _numberFormat maneja automáticamente enteros y decimales sin ceros extra
      // ej: 1.0 -> "1", 1.500 -> "1,5", 1.523 -> "1,523"
      final formatted = _numberFormat.format(val);
      return symbol.isEmpty ? formatted : '$formatted $symbol';
    }

    // Modo completo (no simplificado)
    // Si es entero exacto, mostramos sin decimales (opcional, o podríamos forzar 1,000)
    // Asumimos que "completo" se refiere a ver decimales significativos completos cuando existen.
    // Pero si el usuario quiere ver "1,000 kg", quitamos el chequeo de entero.
    // Sin embargo, por convención, enteros suelen preferirse limpios salvo explicita precisión.
    // Mantendremos enteros limpios incluso en no-simplificado salvo que sea fracción.
    if (val == val.roundToDouble()) {
      final formatted = _numberFormat.format(val.toInt());
      return symbol.isEmpty ? formatted : '$formatted $symbol';
    }

    // Fracción con decimales fijos
    final formatted = _numberFormatWithZeros.format(val);
    return symbol.isEmpty ? formatted : '$formatted $symbol';
  }

  /// Obtiene el nombre capitalizado de una unidad para mostrar en UI
  static String getUnitDisplayName(String unit) {
    if (unit.isEmpty) return 'Unidad';
    return unit[0].toUpperCase() + unit.substring(1).toLowerCase();
  }

  /// Obtiene el símbolo abreviado de una unidad
  static String getUnitSymbol(String unit) {
    switch (unit.toLowerCase()) {
      case 'kilogramo':
        return 'kg';
      case 'gramo':
        return 'g';
      case 'litro':
        return 'L';
      case 'mililitro':
        return 'ml';
      case 'metro':
        return 'm';
      case 'centímetro':
        return 'cm';
      case 'milímetro':
        return 'mm';
      case 'unidad':
        return 'u';
      case 'caja':
        return 'caja';
      case 'paquete':
        return 'paq';
      case 'docena':
        return 'doc';
      default:
        return unit;
    }
  }

  /// Obtiene información de conversión para una unidad (para mostrar en UI)
  static String getUnitConversionInfo(String unit) {
    switch (unit.toLowerCase()) {
      case 'gramo':
        return '1000 gramos = 1 kilogramo';
      case 'kilogramo':
        return '1 kilogramo = 1000 gramos';
      case 'mililitro':
        return '1000 mililitros = 1 litro';
      case 'litro':
        return '1 litro = 1000 mililitros';
      case 'centímetro':
        return '100 centímetros = 1 metro';
      case 'milímetro':
        return '1000 milímetros = 1 metro';
      case 'metro':
        return '1 metro = 100 centímetros';
      case 'docena':
        return '1 docena = 12 unidades';
      default:
        return '';
    }
  }

  /// Obtiene el placeholder para el input de cantidad según tipo de unidad
  static String getQuantityPlaceholder(String unit) {
    if (isDiscreteUnit(unit)) {
      return 'Ej: 1, 2, 10';
    }
    return 'Ej: 0.5, 1.25, 2.5';
  }

  /// Obtiene el step (incremento) para botones +/- según tipo de unidad
  static double getQuantityStep(String unit) {
    if (isDiscreteUnit(unit)) {
      return 1.0;
    }

    // Para fraccionarias, incrementos según la unidad
    switch (unit.toLowerCase()) {
      case 'gramo':
      case 'mililitro':
      case 'centímetro':
      case 'milímetro':
        return 1.0; // Incrementos de 1 unidad
      case 'kilogramo':
      case 'litro':
      case 'metro':
        return 0.1; // Incrementos de 100g, 100ml, 10cm
      default:
        return 0.1;
    }
  }

  /// Parsea una cantidad desde string, compatible con int y double
  ///
  /// Maneja:
  /// - "1" → 1.0
  /// - "1,5" → 1.5 (formato local)
  /// - "1.5" → 1.5 (formato estándar)
  /// - null o inválido → valor por defecto
  static double parseQuantity(dynamic value, {double defaultValue = 1.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      if (value.isEmpty) return defaultValue;
      
      // Limpiar el string de caracteres no numéricos (excepto coma y punto)
      // Esto permite parsear strings que contengan símbolos de unidad o espacios
      final cleanValue = value.replaceAll(RegExp(r'[^0-9,\.]'), '');
      if (cleanValue.isEmpty) return defaultValue;

      try {
        return _numberFormat.parse(cleanValue).toDouble();
      } catch (_) {
        // Fallback para formato estándar (punto decimal)
        // Si tiene coma, reemplazar por punto para tryParse
        final normalized = cleanValue.replaceAll(',', '.');
        return double.tryParse(normalized) ?? defaultValue;
      }
    }

    return defaultValue;
  }

  /// Convierte una cantidad a formato de almacenamiento
  ///
  /// Siempre retorna double, pero compatible con deserialización desde int
  static double toStorageValue(dynamic value) {
    return parseQuantity(value, defaultValue: 1.0);
  }

  /// Redondea una cantidad de forma inteligente según decimales significativos
  ///
  /// Ejemplos con 3 decimales:
  /// - 0.025 → 0.025 (25 gramos)
  /// - 0.700 → 0.7 (700 gramos)
  /// - 2.270 → 2.27 (2.27 kg)
  /// - 1.000 → 1 (1 kg)
  static double roundSmartly(double value, {int decimals = 3}) {
    final multiplier = pow(10, decimals);
    final rounded = (value * multiplier).roundToDouble() / multiplier;
    return rounded;
  }
}
