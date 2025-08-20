import 'package:intl/intl.dart';

/// Utilidades para formateo de fechas y tiempo
class DateFormatter {
  static final Map<String, DateFormat> _formatters = {};

  /// Obtiene un formateador de fecha (con caché)
  static DateFormat _getFormatter(String pattern, {String? locale}) {
    final key = '${pattern}_${locale ?? 'es_AR'}';
    return _formatters.putIfAbsent(
      key,
      () => DateFormat(pattern, locale ?? 'es_AR'),
    );
  }

  /// Formatea una fecha según el patrón especificado
  ///
  /// [date] La fecha a formatear
  /// [pattern] El patrón de formato (por defecto 'dd/MM/yyyy')
  /// [locale] La configuración regional (por defecto 'es_AR')
  ///
  /// Ejemplos:
  /// ```dart
  /// formatDate(DateTime.now()) // "19/08/2025"
  /// formatDate(DateTime.now(), pattern: 'dd MMM yyyy') // "19 ago 2025"
  /// ```
  static String formatDate(
    DateTime date, {
    String pattern = 'dd/MM/yyyy',
    String? locale,
  }) {
    return _getFormatter(pattern, locale: locale).format(date);
  }

  /// Formatea fecha y hora juntas
  ///
  /// [dateTime] La fecha y hora a formatear
  /// [pattern] El patrón (por defecto 'dd/MM/yyyy HH:mm')
  ///
  /// Ejemplo:
  /// ```dart
  /// formatDateTime(DateTime.now()) // "19/08/2025 14:30"
  /// ```
  static String formatDateTime(
    DateTime dateTime, {
    String pattern = 'dd/MM/yyyy HH:mm',
    String? locale,
  }) {
    return _getFormatter(pattern, locale: locale).format(dateTime);
  }

  /// Formatea solo la hora
  ///
  /// [time] La fecha/hora de la cual extraer la hora
  /// [pattern] El patrón (por defecto 'HH:mm')
  ///
  /// Ejemplo:
  /// ```dart
  /// formatTime(DateTime.now()) // "14:30"
  /// ```
  static String formatTime(
    DateTime time, {
    String pattern = 'HH:mm',
    String? locale,
  }) {
    return _getFormatter(pattern, locale: locale).format(time);
  }

  /// Obtiene una fecha relativa más legible (Hoy, Ayer, etc.)
  ///
  /// [postDate] La fecha de la publicación
  /// [currentDate] La fecha actual (opcional, por defecto DateTime.now())
  ///
  /// Retorna:
  /// - "Hoy" si es el mismo día
  /// - "Ayer" si es el día anterior  
  /// - "dd MMM." para fechas del mismo año
  /// - "dd MMM. yyyy" para fechas de años diferentes
  static String getRelativeDate({
    required DateTime postDate,
    DateTime? currentDate,
  }) {
    final current = currentDate ?? DateTime.now();

    // Si es de un año diferente, mostrar fecha completa
    if (postDate.year != current.year) {
      return formatDate(postDate, pattern: 'dd MMM. yyyy');
    }

    // Si no es del mismo día
    if (postDate.month != current.month || postDate.day != current.day) {
      // Verificar si es del día anterior
      final yesterday = current.subtract(const Duration(days: 1));
      if (postDate.year == yesterday.year &&
          postDate.month == yesterday.month &&
          postDate.day == yesterday.day) {
        return 'Ayer';
      }
      
      // Fecha del mismo año pero diferente día
      return formatDate(postDate, pattern: 'dd MMM.');
    }

    // Es del mismo día
    return 'Hoy';
  }

  /// Obtiene fecha de publicación con hora para el mismo día
  ///
  /// Similar a getRelativeDate pero incluye hora para días anteriores recientes
  static String getPublicationDate({
    required DateTime fechaPublicacion,
    DateTime? fechaActual,
  }) {
    final actual = fechaActual ?? DateTime.now();

    // Si es de un año diferente
    if (fechaPublicacion.year != actual.year) {
      return formatDate(fechaPublicacion, pattern: 'dd MMM. yyyy');
    }

    // Si no es del mismo día
    if (fechaPublicacion.month != actual.month ||
        fechaPublicacion.day != actual.day) {
      
      // Si es del día anterior, incluir hora
      final yesterday = actual.subtract(const Duration(days: 1));
      if (fechaPublicacion.year == yesterday.year &&
          fechaPublicacion.month == yesterday.month &&
          fechaPublicacion.day == yesterday.day) {
        return 'Ayer ${formatTime(fechaPublicacion)}';
      }
      
      // Fecha diferente del mismo año
      return formatDate(fechaPublicacion, pattern: 'dd MMM.');
    }

    // Es del mismo día - calcular tiempo transcurrido
    return _getTimeElapsedSameDay(fechaPublicacion, actual);
  }

  /// Calcula el tiempo transcurrido para el mismo día
  static String _getTimeElapsedSameDay(DateTime start, DateTime end) {
    final difference = end.difference(start);

    if (difference.inMinutes < 30) {
      return 'Hace instantes';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min.';
    } else if (difference.inHours < 8) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hoy';
    }
  }

  /// Calcula el tiempo transcurrido desde una fecha con mayor precisión
  ///
  /// [fechaInicio] La fecha desde la cual calcular
  /// [showMinutes] Si mostrar minutos (por defecto true)
  ///
  /// Retorna formato como "2d 3h", "5h 30m", "1d 12h 45m"
  static String getTimeElapsed({
    required DateTime fechaInicio,
    bool showMinutes = true,
    DateTime? fechaFin,
  }) {
    final ahora = fechaFin ?? DateTime.now();
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
        partes.add('${minutos}m');
      }
    } else if (horas > 0) {
      partes.add('${horas}h');
      if (showMinutes) {
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

    // Limitar a máximo 2 partes para mantener legibilidad
    return partes.take(2).join(' ');
  }

  /// Convierte un string de fecha a DateTime
  ///
  /// [dateString] String con formato de fecha
  /// [pattern] Patrón esperado del string
  ///
  /// Retorna DateTime o null si no es válido
  static DateTime? parseDate(String dateString, {String pattern = 'dd/MM/yyyy'}) {
    try {
      return _getFormatter(pattern).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Valida si un string representa una fecha válida
  static bool isValidDate(String dateString, {String pattern = 'dd/MM/yyyy'}) {
    return parseDate(dateString, pattern: pattern) != null;
  }

  /// Obtiene el inicio del día para una fecha
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtiene el final del día para una fecha  
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Resetea el caché de formatters
  static void clearCache() {
    _formatters.clear();
  }
}
