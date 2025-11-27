import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'i_storage_datasource.dart';

/// Implementación de Storage DataSource
/// 
/// **Responsabilidad:**
/// - Wrapper type-safe de FirebaseStorage
/// - Implementa contrato [IStorageDataSource]
/// - Maneja errores de Firebase Storage en capa de datos
/// 
/// **Inyección DI:** @LazySingleton
@LazySingleton(as: IStorageDataSource)
class StorageDataSource implements IStorageDataSource {
  final FirebaseStorage _storage;

  StorageDataSource(this._storage);

  @override
  Future<String> uploadFile(
    String path,
    Uint8List fileBytes, {
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref(path);
      
      // Configurar metadata si existe
      SettableMetadata? uploadMetadata;
      if (metadata != null) {
        uploadMetadata = SettableMetadata(
          contentType: metadata['contentType'],
          customMetadata: metadata,
        );
      }

      // Subir archivo
      final uploadTask = metadata != null
          ? ref.putData(fileBytes, uploadMetadata!)
          : ref.putData(fileBytes);

      final snapshot = await uploadTask;
      
      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir archivo a Storage: $e');
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.delete();
    } catch (e) {
      throw Exception('Error al eliminar archivo de Storage: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al obtener URL de descarga: $e');
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    } catch (e) {
      throw Exception('Error al verificar existencia de archivo: $e');
    }
  }
}
