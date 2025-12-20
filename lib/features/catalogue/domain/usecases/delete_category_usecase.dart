import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';

class DeleteCategoryParams {
  final String accountId;
  final String categoryId;

  DeleteCategoryParams({
    required this.accountId,
    required this.categoryId,
  });
}

@injectable
class DeleteCategoryUseCase {
  final CatalogueRepository repository;

  DeleteCategoryUseCase(this.repository);

  Future<void> call(DeleteCategoryParams params) async {
    return await repository.deleteCategory(
      accountId: params.accountId,
      categoryId: params.categoryId,
    );
  }
}
