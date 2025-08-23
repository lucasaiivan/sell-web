/// Utilidades para formatear y manipular texto
class TextFormatter {
  /// Capitaliza la primera letra de cada palabra
  /// 
  /// [input] - Texto a capitalizar
  /// @return Texto con cada palabra capitalizada
  static String capitalizeString(String input) {
    if (input.isEmpty) {
      return input;
    }
    final words = input.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.length > 1) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      } else {
        return word.toUpperCase();
      }
    });
    return capitalizedWords.join(' ');
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
