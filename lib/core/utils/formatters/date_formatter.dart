import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilidades para formatear fechas y tiempos
class DateFormatter {
  /// Recibe la fecha y devuelve el formato dd/MM/yyyy HH:mm
  static String formatPublicationDate({required DateTime dateTime}) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dateTime).toString();

  /// Obtiene la fecha de publicación en formato legible simple
  /// 
  /// [postDate] La fecha de publicación del contenido
  /// [currentDate] La fecha actual del sistema
  /// @return La fecha en formato legible para el usuario
  static String getSimplePublicationDate(DateTime postDate, DateTime currentDate) {
    if (postDate.year != currentDate.year) {
      // Si la publicación es de un año diferente, muestra la fecha completa
      return DateFormat('dd MMM. yyyy').format(postDate);
    } else if (postDate.month != currentDate.month ||
        postDate.day != currentDate.day) {
      // Si la publicación no es del mismo día de hoy
      if (postDate.year == currentDate.year &&
          postDate.month == currentDate.month &&
          postDate.day == currentDate.day - 1) {
        // Si la publicación es del día anterior, muestra "Ayer"
        return 'Ayer';
      } else {
        // Si la publicación no es del día anterior, muestra la fecha sin el año
        return DateFormat('dd MMM.').format(postDate);
      }
    } else {
      // Si la publicación es del mismo día de hoy, muestra "Hoy"
      return 'Hoy';
    }
  }

  /// Obtiene la fecha de publicación en formato legible detallado
  /// 
  /// [fechaPublicacion] La fecha de publicación del contenido
  /// [fechaActual] La fecha actual del sistema
  /// @return La fecha en formato legible para el usuario
  static String getDetailedPublicationDate({
    required DateTime fechaPublicacion,
    required DateTime fechaActual,
  }) {
    // Si el año de la publicacion es diferente al año actual
    if (fechaPublicacion.year != fechaActual.year) {
      // Si la publicación es de un año diferente, muestra la fecha completa
      return DateFormat('dd MMM. yyyy').format(fechaPublicacion);
    } else if (fechaPublicacion.month != fechaActual.month ||
        fechaPublicacion.day != fechaActual.day) {
      // Si la publicación no es del mismo día de hoy
      if (fechaPublicacion.year == fechaActual.year &&
          fechaPublicacion.month == fechaActual.month &&
          fechaPublicacion.day == fechaActual.day - 1) {
        // Si la publicación es del día anterior, muestra "Ayer"
        return 'Ayer ${DateFormat('HH:mm').format(fechaPublicacion)}';
      } else {
        // Si la publicación no es del día anterior, muestra la fecha sin el año
        return DateFormat('dd MMM.').format(fechaPublicacion);
      }
    } else {
      // Si la publicación es del mismo día de hoy
      Duration difference = fechaActual.difference(fechaPublicacion);
      if (difference.inMinutes < 30) {
        // Si la publicación fue hace menos de 30 minutos, muestra "Hace instantes"
        return 'Hace instantes';
      } else if (difference.inMinutes < 60) {
        // Si la publicación fue hace menos de una hora, muestra los minutos
        return 'Hace ${difference.inMinutes} min.';
      } else if (difference.inHours < 8) {
        // Si la publicación fue hace menos de 8 horas, muestra las horas
        return 'Hace ${difference.inHours} horas';
      } else {
        // Si la publicación fue hace 8 horas o más, muestra "Hoy"
        return 'Hoy';
      }
    }
  }

  /// Calcula el tiempo transcurrido desde una fecha dada hasta ahora con mayor precisión
  /// 
  /// [fechaInicio] La fecha desde la cual se quiere calcular el tiempo transcurrido
  /// [showMinutes] Si se deben mostrar los minutos por defecto (true por defecto)
  /// @return String con el tiempo transcurrido en formato específico (ej: "2d 3h", "5h 30m", "1d 12h 45m")
  static String getElapsedTime({
    required DateTime fechaInicio,
    bool showMinutes = true,
  }) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaInicio);

    final dias = diferencia.inDays;
    final horas = diferencia.inHours % 24;
    final minutos = diferencia.inMinutes % 60;
    final segundos = diferencia.inSeconds % 60;

    List<String> partes = [];

    if (dias > 0) {
      partes.add('${dias}d');
      if (horas > 0) {
        partes.add('${horas}h');
      } else if (showMinutes && minutos > 0) {
        // Si no hay horas pero hay minutos y se deben mostrar
        partes.add('${minutos}m');
      }
    } else if (horas > 0) {
      partes.add('${horas}h');
      if (showMinutes) {
        // Siempre mostrar minutos cuando hay horas y está habilitado
        partes.add('${minutos}m');
      }
    } else if (minutos > 0) {
      partes.add('${minutos}m');
      if (minutos < 10 && segundos > 0) {
        partes.add('${segundos}s');
      }
    } else if (segundos > 0) {
      partes.add('${segundos}s');
    } else {
      return 'Ahora mismo';
    }

    return partes.take(2).join(' ');
  }

  /// Devuelve una marca de tiempo actual de Firestore
  static Timestamp getCurrentTimestamp() => Timestamp.now();
}
