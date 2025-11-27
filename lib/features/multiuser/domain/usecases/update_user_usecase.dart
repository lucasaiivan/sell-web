import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../repositories/multi_user_repository.dart';

@lazySingleton
class UpdateUserUseCase implements UseCase<void, UpdateUserParams> {
  final MultiUserRepository repository;

  UpdateUserUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserParams params) {
    return repository.updateUser(params.user, params.accountId);
  }
}

class UpdateUserParams {
  final AdminProfile user;
  final String accountId;

  UpdateUserParams({required this.user, required this.accountId});
}
