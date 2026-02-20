import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/category.dart';

class CreateCategoryParams {
  final String accountId;
  final Category category;

  CreateCategoryParams({
    required this.accountId,
    required this.category,
  });
}

@injectable
class CreateCategoryUseCase {
  final CatalogueRepository repository;

  CreateCategoryUseCase(this.repository);

  Future<void> call(CreateCategoryParams params) async {
    return await repository.createCategory(
      accountId: params.accountId,
      name: params.category.name,
    );
  }
}
