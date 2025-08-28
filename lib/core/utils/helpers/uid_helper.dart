import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper para generar identificadores únicos
class UidHelper {
  /// Genera un UID basado en la fecha y hora actual
  ///
  /// Formato: ddMMyyyyHHmmss
  /// @return String con el UID generado
  static String generateUid() =>
      DateFormat('ddMMyyyyHHmmss').format(Timestamp.now().toDate()).toString();
}
