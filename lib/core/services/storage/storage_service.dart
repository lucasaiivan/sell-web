import 'dart:typed_data';
import 'package:sellweb/core/di/injection_container.dart';
import 'i_storage_datasource.dart';
import 'storage_paths.dart';

/// Servicio de Storage con métodos estáticos
///
/// **Deprecado:** Usar [IStorageDataSource] directamente con DI
///
/// Este servicio existe para mantener compatibilidad con código legacy
/// que usa métodos estáticos. Gradualmente migrar a inyección de dependencias.
///
/// **Patrón de migración:**
/// ```dart
/// // ❌ ANTES (legacy)
/// final url = await StorageService.uploadProductImage(id, bytes);
///
/// // ✅ DESPUÉS (recomendado)
/// class MyRepository {
///   final IStorageDataSource _storage;
///   MyRepository(this._storage);
///
///   Future<String> uploadImage(String id, Uint8List bytes) {
///     final path = StoragePaths.productImage(accountId, id);
///     return _storage.uploadFile(path, bytes);
///   }
/// }
/// ```
class StorageService {
  StorageService._(); // Prevent instantiation

  /// Obtiene instancia de StorageDataSource desde DI
  static IStorageDataSource get _storage => getIt<IStorageDataSource>();

  // ==========================================
  // MÉTODOS LEGACY (mantener compatibilidad)
  // ==========================================

  /// Sube imagen de producto público y retorna URL
  ///
  /// **Deprecado:** Usar `IStorageDataSource.uploadFile()` con DI
  @Deprecated('Usar IStorageDataSource.uploadFile() con DI')
  static Future<String> uploadProductImage(
    String productId,
    Uint8List fileBytes,
  ) async {
    final path = StoragePaths.publicProductImage(productId);
    return await _storage.uploadFile(
      path,
      fileBytes,
      metadata: {
        'contentType': 'image/jpeg',
        'uploaded_by': 'admin_panel',
      },
    );
  }

  /// Sube imagen de marca pública y retorna URL
  ///
  /// **Deprecado:** Usar `IStorageDataSource.uploadFile()` con DI
  @Deprecated('Usar IStorageDataSource.uploadFile() con DI')
  static Future<String> uploadBrandImage(
    String brandId,
    Uint8List fileBytes,
  ) async {
    final path = StoragePaths.publicBrandImage(brandId);
    return await _storage.uploadFile(
      path,
      fileBytes,
      metadata: {
        'contentType': 'image/jpeg',
        'uploaded_by': 'user',
      },
    );
  }

  /// Sube imagen de perfil de cuenta y retorna URL
  static Future<String> uploadAccountProfileImage(
    String accountId,
    Uint8List fileBytes,
  ) async {
    final path = StoragePaths.accountProfileImage(accountId);
    return await _storage.uploadFile(
      path,
      fileBytes,
      metadata: {'contentType': 'image/jpeg'},
    );
  }

  /// Elimina imagen de producto
  static Future<void> deleteProductImage(String productId) async {
    final path = StoragePaths.publicProductImage(productId);
    await _storage.deleteFile(path);
  }

  /// Elimina imagen de marca
  static Future<void> deleteBrandImage(String brandId) async {
    final path = StoragePaths.publicBrandImage(brandId);
    await _storage.deleteFile(path);
  }
}
