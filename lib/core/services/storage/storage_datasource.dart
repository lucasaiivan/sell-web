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

  @override
  Future<void> deleteFolder(String folderPath) async {
    try {
      final ref = _storage.ref(folderPath);
      
      // Listar todos los archivos en la carpeta
      final listResult = await ref.listAll();
      
      // Eliminar todos los archivos (items)
      for (final item in listResult.items) {
        try {
          await item.delete();
        } catch (e) {
          // Continuar aunque falle la eliminación de un archivo individual
          print('⚠️ Error eliminando ${item.fullPath}: $e');
        }
      }
      
      // Eliminar recursivamente todas las subcarpetas (prefixes)
      for (final prefix in listResult.prefixes) {
        try {
          await deleteFolder(prefix.fullPath);
        } catch (e) {
          // Continuar aunque falle la eliminación de una subcarpeta
          print('⚠️ Error eliminando subcarpeta ${prefix.fullPath}: $e');
        }
      }
    } on FirebaseException catch (e) {
      // Si la carpeta no existe, no es un error
      if (e.code == 'object-not-found') {
        return;
      }
      throw Exception('Error al eliminar carpeta de Storage: $e');
    } catch (e) {
      throw Exception('Error al eliminar carpeta de Storage: $e');
    }
  }
}
