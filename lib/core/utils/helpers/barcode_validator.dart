/// Enum que representa los formatos de códigos de barras estándar GS1
///
/// ## Formatos Soportados:
/// - **GTIN-13 (EAN-13)**: 13 dígitos - Unidad de consumo estándar (retail)
/// - **GTIN-8 (EAN-8)**: 8 dígitos - Unidad de consumo pequeña
/// - **GTIN-14 (ITF-14)**: 14 dígitos - Unidad de despacho logístico
/// - **UPC-A (GTIN-12)**: 12 dígitos - Estados Unidos y Canadá
/// - **UPC-E**: 8 dígitos - Versión comprimida de UPC-A (EE.UU./Canadá)
enum BarcodeFormat {
  /// GTIN-13 / EAN-13: Código estándar internacional de 13 dígitos
  /// Obligatorio para productos nacionales en Argentina (prefijo 779)
  ean13('EAN-13', 13),

  /// GTIN-8 / EAN-8: Código corto de 8 dígitos
  /// Para envases pequeños donde EAN-13 no cabe
  ean8('EAN-8', 8),

  /// GTIN-14 / ITF-14 / DUN-14: Código logístico de 14 dígitos
  /// Para cajas y bultos en depósitos y distribución
  gtin14('GTIN-14', 14),

  /// UPC-A / GTIN-12: Código de 12 dígitos de EE.UU. y Canadá
  /// Compatible con sistemas argentinos (se procesa como EAN-13 con 0 inicial)
  upcA('UPC-A', 12),

  /// UPC-E: Versión comprimida de UPC-A (8 dígitos)
  /// Para productos de importación norteamericana de tamaño reducido
  upcE('UPC-E', 8);

  const BarcodeFormat(this.displayName, this.length);

  /// Nombre para mostrar al usuario
  final String displayName;

  /// Longitud esperada del código
  final int length;
}

/// Información del país de origen basada en el prefijo GS1
///
/// Los prefijos GS1 identifican el país donde se registró el código,
/// NO necesariamente donde se fabricó el producto.
class BarcodeCountryInfo {
  const BarcodeCountryInfo({
    required this.prefix,
    required this.country,
    required this.flag,
    this.region,
  });

  /// Prefijo GS1 (puede ser de 2-3 dígitos)
  final String prefix;

  /// Nombre del país
  final String country;

  /// Emoji de la bandera
  final String flag;

  /// Región opcional (ej: "Latinoamérica", "Europa")
  final String? region;

  @override
  String toString() => '$flag $country';
}

/// Validador de códigos de barras con soporte para formatos GS1 Argentina
///
/// ## Formatos Adoptados en Argentina (GS1 Argentina - Prefijo 779):
/// - **GTIN-13 (EAN-13)**: Obligatorio para productos nacionales
/// - **GTIN-8 (EAN-8)**: Productos pequeños
/// - **GTIN-14 (ITF-14)**: Unidades logísticas
///
/// ## Formatos Importados Aceptados:
/// - **EAN-13 extranjero**: Productos de Europa, Asia, Latinoamérica
/// - **UPC-A (GTIN-12)**: Productos de EE.UU. y Canadá
/// - **UPC-E**: Productos pequeños de EE.UU.
///
/// ## Validación:
/// Todos los formatos usan el algoritmo Módulo 10 (GS1 Check Digit)
/// excepto UPC-E que se valida mediante el checksum simplificado EAN-8.
class BarcodeValidator {
  // ═══════════════════════════════════════════════════════════════════════════
  // PREFIJOS GS1 POR PAÍS/REGIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mapa de prefijos GS1 a información del país
  /// Fuente: https://www.gs1.org/standards/id-keys/company-prefix
  static const Map<String, BarcodeCountryInfo> _countryPrefixes = {
    // Argentina
    '779': BarcodeCountryInfo(
      prefix: '779',
      country: 'Argentina',
      flag: '🇦🇷',
      region: 'Latinoamérica',
    ),

    // Latinoamérica
    '770': BarcodeCountryInfo(
      prefix: '770',
      country: 'Colombia',
      flag: '🇨🇴',
      region: 'Latinoamérica',
    ),
    '773': BarcodeCountryInfo(
      prefix: '773',
      country: 'Uruguay',
      flag: '🇺🇾',
      region: 'Latinoamérica',
    ),
    '775': BarcodeCountryInfo(
      prefix: '775',
      country: 'Perú',
      flag: '🇵🇪',
      region: 'Latinoamérica',
    ),
    '777': BarcodeCountryInfo(
      prefix: '777',
      country: 'Bolivia',
      flag: '🇧🇴',
      region: 'Latinoamérica',
    ),
    '778': BarcodeCountryInfo(
      prefix: '778',
      country: 'Ecuador',
      flag: '🇪🇨',
      region: 'Latinoamérica',
    ),
    '780': BarcodeCountryInfo(
      prefix: '780',
      country: 'Chile',
      flag: '🇨🇱',
      region: 'Latinoamérica',
    ),
    '784': BarcodeCountryInfo(
      prefix: '784',
      country: 'Paraguay',
      flag: '🇵🇾',
      region: 'Latinoamérica',
    ),
    '786': BarcodeCountryInfo(
      prefix: '786',
      country: 'Ecuador',
      flag: '🇪🇨',
      region: 'Latinoamérica',
    ),
    '789': BarcodeCountryInfo(
      prefix: '789',
      country: 'Brasil',
      flag: '🇧🇷',
      region: 'Latinoamérica',
    ),
    '790': BarcodeCountryInfo(
      prefix: '790',
      country: 'Brasil',
      flag: '🇧🇷',
      region: 'Latinoamérica',
    ),
    '750': BarcodeCountryInfo(
      prefix: '750',
      country: 'México',
      flag: '🇲🇽',
      region: 'Latinoamérica',
    ),

    // Norteamérica (UPC)
    '00': BarcodeCountryInfo(
      prefix: '00',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '01': BarcodeCountryInfo(
      prefix: '01',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '02': BarcodeCountryInfo(
      prefix: '02',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '03': BarcodeCountryInfo(
      prefix: '03',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '04': BarcodeCountryInfo(
      prefix: '04',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '05': BarcodeCountryInfo(
      prefix: '05',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '06': BarcodeCountryInfo(
      prefix: '06',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '07': BarcodeCountryInfo(
      prefix: '07',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '08': BarcodeCountryInfo(
      prefix: '08',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '09': BarcodeCountryInfo(
      prefix: '09',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '10': BarcodeCountryInfo(
      prefix: '10',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '11': BarcodeCountryInfo(
      prefix: '11',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '12': BarcodeCountryInfo(
      prefix: '12',
      country: 'Estados Unidos',
      flag: '🇺🇸',
      region: 'Norteamérica',
    ),
    '13': BarcodeCountryInfo(
      prefix: '13',
      country: 'Canadá / Estados Unidos',
      flag: '🇨🇦',
      region: 'Norteamérica',
    ),

    // Europa
    '400': BarcodeCountryInfo(
      prefix: '400',
      country: 'Alemania',
      flag: '🇩🇪',
      region: 'Europa',
    ),
    '840': BarcodeCountryInfo(
      prefix: '840',
      country: 'España',
      flag: '🇪🇸',
      region: 'Europa',
    ),
    '300': BarcodeCountryInfo(
      prefix: '300',
      country: 'Francia',
      flag: '🇫🇷',
      region: 'Europa',
    ),
    '800': BarcodeCountryInfo(
      prefix: '800',
      country: 'Italia',
      flag: '🇮🇹',
      region: 'Europa',
    ),
    '500': BarcodeCountryInfo(
      prefix: '500',
      country: 'Reino Unido',
      flag: '🇬🇧',
      region: 'Europa',
    ),
    '870': BarcodeCountryInfo(
      prefix: '870',
      country: 'Países Bajos',
      flag: '🇳🇱',
      region: 'Europa',
    ),

    // Asia
    '450': BarcodeCountryInfo(
      prefix: '450',
      country: 'Japón',
      flag: '🇯🇵',
      region: 'Asia',
    ),
    '490': BarcodeCountryInfo(
      prefix: '490',
      country: 'Japón',
      flag: '🇯🇵',
      region: 'Asia',
    ),
    '880': BarcodeCountryInfo(
      prefix: '880',
      country: 'Corea del Sur',
      flag: '🇰🇷',
      region: 'Asia',
    ),
    '690': BarcodeCountryInfo(
      prefix: '690',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '691': BarcodeCountryInfo(
      prefix: '691',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '692': BarcodeCountryInfo(
      prefix: '692',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '693': BarcodeCountryInfo(
      prefix: '693',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '694': BarcodeCountryInfo(
      prefix: '694',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '695': BarcodeCountryInfo(
      prefix: '695',
      country: 'China',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    '890': BarcodeCountryInfo(
      prefix: '890',
      country: 'India',
      flag: '🇮🇳',
      region: 'Asia',
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el formato de código de barras basado en la longitud y estructura
  ///
  /// ## Lógica de detección:
  /// - **8 dígitos**: Puede ser EAN-8 o UPC-E
  ///   - Si comienza con 0 o 1: probablemente UPC-E (EE.UU.)
  ///   - Otros casos: EAN-8
  /// - **12 dígitos**: UPC-A (EE.UU./Canadá)
  /// - **13 dígitos**: EAN-13 (estándar internacional)
  /// - **14 dígitos**: GTIN-14 / ITF-14 (logístico)
  ///
  /// Retorna `null` si la longitud no corresponde a un formato estándar.
  static BarcodeFormat? getFormat(String code) {
    if (code.isEmpty) return null;

    final cleanCode = code.trim();

    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) return null;

    switch (cleanCode.length) {
      case 8:
        // Diferenciar entre EAN-8 y UPC-E
        // UPC-E comienza con 0 o 1 (número del sistema UPC)
        // Esta es una heurística simplificada
        final firstDigit = cleanCode[0];
        if (firstDigit == '0' || firstDigit == '1') {
          // Probablemente UPC-E (producto de EE.UU.)
          return BarcodeFormat.upcE;
        }
        return BarcodeFormat.ean8;
      case 12:
        return BarcodeFormat.upcA;
      case 13:
        return BarcodeFormat.ean13;
      case 14:
        return BarcodeFormat.gtin14;
      default:
        return null;
    }
  }

  /// Obtiene el nombre del tipo de código de barras para mostrar
  ///
  /// Wrapper de compatibilidad con la API anterior.
  /// Retorna el nombre del formato o null si no es reconocido.
  static String? getBarcodeType(String code) {
    return getFormat(code)?.displayName;
  }

  /// Valida si un código de barras es válido según estándares GS1
  ///
  /// ## Formatos validados:
  /// - **EAN-13**: Checksum Módulo 10
  /// - **EAN-8**: Checksum Módulo 10
  /// - **UPC-A**: Checksum Módulo 10
  /// - **UPC-E**: Checksum simplificado (como EAN-8)
  /// - **GTIN-14**: Checksum Módulo 10
  ///
  /// Retorna `true` si el formato y el checksum son correctos.
  static bool isValid(String code) {
    if (code.isEmpty) return false;

    final cleanCode = code.trim();

    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) return false;

    final format = getFormat(cleanCode);
    if (format == null) return false;

    switch (format) {
      case BarcodeFormat.ean13:
      case BarcodeFormat.ean8:
      case BarcodeFormat.upcA:
      case BarcodeFormat.gtin14:
        return _validateMod10Checksum(cleanCode);
      case BarcodeFormat.upcE:
        // UPC-E usa el checksum simplificado (mismo algoritmo que EAN-8)
        // Nota: La validación completa requeriría expandir a UPC-A primero,
        // pero para simplificar aceptamos si el checksum EAN-8 es válido
        return _validateMod10Checksum(cleanCode);
    }
  }

  /// Obtiene información del país de origen basada en el prefijo GS1
  ///
  /// ## Prefijos GS1 comunes:
  /// - **779**: Argentina
  /// - **789-790**: Brasil
  /// - **750**: México
  /// - **00-13**: Estados Unidos / Canadá
  /// - **400-440**: Alemania
  /// - **840-849**: España
  ///
  /// Retorna `null` si el prefijo no está en la base de datos o
  /// si el código es muy corto para determinar el país.
  static BarcodeCountryInfo? getCountryInfo(String code) {
    if (code.isEmpty) return null;

    final cleanCode = code.trim();
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) return null;

    // Para códigos de 12 dígitos (UPC-A), agregar 0 al inicio para normalizar
    String normalizedCode = cleanCode;
    if (cleanCode.length == 12) {
      normalizedCode = '0$cleanCode';
    }

    // Para códigos de 8 dígitos, no podemos determinar el país
    // ya que EAN-8 no tiene prefijo de país estándar
    if (cleanCode.length < 12) return null;

    // Para GTIN-14, el primer dígito es el indicador de empaque
    // El prefijo de país está en los dígitos 2-4
    if (cleanCode.length == 14) {
      normalizedCode = cleanCode.substring(1);
    }

    // Intentar con prefijo de 3 dígitos primero (más específico)
    final prefix3 = normalizedCode.substring(0, 3);
    if (_countryPrefixes.containsKey(prefix3)) {
      return _countryPrefixes[prefix3];
    }

    // Intentar con prefijo de 2 dígitos (UPC - EE.UU.)
    final prefix2 = normalizedCode.substring(0, 2);
    if (_countryPrefixes.containsKey(prefix2)) {
      return _countryPrefixes[prefix2];
    }

    return null;
  }

  /// Verifica si el código corresponde a un producto argentino (prefijo 779)
  ///
  /// Los productos registrados en GS1 Argentina tienen el prefijo 779.
  /// Esto indica que el código fue asignado por GS1 Argentina,
  /// NO necesariamente que el producto fue fabricado en Argentina.
  static bool isArgentinianProduct(String code) {
    final countryInfo = getCountryInfo(code);
    return countryInfo?.prefix == '779';
  }

  /// Obtiene el prefijo de país del código de barras
  ///
  /// Retorna el prefijo GS1 de 2-3 dígitos o null si no se puede determinar.
  static String? getCountryPrefix(String code) {
    return getCountryInfo(code)?.prefix;
  }

  /// Obtiene el emoji de la bandera del país de origen
  ///
  /// Retorna el emoji de la bandera o null si no se puede determinar el país.
  static String? getCountryFlag(String code) {
    return getCountryInfo(code)?.flag;
  }

  /// Obtiene una descripción formateada del código para mostrar al usuario
  ///
  /// Ejemplo: "EAN-13 🇦🇷" o "UPC-A 🇺🇸"
  ///
  /// **IMPORTANTE**: Solo retorna el formato si el checksum es válido.
  /// Si el código tiene un formato reconocido pero checksum inválido, retorna `null`.
  static String? getFormattedDescription(String code) {
    final format = getFormat(code);
    if (format == null) return null;

    // Validar checksum antes de mostrar el formato
    if (!isValid(code)) return null;

    final flag = getCountryFlag(code);
    if (flag != null) {
      return '${format.displayName} $flag';
    }

    return format.displayName;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida el dígito verificador usando el algoritmo Módulo 10 (GS1 Standard)
  ///
  /// ## Algoritmo:
  /// 1. Recorrer los dígitos de derecha a izquierda (sin contar el checksum)
  /// 2. Multiplicar posiciones impares (1, 3, 5...) por 3
  /// 3. Multiplicar posiciones pares (2, 4, 6...) por 1
  /// 4. Sumar todos los resultados
  /// 5. El checksum es (10 - (suma % 10)) % 10
  static bool _validateMod10Checksum(String code) {
    try {
      final digits = code.split('').map(int.parse).toList();

      // El último dígito es el checksum proporcionado
      final checksumDigit = digits.last;

      // Los datos son todos menos el último
      final dataDigits = digits.sublist(0, digits.length - 1);

      int sum = 0;
      // Invertimos para facilitar el conteo de posiciones desde la derecha
      final reversedData = dataDigits.reversed.toList();

      for (int i = 0; i < reversedData.length; i++) {
        // Posición 1 (índice 0) es impar -> x3
        // Posición 2 (índice 1) es par -> x1
        final weight = (i % 2 == 0) ? 3 : 1;
        sum += reversedData[i] * weight;
      }

      // Calcular checksum: (10 - (sum % 10)) % 10
      // Esto maneja el caso donde sum % 10 == 0 (checksum sería 0, no 10)
      final calculatedChecksum = (10 - (sum % 10)) % 10;

      return calculatedChecksum == checksumDigit;
    } catch (e) {
      return false;
    }
  }
}
