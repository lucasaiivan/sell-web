import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/repositories/i_cloud_print_repository.dart';

@LazySingleton(as: ICloudPrintRepository)
class CloudPrintRepositoryImpl implements ICloudPrintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<TicketModel>> getPrintQueue(String businessId) {
    return _firestore
        .collection('ACCOUNTS')
        .doc(businessId)
        .collection('PRINTING_RECEIPTS')
        .orderBy('creation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TicketModel.fromDocumentSnapshot(documentSnapshot: doc))
            .toList());
  }

  @override
  Future<void> enqueuePrintJob({
    required String businessId,
    required TicketModel job,
  }) async {
    await _firestore
        .collection('ACCOUNTS')
        .doc(businessId)
        .collection('PRINTING_RECEIPTS')
        .add(job.toMapOptimized());
  }

  @override
  Future<void> removePrintJob({
    required String businessId,
    required String jobId,
  }) async {
    await _firestore
        .collection('ACCOUNTS')
        .doc(businessId)
        .collection('PRINTING_RECEIPTS')
        .doc(jobId)
        .delete();
  }

  @override
  Future<void> clearPrintQueue({required String businessId}) async {
    // Utilizamos WriteBatch para eliminar todos los documentos atómicamente
    final collectionRef = _firestore
        .collection('ACCOUNTS')
        .doc(businessId)
        .collection('PRINTING_RECEIPTS');

    final snapshot = await collectionRef.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
