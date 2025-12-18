import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/provider.dart';

class CreateProviderParams {
  final String accountId;
  final Provider provider;

  CreateProviderParams({
    required this.accountId,
    required this.provider,
  });
}

@injectable
class CreateProviderUseCase {
  final CatalogueRepository repository;

  CreateProviderUseCase(this.repository);

  Future<void> call(CreateProviderParams params) async {
    return await repository.createProvider(
      accountId: params.accountId,
      name: params.provider.name,
      phone: params.provider.phone,
      email: params.provider.email,
    );
  }
}
