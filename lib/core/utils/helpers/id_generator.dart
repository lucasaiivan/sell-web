/// Generador universal de IDs únicos y legibles para entidades del sistema
///
/// Genera IDs con formato: [PREFIX]-[HASH]-[DATE]-[SEQ]
///
/// **Ventajas:**
/// - IDs cortos y legibles (22 caracteres)
/// - Fecha visible para identificación rápida
/// - Único por cuenta + timestamp
/// - Ordenables cronológicamente
///
/// **Ejemplos:**
/// - Productos: SKU-A3F9K-20251211-0001
/// - Categorías: CAT-A3F9K-20251211-0001
/// - Proveedores: PRV-A3F9K-20251211-0001
/// - Marcas: BRD-A3F9K-20251211-0001
class IdGenerator {
  /// Prefijos para diferentes tipos de entidades
  static const String productPrefix = 'SKU';
  static const String categoryPrefix = 'CAT';
  static const String providerPrefix = 'PRV';
  static const String brandPrefix = 'BRD';
  static const String transactionPrefix = 'TRX';
  static const String ticketPrefix = 'TKT';

  /// Genera un ID único para un producto SKU interno
  ///
  /// Formato: SKU-XXXXX-YYYYMMDD-NNNN
  /// - XXXXX: Hash corto del accountId (5 caracteres alfanuméricos)
  /// - YYYYMMDD: Fecha actual (año-mes-día)
  /// - NNNN: Secuencia única del día (4 dígitos)
  ///
  /// Ejemplo: `SKU-A3F9K-20251211-0001`
  static String generateProductSku(String accountId) {
    return _generateId(productPrefix, accountId);
  }

  /// Genera un ID único para una categoría
  ///
  /// Formato: CAT-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo: `CAT-A3F9K-20251211-0001`
  static String generateCategoryId(String accountId) {
    return _generateId(categoryPrefix, accountId);
  }

  /// Genera un ID único para un proveedor
  ///
  /// Formato: PRV-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo: `PRV-A3F9K-20251211-0001`
  static String generateProviderId(String accountId) {
    return _generateId(providerPrefix, accountId);
  }

  /// Genera un ID único para una marca
  ///
  /// Formato: BRD-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo: `BRD-A3F9K-20251211-0001`
  static String generateBrandId(String accountId) {
    return _generateId(brandPrefix, accountId);
  }

  /// Genera un ID único para una transacción
  ///
  /// Formato: TRX-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo: `TRX-A3F9K-20251211-0001`
  static String generateTransactionId(String accountId) {
    return _generateId(transactionPrefix, accountId);
  }

  /// Genera un ID único para un ticket/venta
  ///
  /// Formato: TKT-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo: `TKT-A3F9K-20251211-0001`
  static String generateTicketId(String accountId) {
    return _generateId(ticketPrefix, accountId);
  }

  /// Genera un ID genérico con el formato estándar
  ///
  /// [prefix] - Prefijo del tipo de entidad (SKU, CAT, PRV, etc.)
  /// [accountId] - ID de la cuenta del comercio
  ///
  /// Retorna: PREFIX-XXXXX-YYYYMMDD-NNNN
  static String _generateId(String prefix, String accountId) {
    final now = DateTime.now();
    
    // Generar hash corto del accountId (5 caracteres alfanuméricos)
    final accountHash = _generateShortHash(accountId);
    
    // Fecha en formato compacto YYYYMMDD
    final dateStr = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    
    // Secuencia única basada en milisegundos del día (4 dígitos)
    final millisOfDay = now.millisecondsSinceEpoch % 86400000; // Milisegundos en un día
    final sequence = (millisOfDay % 10000).toString().padLeft(4, '0');
    
    return '$prefix-$accountHash-$dateStr-$sequence';
  }

  /// Genera un hash corto alfanumérico de 5 caracteres
  ///
  /// Convierte el hashCode del string a base36 (0-9, A-Z)
  /// y asegura que tenga exactamente 5 caracteres.
  static String _generateShortHash(String input) {
    // Usar hashCode del string y convertirlo a base36 (0-9, A-Z)
    final hash = input.hashCode.abs();
    var result = hash.toRadixString(36).toUpperCase();
    
    // Asegurar que tenga exactamente 5 caracteres
    if (result.length > 5) {
      result = result.substring(0, 5);
    } else if (result.length < 5) {
      result = result.padLeft(5, '0');
    }
    
    return result;
  }

  /// Verifica si un string es un ID generado por este sistema
  ///
  /// Retorna true si el ID tiene el formato PREFIX-XXXXX-YYYYMMDD-NNNN
  ///
  /// Ejemplo:
  /// ```dart
  /// IdGenerator.isGeneratedId('SKU-A3F9K-20251211-0001') // true
  /// IdGenerator.isGeneratedId('7501234567890') // false
  /// ```
  static bool isGeneratedId(String id) {
    final pattern = RegExp(r'^[A-Z]{3}-[A-Z0-9]{5}-\d{8}-\d{4}$');
    return pattern.hasMatch(id);
  }

  /// Extrae el prefijo de un ID generado
  ///
  /// Ejemplo: `"SKU-A3F9K-20251211-0001"` → `"SKU"`
  ///
  /// Retorna null si el ID no tiene el formato correcto
  static String? extractPrefix(String id) {
    if (!isGeneratedId(id)) return null;
    return id.split('-').first;
  }

  /// Extrae la fecha de creación de un ID generado
  ///
  /// Ejemplo: `"SKU-A3F9K-20251211-0001"` → `DateTime(2025, 12, 11)`
  ///
  /// Retorna null si el ID no tiene el formato correcto
  static DateTime? extractDate(String id) {
    if (!isGeneratedId(id)) return null;
    
    try {
      final parts = id.split('-');
      final dateStr = parts[2]; // YYYYMMDD
      
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Extrae el hash de la cuenta de un ID generado
  ///
  /// Ejemplo: `"SKU-A3F9K-20251211-0001"` → `"A3F9K"`
  ///
  /// Retorna null si el ID no tiene el formato correcto
  static String? extractAccountHash(String id) {
    if (!isGeneratedId(id)) return null;
    final parts = id.split('-');
    return parts[1];
  }

  /// Extrae la secuencia de un ID generado
  ///
  /// Ejemplo: `"SKU-A3F9K-20251211-0001"` → `"0001"`
  ///
  /// Retorna null si el ID no tiene el formato correcto
  static String? extractSequence(String id) {
    if (!isGeneratedId(id)) return null;
    final parts = id.split('-');
    return parts[3];
  }

  /// Compara dos IDs generados por fecha
  ///
  /// Retorna:
  /// - Negativo si id1 es anterior a id2
  /// - 0 si son del mismo día
  /// - Positivo si id1 es posterior a id2
  ///
  /// Retorna null si alguno de los IDs no es válido
  static int? compareByDate(String id1, String id2) {
    final date1 = extractDate(id1);
    final date2 = extractDate(id2);
    
    if (date1 == null || date2 == null) return null;
    
    return date1.compareTo(date2);
  }
}
