import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'i_firestore_datasource.dart';
import '../../services/monitoring/query_counter_service.dart';

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
  final QueryCounterService _queryCounter;

  FirestoreDataSource(this._firestore, this._queryCounter);

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
    final snapshot = await query.get(GetOptions(source: source));
    
    // Contar lecturas solo si no vienen de caché
    if (!snapshot.metadata.isFromCache) {
      _queryCounter.incrementReads(snapshot.docs.length);
    }
    
    return snapshot;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDocuments(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map((snapshot) {
      // En streams, contar solo cambios si no es de caché
      // Nota: La primera emisión trae todos los docs como 'added'
       if (!snapshot.metadata.isFromCache) {
        // En teoría deberíamos contar solo docChanges para actualizaciones
        // pero para simplificar y ser conservadores con el costo estimado:
        _queryCounter.incrementReads(snapshot.docChanges.length);
      }
      return snapshot;
    });
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream(String path) {
    return streamDocuments(_firestore.collection(path));
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
    _queryCounter.incrementWrites(1);
  }

  @override
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    await _firestore.doc(path).update(data);
    _queryCounter.incrementWrites(1);
  }

  @override
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
    _queryCounter.incrementWrites(1);
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
    _queryCounter.incrementWrites(operations.length);
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
    _queryCounter.incrementWrites(1);
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
