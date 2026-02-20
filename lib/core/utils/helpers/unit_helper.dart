import 'dart:math';
import 'package:intl/intl.dart';
import 'package:sellweb/core/constants/unit_constants.dart';

/// Utilidades para manejo de unidades de venta y validaciones de cantidad
///
/// Este helper centraliza la lógica de:
/// - Tipos de unidades (discretas vs fraccionarias)
/// - Validaciones de cantidad según tipo
/// - Conversiones y formateo de cantidades
/// - Límites máximos según tipo de unidad
class UnitHelper {
  // Unidades discretas (solo números enteros)
  static List<String> get discreteUnits => UnitConstants.discreteUnits;

  // Unidades fraccionarias (permiten decimales)
  static List<String> get fractionalUnits => UnitConstants.fractionalUnits;

  // Todas las unidades soportadas
  static List<String> get allUnits => UnitConstants.validUnits;

  /// Cantidad mínima permitida para cualquier tipo de unidad
  static const double minQuantity = 0.001;

  /// Cantidad máxima para unidades discretas (unidad, caja, paquete, docena)
  static const double maxQuantityDiscrete = 9999999.0;

  /// Cantidad máxima para unidades fraccionarias (kg, L, m, etc.)
  static const double maxQuantityFractional = 9999999.0;

  /// Determina si una unidad es fraccionaria (permite decimales)
  static bool isFractionalUnit(String unit) {
    return UnitConstants.fractionalUnits.contains(UnitConstants.normalizeId(unit));
  }

  /// Determina si una unidad es discreta (solo enteros)
  static bool isDiscreteUnit(String unit) {
    return UnitConstants.discreteUnits.contains(UnitConstants.normalizeId(unit));
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
      return 'La unidad "${getUnitDisplayName(unit)}" solo acepta cantidades enteras';
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
  /// - 0.5 kg → {value: 500, unit: 'gram'}
  /// - 0.250 L → {value: 250, unit: 'milliliter'}
  static Map<String, dynamic> convertToDisplayUnit(
      double quantity, String unit) {
    final unitId = UnitConstants.normalizeId(unit);

    // 1. Lógica para convertir de unidad mayor a menor (si es < 1)
    if (quantity < 1.0 && quantity > 0) {
      switch (unitId) {
        case UnitConstants.kilogram:
          return {'value': quantity * 1000, 'unit': 'gram'};
        case UnitConstants.liter:
          return {'value': quantity * 1000, 'unit': 'milliliter'};
        case UnitConstants.meter:
          if (quantity >= 0.01) {
            return {'value': quantity * 100, 'unit': 'centimeter'};
          } else {
            return {'value': quantity * 1000, 'unit': 'millimeter'};
          }
      }
    }

    // 2. Lógica para convertir de unidad menor a mayor (si es grande)
    // Note: Since we are standardizing on base units (kg, L, m), input units
    // will usually be the base units. But if we receive 'gram' here for some reason:
    
    // We treat 'gram' as a pseudo-unit used in display logic, but the input 'unit' to this function
    // is expected to be a valid ID from UnitConstants usually.
    // If the input is ALREADY a sub-unit (legacy), we handle it.
    
    // For now, assume inputs are standard IDs. 
    
    return {'value': quantity, 'unit': unitId};
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
      final formatted = _numberFormat.format(val);
      return symbol.isEmpty ? formatted : '$formatted $symbol';
    }

    // Modo completo (no simplificado)
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
    // Check for display sub-units
    switch (unit.toLowerCase()) {
      case 'gram': return 'Gramo';
      case 'milliliter': return 'Mililitro';
      case 'centimeter': return 'Centímetro';
      case 'millimeter': return 'Milímetro';
    }
    return UnitConstants.getDisplayName(unit);
  }

  /// Obtiene el símbolo abreviado de una unidad
  static String getUnitSymbol(String unit) {
    // Check for display sub-units
    switch (unit.toLowerCase()) {
      case 'gram': return 'g';
      case 'milliliter': return 'ml';
      case 'centimeter': return 'cm';
      case 'millimeter': return 'mm';
    }
    return UnitConstants.getSymbol(unit);
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

    // Para fraccionarias, incrementos de 0.1 (100g, 100ml)
    return 0.1;
  }

  /// Parsea una cantidad desde string, compatible con int y double
  static double parseQuantity(dynamic value, {double defaultValue = 1.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      if (value.isEmpty) return defaultValue;
      
      final cleanValue = value.replaceAll(RegExp(r'[^0-9,\.]'), '');
      if (cleanValue.isEmpty) return defaultValue;

      try {
        return _numberFormat.parse(cleanValue).toDouble();
      } catch (_) {
        final normalized = cleanValue.replaceAll(',', '.');
        return double.tryParse(normalized) ?? defaultValue;
      }
    }

    return defaultValue;
  }

  /// Convierte una cantidad a formato de almacenamiento
  static double toStorageValue(dynamic value) {
    return parseQuantity(value, defaultValue: 1.0);
  }

  /// Redondea una cantidad de forma inteligente según decimales significativos
  static double roundSmartly(double value, {int decimals = 3}) {
    final multiplier = pow(10, decimals);
    final rounded = (value * multiplier).roundToDouble() / multiplier;
    return rounded;
  }
}
