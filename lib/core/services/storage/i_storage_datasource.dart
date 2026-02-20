import 'dart:typed_data';

/// Contrato para operaciones de Firebase Storage
///
/// **Patrón:** Repository Pattern con abstracción de Storage
/// **Beneficio:** Testeable, mockeable, intercambiable
///
/// Define operaciones de almacenamiento sin acoplar a Firebase Storage.
/// Permite implementar con Firebase Storage, mock local, o cualquier backend.
abstract interface class IStorageDataSource {
  /// Sube un archivo a Storage y retorna la URL de descarga
  ///
  /// [path] Ruta completa en Storage (ej: 'ACCOUNTS/abc123/PRODUCTS/prod1.jpg')
  /// [fileBytes] Bytes del archivo a subir
  /// [metadata] Metadatos opcionales (contentType, customMetadata)
  ///
  /// Returns URL pública de descarga
  Future<String> uploadFile(
    String path,
    Uint8List fileBytes, {
    Map<String, String>? metadata,
  });

  /// Elimina un archivo de Storage
  ///
  /// [path] Ruta completa del archivo a eliminar
  Future<void> deleteFile(String path);

  /// Obtiene la URL de descarga de un archivo
  ///
  /// [path] Ruta completa del archivo
  /// Returns URL pública de descarga
  Future<String> getDownloadUrl(String path);

  /// Verifica si un archivo existe en Storage
  ///
  /// [path] Ruta completa del archivo
  /// Returns true si existe, false si no
  Future<bool> fileExists(String path);

  /// Elimina todos los archivos dentro de una carpeta en Storage
  ///
  /// [folderPath] Ruta de la carpeta a eliminar (ej: 'ACCOUNTS/abc123/PRODUCTS')
  /// 
  /// **Nota:** Elimina recursivamente todos los archivos dentro de la carpeta.
  /// Si la carpeta no existe o está vacía, no lanza error.
  Future<void> deleteFolder(String folderPath);
}
