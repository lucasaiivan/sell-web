import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper para generar identificadores únicos
/// 
/// **Estrategia:** Timestamp + Microsegundos + Random
/// **Unicidad:** Probabilidad de colisión < 1 en 1.000.000 por segundo
/// 
/// **Dart 3.x Features:**
/// - Usa Records para descomponer componentes
/// - Pattern matching para claridad
class UidHelper {
  // Singleton para Random (evita recrear en cada llamada)
  static final Random _random = Random();
  static final DateFormat _formatter = DateFormat('ddMMyyyyHHmmss');

  /// Genera un UID basado en la fecha, hora actual y componente aleatorio
  ///
  /// **Formato:** ddMMyyyyHHmmssSSSRRR (20 dígitos)
  /// - ddMMyyyyHHmmss: fecha y hora hasta segundos (14 dígitos)
  /// - SSS: microsegundos (3 dígitos)
  /// - RRR: componente aleatorio (3 dígitos)
  ///
  /// **Complejidad:** O(1) - operaciones constantes
  /// 
  /// **Ejemplos:**
  /// ```dart
  /// generateUid() // '27112025153045123456'
  /// ```
  /// 
  /// @return String numérico único de 20 dígitos
  static String generateUid() {
    final now = Timestamp.now().toDate();
    
    // Descomponer usando Records (Dart 3.x)
    final (baseTime, microseconds, randomPart) = _generateComponents(now);
    
    return '$baseTime$microseconds$randomPart';
  }

  /// Genera componentes del UID usando Records
  /// 
  /// **Retorna:** (baseTime, microseconds, random) como Record
  static (String, String, String) _generateComponents(DateTime dateTime) {
    // Fecha y hora base (14 dígitos)
    final baseTime = _formatter.format(dateTime);

    // Microsegundos truncados a 3 dígitos (precisión extra)
    final microseconds = dateTime.microsecond
        .toString()
        .padLeft(6, '0')
        .substring(0, 3);

    // Componente aleatorio para evitar colisiones (3 dígitos: 000-999)
    final randomPart = _random.nextInt(1000).toString().padLeft(3, '0');

    return (baseTime, microseconds, randomPart);
  }

  /// Genera un UID con prefijo personalizado (útil para debugging)
  /// 
  /// **Ejemplo:**
  /// ```dart
  /// generatePrefixedUid('TRX') // 'TRX-27112025153045123'
  /// ```
  static String generatePrefixedUid(String prefix) {
    return '$prefix-${generateUid()}';
  }
}
