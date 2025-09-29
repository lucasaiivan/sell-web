import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper para generar identificadores únicos
class UidHelper {
  static final Random _random = Random();
  
  /// Genera un UID basado en la fecha, hora actual y componente aleatorio
  ///
  /// Formato: ddMMyyyyHHmmssSSSRRR
  /// - ddMMyyyyHHmmss: fecha y hora hasta segundos
  /// - SSS: microsegundos (3 dígitos)  
  /// - RRR: componente aleatorio (3 dígitos)
  /// 
  /// @return String numérico único de 20 dígitos
  static String generateUid() {
    final now = Timestamp.now().toDate();
    
    // Fecha y hora base (14 dígitos): ddMMyyyyHHmmss
    final baseTime = DateFormat('ddMMyyyyHHmmss').format(now);
    
    // Microsegundos para mayor precisión (3 dígitos)
    final microseconds = now.microsecond.toString().padLeft(3, '0').substring(0, 3);
    
    // Componente aleatorio para evitar colisiones (3 dígitos)
    final randomComponent = _random.nextInt(1000).toString().padLeft(3, '0');
    
    return '$baseTime$microseconds$randomComponent';
  }
}
