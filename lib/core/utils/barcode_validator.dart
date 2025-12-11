class BarcodeValidator {
  /// Obtiene el tipo de código de barras según su longitud
  /// Retorna el nombre del formato o null si no es reconocido
  static String? getBarcodeType(String code) {
    if (code.isEmpty) return null;
    
    final cleanCode = code.trim();
    
    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) return null;

    switch (cleanCode.length) {
      case 8:
        return 'EAN-8';
      case 12:
        return 'UPC-A';
      case 13:
        return 'EAN-13';
      case 14:
        return 'GTIN-14';
      default:
        return null;
    }
  }

  /// Valida si un código de barras es válido (EAN-13, EAN-8, UPC-A, UPC-E)
  /// Retorna true si el formato y el checksum son correctos.
  static bool isValid(String code) {
    if (code.isEmpty) return false;
    
    // Eliminar espacios en blanco
    final cleanCode = code.trim();
    
    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) return false;

    // Validar longitud y checksum según el tipo
    switch (cleanCode.length) {
      case 8: // EAN-8
        return _validateChecksum(cleanCode);
      case 12: // UPC-A
        return _validateChecksum(cleanCode);
      case 13: // EAN-13
        return _validateChecksum(cleanCode);
      case 14: // GTIN-14 / ITF-14
        return _validateChecksum(cleanCode);
      default:
        // Para otros formatos o longitudes no estándar, asumimos válido si es numérico
        // pero retornamos false para indicar que no pasó la validación estricta de formato estándar
        // Dependiendo de la regla de negocio, podríamos retornar true si solo queremos validar que sea numérico.
        // Según el requerimiento: "Validación Matemática... valida el checksum"
        return false;
    }
  }

  /// Calcula y valida el dígito verificador (algoritmo Módulo 10)
  static bool _validateChecksum(String code) {
    try {
      // Convertir a lista de dígitos
      final digits = code.split('').map(int.parse).toList();
      
      // El último dígito es el checksum proporcionado
      final checksumDigit = digits.last;
      
      // Los datos son todos menos el último
      final dataDigits = digits.sublist(0, digits.length - 1);
      
      // Calcular checksum
      // 1. Sumar posiciones impares (desde la derecha, sin contar checksum)
      // 2. Sumar posiciones pares (desde la derecha)
      // Nota: La implementación estándar suele ser:
      // Recorrer de derecha a izquierda.
      // Posiciones impares (1, 3, 5...) se multiplican por 3.
      // Posiciones pares (2, 4, 6...) se multiplican por 1.
      
      int sum = 0;
      // Invertimos para facilitar el conteo de posiciones desde la derecha
      final reversedData = dataDigits.reversed.toList();
      
      for (int i = 0; i < reversedData.length; i++) {
        // Posición 1 (índice 0) es impar -> x3
        // Posición 2 (índice 1) es par -> x1
        final weight = (i % 2 == 0) ? 3 : 1;
        sum += reversedData[i] * weight;
      }
      
      final nearestTen = (sum / 10).ceil() * 10;
      final calculatedChecksum = nearestTen - sum;
      
      return calculatedChecksum == checksumDigit;
    } catch (e) {
      return false;
    }
  }
}
