import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/provider.dart';

class UpdateProviderParams {
  final String accountId;
  final Provider provider;

  UpdateProviderParams({
    required this.accountId,
    required this.provider,
  });
}

@injectable
class UpdateProviderUseCase {
  final CatalogueRepository repository;

  UpdateProviderUseCase(this.repository);

  Future<void> call(UpdateProviderParams params) async {
    return await repository.updateProvider(
      accountId: params.accountId,
      providerId: params.provider.id,
      name: params.provider.name,
      phone: params.provider.phone,
      email: params.provider.email,
    );
  }
}
