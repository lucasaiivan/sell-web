import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/admin_profile.dart';

abstract class MultiUserRepository {
  Stream<Either<Failure, List<AdminProfile>>> getUsers(String accountId);
  Future<Either<Failure, void>> createUser(AdminProfile user, String accountId);
  Future<Either<Failure, void>> updateUser(AdminProfile user, String accountId);
  Future<Either<Failure, void>> deleteUser(AdminProfile user, String accountId);
}
