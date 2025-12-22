/// Utilidades para formatear y manipular texto
class TextFormatter {
  /// Capitaliza la primera letra de cada palabra (Title Case)
  ///
  /// [input] - Texto a capitalizar
  /// @return Texto con cada palabra capitalizada
  static String capitalizeString(String input) {
    if (input.trim().isEmpty) return input;

    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      if (word.length > 1) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      } else {
        return word.toUpperCase();
      }
    }).join(' ');
  }

  /// Capitaliza solo la primera letra de la primera palabra (Sentence Case)
  ///
  /// [input] - Texto a formatear
  /// @return Texto con la primera letra en mayúscula
  static String toSentenceCase(String input) {
    if (input.trim().isEmpty) return input;
    final trimmed = input.trim();
    if (trimmed.length > 1) {
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
    } else {
      return trimmed.toUpperCase();
    }
  }

  /// Normaliza el texto quitando espacios, acentos y convirtiendo a minúsculas
  ///
  /// [text] - Texto a normalizar
  /// @return Texto normalizado
  static String normalizeText(String text) {
    return text
        .replaceAll(' ', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .toLowerCase();
  }
}
