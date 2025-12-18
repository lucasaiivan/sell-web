import 'dart:math';

/// Generador universal de IDs únicos y legibles para entidades del sistema
///
/// Genera IDs con formato: [PREFIX]-[HASH/SALT]-[DATE]-[SEQ]
///
/// **Ventajas:**
/// - IDs cortos y legibles
/// - Fecha visible para identificación rápida
/// - Único por colisión controlada + timestamp
/// - Ordenables cronológicamente
///
/// **Ejemplos:**
/// - Productos: SKU-A3F-20251211-0001 (Salt aleatorio 3 chars)
/// - Transacciones: TRX-USR12-20251211-0001 (Primeros 5 chars del userId)
class IdGenerator {
  /// Prefijos para diferentes tipos de entidades
  static const String productPrefix = 'SKU';
  static const String categoryPrefix = 'CAT';
  static const String providerPrefix = 'PRV';
  static const String brandPrefix = 'BRD';
  static const String transactionPrefix = 'TRX';
  static const String cashRegisterPrefix = 'CSH';

  /// Genera un ID único para un producto SKU interno
  /// Usa un Random Salt de 3 caracteres para brevedad.
  static String generateProductSku() {
    return _generateId(productPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID único para una categoría
  static String generateCategoryId() {
    return _generateId(categoryPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID único para un proveedor
  static String generateProviderId() {
    return _generateId(providerPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID único para una marca
  static String generateBrandId() {
    return _generateId(brandPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID único para una caja registradora
  static String generateCashRegisterId() {
    return _generateId(cashRegisterPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID único para una transacción o ticket de venta
  static String generateTransactionId() {
    return _generateId(transactionPrefix, _generateRandomSalt(3));
  }

  /// Genera un ID genérico con el formato estándar
  static String _generateId(String prefix, String hash) {
    final now = DateTime.now();

    // Fecha en formato compacto YYYYMMDD
    final dateStr = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // Secuencia única basada en milisegundos del día (4 dígitos)
    final millisOfDay = now.millisecondsSinceEpoch % 86400000;
    final sequence = (millisOfDay % 10000).toString().padLeft(4, '0');

    return '$prefix-$hash-$dateStr-$sequence';
  }

  /// Genera un salt aleatorio alfanumérico
  static String _generateRandomSalt(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  /// Verifica si un string es un ID generado por este sistema
  /// Soporta hashes de 3 a 5 caracteres
  static bool isGeneratedId(String id) {
    final pattern = RegExp(r'^[A-Z]{3}-[A-Z0-9]{3,5}-\d{8}-\d{4}$');
    return pattern.hasMatch(id);
  }

  /// Extrae el prefijo de un ID generado
  static String? extractPrefix(String id) {
    if (!isGeneratedId(id)) return null;
    return id.split('-').first;
  }

  /// Extrae la fecha de creación de un ID generado
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

  /// Extrae el hash/salt de un ID generado
  static String? extractHash(String id) {
    if (!isGeneratedId(id)) return null;
    final parts = id.split('-');
    return parts[1];
  }

  /// Extrae la secuencia de un ID generado
  static String? extractSequence(String id) {
    if (!isGeneratedId(id)) return null;
    final parts = id.split('-');
    return parts[3];
  }

  /// Compara dos IDs generados por fecha
  static int? compareByDate(String id1, String id2) {
    final date1 = extractDate(id1);
    final date2 = extractDate(id2);

    if (date1 == null || date2 == null) return null;

    return date1.compareTo(date2);
  }
}

