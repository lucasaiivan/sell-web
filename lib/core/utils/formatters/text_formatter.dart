/// Utilidades para formateo y transformación de texto
class TextFormatter {
  /// Capitaliza la primera letra de un string
  ///
  /// [text] El texto a capitalizar
  ///
  /// Ejemplo:
  /// ```dart
  /// capitalizeFirst('hello world') // "Hello world"
  /// ```
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitaliza cada palabra en un string
  ///
  /// [text] El texto a capitalizar
  ///
  /// Ejemplo:
  /// ```dart
  /// capitalizeWords('hello world') // "Hello World"
  /// ```
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Formatea un número de teléfono
  ///
  /// [phone] El número de teléfono sin formato
  ///
  /// Ejemplo:
  /// ```dart
  /// formatPhoneNumber('1234567890') // "(123) 456-7890"
  /// ```
  static String formatPhoneNumber(String phone) {
    // Remover todos los caracteres no numéricos
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length == 10) {
      // Formato estadounidense: (XXX) XXX-XXXX
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      // Formato con código de país: +1 (XXX) XXX-XXXX
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.startsWith('54') && cleaned.length >= 12) {
      // Formato argentino: +54 9 (XXX) XXXX-XXXX
      final areaCode = cleaned.substring(2, 5);
      final firstPart = cleaned.substring(5, 9);
      final secondPart = cleaned.substring(9);
      return '+54 9 ($areaCode) $firstPart-$secondPart';
    }
    
    // Si no coincide con ningún formato conocido, devolver con espacios
    return _addSpacesToNumber(cleaned);
  }

  /// Agrega espacios a un número largo para mejor legibilidad
  static String _addSpacesToNumber(String number) {
    if (number.length <= 4) return number;
    
    String formatted = '';
    for (int i = 0; i < number.length; i += 3) {
      if (formatted.isNotEmpty) formatted += ' ';
      final end = (i + 3 > number.length) ? number.length : i + 3;
      formatted += number.substring(i, end);
    }
    return formatted;
  }

  /// Trunca un texto si excede la longitud máxima
  ///
  /// [text] El texto a truncar
  /// [maxLength] Longitud máxima permitida
  /// [ellipsis] Texto a agregar al final (por defecto '...')
  ///
  /// Ejemplo:
  /// ```dart
  /// truncateText('This is a very long text', 10) // "This is a..."
  /// ```
  static String truncateText(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    
    // Buscar el último espacio antes del límite para no cortar palabras
    int cutPoint = maxLength - ellipsis.length;
    int lastSpace = text.lastIndexOf(' ', cutPoint);
    
    if (lastSpace > maxLength * 0.6) {
      // Si el último espacio está razonablemente cerca del límite, usarlo
      return '${text.substring(0, lastSpace)}$ellipsis';
    } else {
      // Si no, cortar directamente
      return '${text.substring(0, cutPoint)}$ellipsis';
    }
  }

  /// Remueve acentos y caracteres especiales de un texto
  ///
  /// [text] El texto a normalizar
  ///
  /// Ejemplo:
  /// ```dart
  /// removeAccents('Niño con piñata') // "Nino con pinata"
  /// ```
  static String removeAccents(String text) {
    const withAccents = 'áàäâéèëêíìïîóòöôúùüûñç';
    const withoutAccents = 'aaaaeeeeiiiioooouuuunc';
    
    String result = text.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Limpia un string para usarlo como slug o URL
  ///
  /// [text] El texto a convertir en slug
  ///
  /// Ejemplo:
  /// ```dart
  /// toSlug('Mi Producto Especial!') // "mi-producto-especial"
  /// ```
  static String toSlug(String text) {
    return removeAccents(text)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remover caracteres especiales
        .replaceAll(RegExp(r'\s+'), '-') // Espacios a guiones
        .replaceAll(RegExp(r'-+'), '-') // Múltiples guiones a uno solo
        .replaceAll(RegExp(r'^-|-$'), ''); // Remover guiones al inicio/final
  }

  /// Extrae las iniciales de un nombre
  ///
  /// [name] El nombre completo
  /// [maxInitials] Máximo número de iniciales (por defecto 2)
  ///
  /// Ejemplo:
  /// ```dart
  /// getInitials('Juan Carlos Pérez') // "JC"
  /// ```
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';
    
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .take(maxInitials)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .where((initial) => initial.isNotEmpty)
        .join();
    
    return initials;
  }

  /// Valida si un texto contiene solo letras y espacios
  static bool isOnlyLetters(String text) {
    return RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(text);
  }

  /// Valida si un texto contiene solo números
  static bool isOnlyNumbers(String text) {
    return RegExp(r'^\d+$').hasMatch(text);
  }

  /// Valida si un texto es alfanumérico
  static bool isAlphanumeric(String text) {
    return RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ]+$').hasMatch(text);
  }

  /// Cuenta las palabras en un texto
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Formatea un texto para mostrar como título
  ///
  /// Capitaliza la primera letra de cada palabra excepto artículos, preposiciones, etc.
  static String formatAsTitle(String text) {
    if (text.isEmpty) return text;
    
    // Palabras que normalmente no se capitalizan en títulos (en español)
    const lowerCaseWords = {
      'a', 'al', 'ante', 'bajo', 'con', 'contra', 'de', 'del', 'desde', 'durante',
      'en', 'entre', 'hacia', 'hasta', 'para', 'por', 'según', 'sin', 'sobre',
      'tras', 'y', 'e', 'ni', 'o', 'u', 'pero', 'mas', 'sino', 'que', 'la', 'las',
      'el', 'los', 'un', 'una', 'unos', 'unas'
    };
    
    final words = text.toLowerCase().split(' ');
    final formattedWords = <String>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (i == 0 || i == words.length - 1 || !lowerCaseWords.contains(word)) {
        // Capitalizar primera palabra, última palabra, o palabras importantes
        formattedWords.add(capitalizeFirst(word));
      } else {
        // Mantener en minúscula artículos y preposiciones
        formattedWords.add(word);
      }
    }
    
    return formattedWords.join(' ');
  }

  /// Resalta texto en una búsqueda
  ///
  /// [text] Texto original
  /// [query] Término de búsqueda
  /// [startTag] Tag de inicio para el highlight (ej: '<mark>')
  /// [endTag] Tag de cierre para el highlight (ej: '</mark>')
  ///
  /// Retorna texto con las coincidencias marcadas
  static String highlightSearchTerm(
    String text,
    String query, {
    String startTag = '<mark>',
    String endTag = '</mark>',
  }) {
    if (query.isEmpty) return text;
    
    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      return '$startTag${match.group(0)}$endTag';
    });
  }
}
