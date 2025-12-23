import 'dart:math';

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
    'caja',
    'paquete',
    'docena',
  ];

  /// Cantidad mínima permitida para cualquier tipo de unidad
  static const double minQuantity = 0.001;

  /// Cantidad máxima para unidades discretas (unidad, caja, paquete, docena)
  static const double maxQuantityDiscrete = 10000.0;

  /// Cantidad máxima para unidades fraccionarias (kg, L, m, etc.)
  static const double maxQuantityFractional = 1000.0;

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

  /// Formatea una cantidad para mostrar en UI
  /// 
  /// Ejemplos:
  /// - Discretas: 1.0 → "1", 5.0 → "5"
  /// - Fraccionarias: 0.025 → "0.025", 2.5 → "2.5", 1.0 → "1"
  static String formatQuantity(double quantity, String unit) {
    if (isDiscreteUnit(unit)) {
      return quantity.toInt().toString();
    }

    // Eliminar ceros innecesarios
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
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
        return 0.01; // Incrementos de 10g, 10ml, 1cm
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
  /// - "1.5" → 1.5
  /// - "0.025" → 0.025
  /// - null o inválido → valor por defecto
  static double parseQuantity(dynamic value, {double defaultValue = 1.0}) {
    if (value == null) return defaultValue;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
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
