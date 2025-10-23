import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/account_repository.dart';
import '../core/services/storage/app_data_persistence_service.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDataPersistenceService _persistenceService =
      AppDataPersistenceService.instance;

  @override
  Future<List<AdminProfile>> getUserAccounts(String email) async {
    final ref =
        FirebaseFirestore.instance.collection('/USERS/$email/ACCOUNTS/');
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => AdminProfile.fromDocumentSnapshot(documentSnapshot: doc))
        .toList();
  }

  @override
  Future<AccountProfile?> getAccount(String accountId) async {
    final doc = await FirebaseFirestore.instance
        .collection('/ACCOUNTS')
        .doc(accountId)
        .get();
    if (!doc.exists) return null;
    return AccountProfile.fromDocumentSnapshot(documentSnapshot: doc);
  }

  @override
  Future<void> saveSelectedAccountId(String accountId) async {
    await _persistenceService.saveSelectedAccountId(accountId);
  }

  @override
  Future<String?> getSelectedAccountId() async {
    return await _persistenceService.getSelectedAccountId();
  }

  @override
  Future<void> removeSelectedAccountId() async {
    await _persistenceService.clearSelectedAccountId();
  }
}
