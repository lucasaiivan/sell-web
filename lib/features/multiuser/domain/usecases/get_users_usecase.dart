import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../repositories/multi_user_repository.dart';

@lazySingleton
class GetUsersUseCase implements StreamUseCase<List<AdminProfile>, String> {
  final MultiUserRepository repository;

  GetUsersUseCase(this.repository);

  @override
  Stream<Either<Failure, List<AdminProfile>>> call(String params) {
    return repository.getUsers(params);
  }
}
