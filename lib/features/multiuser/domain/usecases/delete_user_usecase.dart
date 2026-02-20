import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../repositories/multi_user_repository.dart';

@lazySingleton
class DeleteUserUseCase implements UseCase<void, DeleteUserParams> {
  final MultiUserRepository repository;

  DeleteUserUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserParams params) {
    return repository.deleteUser(params.user, params.accountId);
  }
}

class DeleteUserParams {
  final AdminProfile user;
  final String accountId;

  DeleteUserParams({required this.user, required this.accountId});
}
