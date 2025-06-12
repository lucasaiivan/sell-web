import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<AdminModel>> getUserAccounts(String email) async {
    final ref = FirebaseFirestore.instance.collection('/USERS/$email/ACCOUNTS/');
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => AdminModel.fromDocumentSnapshot(documentSnapshot: doc))
        .toList();
  }

  @override
  Future<ProfileAccountModel?> getAccount(String accountId) async {
    final doc = await FirebaseFirestore.instance.collection('/ACCOUNTS').doc(accountId).get();
    if (!doc.exists) return null;
    return ProfileAccountModel.fromDocumentSnapshot(documentSnapshot: doc);
  }
}
