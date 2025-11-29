import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'i_firestore_datasource.dart';

/// Implementación de Firestore DataSource
/// 
/// **Responsabilidad:**
/// - Wrapper type-safe de FirebaseFirestore
/// - Implementa contrato [IFirestoreDataSource]
/// - Maneja errores de Firebase en capa de datos
/// 
/// **Inyección DI:** @LazySingleton (registrado como interfaz)
@LazySingleton(as: IFirestoreDataSource)
class FirestoreDataSource implements IFirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource(this._firestore);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  @override
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments(
    Query<Map<String, dynamic>> query, {
    Source source = Source.serverAndCache,
  }) async {
    return await query.get(GetOptions(source: source));
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDocuments(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(String path) {
    return _firestore.collection(path).snapshots();
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  @override
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _firestore.doc(path).update(data);
  }

  @override
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  @override
  Future<void> batchWrite(
    List<({String path, Map<String, dynamic> data, String operation})>
        operations,
  ) async {
    final batch = _firestore.batch();

    for (final op in operations) {
      final docRef = _firestore.doc(op.path);

      switch (op.operation) {
        case 'set':
          batch.set(docRef, op.data);
          break;
        case 'update':
          batch.update(docRef, op.data);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }

  @override
  Future<void> incrementField(
    String path,
    String field,
    num value,
  ) async {
    await _firestore.doc(path).update({
      field: FieldValue.increment(value),
    });
  }

  @override
  Future<void> clearPersistence() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      // Solo funciona cuando no hay listeners activos
      throw Exception(
        'No se puede limpiar la persistencia mientras hay listeners activos. '
        'Cierra todas las conexiones primero. Error: $e',
      );
    }
  }
}
