import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/database/database_cloud.dart';
import '../../../auth/data/models/admin_profile_model.dart';
import '../../../auth/domain/entities/admin_profile.dart';

abstract class MultiUserRemoteDataSource {
  Stream<List<AdminProfileModel>> getUsers(String accountId);
  Future<void> createUser(AdminProfile user, String accountId);
  Future<void> updateUser(AdminProfile user, String accountId);
  Future<void> deleteUser(AdminProfile user, String accountId);
}

@LazySingleton(as: MultiUserRemoteDataSource)
class MultiUserRemoteDataSourceImpl implements MultiUserRemoteDataSource {
  @override
  Stream<List<AdminProfileModel>> getUsers(String accountId) {
    return DatabaseCloudService.accountUsersStream(accountId).map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminProfileModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Future<void> createUser(AdminProfile user, String accountId) async {
    final userModel = AdminProfileModel.fromEntity(user);
    final userJson = userModel.toJson();

    // Reference to the user in the account's users list
    final accountUserRef =
        DatabaseCloudService.accountUsers(accountId).doc(user.email);

    // Reference to the account in the user's managed accounts list
    final userAccountRef =
        DatabaseCloudService.userManagedAccounts(user.email).doc(accountId);

    final batch = FirebaseFirestore.instance.batch();

    batch.set(accountUserRef, userJson);
    batch.set(userAccountRef, userJson);

    await batch.commit();
  }

  @override
  Future<void> updateUser(AdminProfile user, String accountId) async {
    final userModel = AdminProfileModel.fromEntity(user);
    final userJson = userModel.toJson();

    // Reference to the user in the account's users list
    final accountUserRef =
        DatabaseCloudService.accountUsers(accountId).doc(user.email);

    // Reference to the account in the user's managed accounts list
    final userAccountRef =
        DatabaseCloudService.userManagedAccounts(user.email).doc(accountId);

    final batch = FirebaseFirestore.instance.batch();

    batch.update(accountUserRef, userJson);
    batch.update(userAccountRef, userJson);

    await batch.commit();
  }

  @override
  Future<void> deleteUser(AdminProfile user, String accountId) async {
    // Reference to the user in the account's users list
    final accountUserRef =
        DatabaseCloudService.accountUsers(accountId).doc(user.email);

    // Reference to the account in the user's managed accounts list
    final userAccountRef =
        DatabaseCloudService.userManagedAccounts(user.email).doc(accountId);

    final batch = FirebaseFirestore.instance.batch();

    batch.delete(accountUserRef);
    batch.delete(userAccountRef);

    await batch.commit();
  }
}
