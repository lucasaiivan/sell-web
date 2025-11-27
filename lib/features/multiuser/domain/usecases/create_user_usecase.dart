import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../repositories/multi_user_repository.dart';

@lazySingleton
class CreateUserUseCase implements UseCase<void, CreateUserParams> {
  final MultiUserRepository repository;

  CreateUserUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateUserParams params) {
    return repository.createUser(params.user, params.accountId);
  }
}

class CreateUserParams {
  final AdminProfile user;
  final String accountId;

  CreateUserParams({required this.user, required this.accountId});
}
