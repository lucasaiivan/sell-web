import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/account_repository.dart';
import '../core/utils/shared_prefs_keys.dart';

class AccountRepositoryImpl implements AccountRepository {
  final SharedPreferences _prefs;

  AccountRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<AdminModel>> getUserAccounts(String email) async {
    final ref =
        FirebaseFirestore.instance.collection('/USERS/$email/ACCOUNTS/');
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => AdminModel.fromDocumentSnapshot(documentSnapshot: doc))
        .toList();
  }

  @override
  Future<ProfileAccountModel?> getAccount(String accountId) async {
    final doc = await FirebaseFirestore.instance
        .collection('/ACCOUNTS')
        .doc(accountId)
        .get();
    if (!doc.exists) return null;
    return ProfileAccountModel.fromDocumentSnapshot(documentSnapshot: doc);
  }

  @override
  Future<void> saveSelectedAccountId(String accountId) async {
    await _prefs.setString(SharedPrefsKeys.selectedAccountId, accountId);
  }

  @override
  Future<String?> getSelectedAccountId() async {
    return _prefs.getString(SharedPrefsKeys.selectedAccountId);
  }

  @override
  Future<void> removeSelectedAccountId() async {
    await _prefs.remove(SharedPrefsKeys.selectedAccountId);
  }
}
