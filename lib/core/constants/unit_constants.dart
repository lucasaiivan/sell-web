class UnitConstants {
  // English IDs (Database Keys)
  static const String unit = 'unit';
  static const String kilogram = 'kilogram';
  static const String liter = 'liter';
  static const String meter = 'meter';
  static const String box = 'box';
  static const String package = 'package';

  // List of all valid IDs
  static const List<String> validUnits = [
    unit,
    kilogram,
    liter,
    meter,
    box,
    package,
  ];

  // Fractional Units (allow refined quantity logic)
  static const List<String> fractionalUnits = [
    kilogram,
    liter,
    meter,
  ];

  // Discrete Units (only integers)
  static const List<String> discreteUnits = [
    unit,
    box,
    package,
  ];

  // Map to Spanish Names (Display)
  static const Map<String, String> localizedNames = {
    unit: 'Unidad',
    kilogram: 'Kilogramo',
    liter: 'Litro',
    meter: 'Metro',
    box: 'Caja',
    package: 'Paquete',
  };

  // Map to Symbols/Abbreviations
  static const Map<String, String> localizedSymbols = {
    unit: 'u',
    kilogram: 'kg',
    liter: 'L',
    meter: 'm',
    box: 'cja',
    package: 'paq',
  };

  // Legacy Mapping (Old Spanish ID -> New English ID)
  // Use this when parsing data from DB to ensure migration
  static const Map<String, String> legacyMapping = {
    'unidad': unit,
    'kilogramo': kilogram,
    'gramo': kilogram, // Merge gram into kilogram
    'litro': liter,
    'mililitro': liter, // Merge ml into liter
    'metro': meter,
    'centímetro': meter, // Merge cm into meter
    'caja': box,
    'paquete': package,
    'docena': unit, // Map dozen to unit or handle separately (simplification requested)
  };

  // Helper Methods

  /// Translates DB ID to Spanish Name
  static String getDisplayName(String id) {
    if (!validUnits.contains(id)) {
      // Try to find if it's a legacy ID
      if (legacyMapping.containsKey(id.toLowerCase())) {
        return localizedNames[legacyMapping[id.toLowerCase()]] ?? id;
      }
      return id;
    }
    return localizedNames[id] ?? id;
  }

  /// Gets the symbol for the ID
  static String getSymbol(String id) {
     if (!validUnits.contains(id)) {
      // Try to find if it's a legacy ID
      if (legacyMapping.containsKey(id.toLowerCase())) {
        return localizedSymbols[legacyMapping[id.toLowerCase()]] ?? '';
      }
      return '';
    }
    return localizedSymbols[id] ?? '';
  }

  /// Normalizes any input string to a valid English ID
  static String normalizeId(String input) {
    final lower = input.toLowerCase();
    if (validUnits.contains(lower)) return lower;
    if (legacyMapping.containsKey(lower)) return legacyMapping[lower]!;
    return unit; // Default fallback
  }
}
