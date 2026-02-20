import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/category.dart';

class UpdateCategoryParams {
  final String accountId;
  final Category category;

  UpdateCategoryParams({
    required this.accountId,
    required this.category,
  });
}

@injectable
class UpdateCategoryUseCase {
  final CatalogueRepository repository;

  UpdateCategoryUseCase(this.repository);

  Future<void> call(UpdateCategoryParams params) async {
    return await repository.updateCategory(
      accountId: params.accountId,
      categoryId: params.category.id,
      name: params.category.name,
    );
  }
}
