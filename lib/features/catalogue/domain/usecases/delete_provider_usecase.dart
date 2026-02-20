import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';

class DeleteProviderParams {
  final String accountId;
  final String providerId;

  DeleteProviderParams({
    required this.accountId,
    required this.providerId,
  });
}

@injectable
class DeleteProviderUseCase {
  final CatalogueRepository repository;

  DeleteProviderUseCase(this.repository);

  Future<void> call(DeleteProviderParams params) async {
    return await repository.deleteProvider(
      accountId: params.accountId,
      providerId: params.providerId,
    );
  }
}
