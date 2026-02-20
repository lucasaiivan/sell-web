import 'package:injectable/injectable.dart';
import '../../../../core/services/database/firestore_paths.dart';
import '../../../../core/services/database/i_firestore_datasource.dart';
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
  final IFirestoreDataSource _dataSource;

  const MultiUserRemoteDataSourceImpl(this._dataSource);

  @override
  Stream<List<AdminProfileModel>> getUsers(String accountId) {
    return _dataSource
        .collectionStream(FirestorePaths.accountUsers(accountId))
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminProfileModel.fromDocument(doc))
          .toList();
    });
  }

  @override
  Future<void> createUser(AdminProfile user, String accountId) async {
    final userModel = AdminProfileModel.fromEntity(user);
    final userJson = userModel.toJson();

    // Create user in both account users and user managed accounts atomically
    await _dataSource.batchWrite([
      (
        path: FirestorePaths.accountUser(accountId, user.email),
        data: userJson,
        operation: 'set',
      ),
      (
        path: FirestorePaths.userManagedAccount(user.email, accountId),
        data: userJson,
        operation: 'set',
      ),
    ]);
  }

  @override
  Future<void> updateUser(AdminProfile user, String accountId) async {
    final userModel = AdminProfileModel.fromEntity(user);
    final userJson = userModel.toJson();

    // Update user in both account users and user managed accounts atomically
    await _dataSource.batchWrite([
      (
        path: FirestorePaths.accountUser(accountId, user.email),
        data: userJson,
        operation: 'update',
      ),
      (
        path: FirestorePaths.userManagedAccount(user.email, accountId),
        data: userJson,
        operation: 'update',
      ),
    ]);
  }

  @override
  Future<void> deleteUser(AdminProfile user, String accountId) async {
    // Delete user from both account users and user managed accounts atomically
    await _dataSource.batchWrite([
      (
        path: FirestorePaths.accountUser(accountId, user.email),
        data: {}, // No data needed for delete operation
        operation: 'delete',
      ),
      (
        path: FirestorePaths.userManagedAccount(user.email, accountId),
        data: {}, // No data needed for delete operation
        operation: 'delete',
      ),
    ]);
  }
}
