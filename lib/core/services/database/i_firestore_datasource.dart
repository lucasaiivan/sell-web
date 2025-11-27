import 'package:cloud_firestore/cloud_firestore.dart';

/// Contrato para operaciones de base de datos
/// 
/// **Patrón:** Repository Pattern con abstracción de Firestore
/// **Beneficio:** Testeable, mockeable, intercambiable
/// 
/// Define operaciones CRUD genéricas sin acoplar a Firebase.
/// Permite implementar con Firestore, mock local, o cualquier backend.
abstract interface class IFirestoreDataSource {
  /// Obtiene una referencia a colección
  CollectionReference<Map<String, dynamic>> collection(String path);

  /// Obtiene un documento por path completo
  DocumentReference<Map<String, dynamic>> document(String path);

  /// Obtiene documentos de una query
  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments(
    Query<Map<String, dynamic>> query,
  );

  /// Stream de documentos de una query
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDocuments(
    Query<Map<String, dynamic>> query,
  );

  /// Stream de una colección completa
  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(String path);

  /// Crea o actualiza un documento
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  });

  /// Actualiza campos específicos de un documento
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  );

  /// Elimina un documento
  Future<void> deleteDocument(String path);

  /// Operación de batch (transaccional)
  Future<void> batchWrite(
    List<({String path, Map<String, dynamic> data, String operation})> operations,
  );

  /// Incrementa un campo numérico
  Future<void> incrementField(
    String path,
    String field,
    num value,
  );
}
