import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilidades optimizadas para formatear fechas y tiempos
///
/// **Optimizaciones:**
/// - Formatters lazy-initialized (singleton pattern)
/// - Lógica DRY con helpers privados
/// - Pattern matching para claridad
/// - Extension types para type-safety
class DateFormatter {
  // Formatters reutilizables (evita recrear en cada llamada)
  static final _fullDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _fullDateFormat = DateFormat('dd MMM. yyyy');
  static final _shortDateFormat = DateFormat('dd MMM.');
  static final _timeFormat = DateFormat('HH:mm');

  /// Formatea fecha y hora en formato estándar
  ///
  /// **Formato:** dd/MM/yyyy HH:mm
  /// **Complejidad:** O(1)
  static String formatPublicationDate({required DateTime dateTime}) =>
      _fullDateTimeFormat.format(dateTime);

  /// Obtiene la fecha de publicación en formato legible simple
  ///
  /// **Formatos posibles:**
  /// - "Hoy" (mismo día)
  /// - "Ayer" (día anterior)
  /// - "dd MMM." (mismo año)
  /// - "dd MMM. yyyy" (año diferente)
  ///
  /// **Complejidad:** O(1) - comparaciones constantes
  static String getSimplePublicationDate(
    DateTime postDate,
    DateTime currentDate,
  ) {
    // Normalizar a solo fecha (sin hora) para comparación
    final postDay = _normalizeDate(postDate);
    final currentDay = _normalizeDate(currentDate);
    final daysDifference = currentDay.difference(postDay).inDays;

    return switch (daysDifference) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ when postDay.year != currentDay.year =>
        _fullDateFormat.format(postDate),
      _ => _shortDateFormat.format(postDate),
    };
  }

  /// Obtiene la fecha de publicación en formato legible detallado
  ///
  /// **Formatos posibles:**
  /// - "Hace instantes" (< 30 min)
  /// - "Hace X min." (30-60 min)
  /// - "Hace X horas" (1-8 horas)
  /// - "Hoy" (mismo día, > 8 horas)
  /// - "Ayer HH:mm" (día anterior)
  /// - "dd MMM." (días anteriores, mismo año)
  /// - "dd MMM. yyyy" (año diferente)
  ///
  /// **Complejidad:** O(1)
  static String getDetailedPublicationDate({
    required DateTime fechaPublicacion,
    required DateTime fechaActual,
  }) {
    final postDay = _normalizeDate(fechaPublicacion);
    final currentDay = _normalizeDate(fechaActual);
    final daysDifference = currentDay.difference(postDay).inDays;

    // Año diferente
    if (fechaPublicacion.year != fechaActual.year) {
      return _fullDateFormat.format(fechaPublicacion);
    }

    // Días anteriores
    return switch (daysDifference) {
      0 => _formatSameDay(fechaPublicacion, fechaActual),
      1 => 'Ayer ${_timeFormat.format(fechaPublicacion)}',
      _ => _shortDateFormat.format(fechaPublicacion),
    };
  }

  // ==========================================
  // HELPERS PRIVADOS
  // ==========================================

  /// Normaliza DateTime a solo fecha (hora a 00:00:00)
  ///
  /// **Complejidad:** O(1)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Formatea el tiempo relativo para el mismo día
  ///
  /// **Complejidad:** O(1)
  static String _formatSameDay(DateTime postDate, DateTime currentDate) {
    final difference = currentDate.difference(postDate);

    return switch (difference.inMinutes) {
      < 30 => 'Hace instantes',
      < 60 => 'Hace ${difference.inMinutes} min.',
      _ when difference.inHours < 8 => 'Hace ${difference.inHours} horas',
      _ => 'Hoy',
    };
  }

  /// Calcula el tiempo transcurrido con formato compacto
  ///
  /// **Formatos:**
  /// - "2d 3h" (días + horas)
  /// - "5h 30m" (horas + minutos)
  /// - "45m 12s" (minutos + segundos)
  /// - "Ahora mismo" (< 1 segundo)
  ///
  /// **Complejidad:** O(1)
  static String getElapsedTime({
    required DateTime fechaInicio,
    bool showMinutes = true,
  }) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaInicio);

    if (diferencia.inSeconds < 1) return 'Ahora mismo';

    // Componentes de tiempo
    final (dias, horas, minutos, segundos) = (
      diferencia.inDays,
      diferencia.inHours % 24,
      diferencia.inMinutes % 60,
      diferencia.inSeconds % 60,
    );

    // Construir partes usando pattern matching
    final partes = <String>[];

    if (dias > 0) {
      partes.add('${dias}d');
      if (horas > 0) {
        partes.add('${horas}h');
      } else if (showMinutes && minutos > 0) {
        partes.add('${minutos}m');
      }
    } else if (horas > 0) {
      partes.add('${horas}h');
      if (showMinutes) partes.add('${minutos}m');
    } else if (minutos > 0) {
      partes.add('${minutos}m');
      if (minutos < 10 && segundos > 0) partes.add('${segundos}s');
    } else {
      partes.add('${segundos}s');
    }

    return partes.take(2).join(' ');
  }

  /// Devuelve una marca de tiempo actual de Firestore
  static Timestamp getCurrentTimestamp() => Timestamp.now();
}
