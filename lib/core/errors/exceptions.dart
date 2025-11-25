/// Excepción lanzada cuando falla una llamada al servidor
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Error de servidor']);
}

/// Excepción lanzada cuando falla una operación de caché
class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Error de caché']);
}

/// Excepción lanzada cuando no hay conexión a internet
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Error de red']);
}
