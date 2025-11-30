import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product_catalogue.dart';

/// Parámetros para AddProductToCatalogueUseCase
class AddProductToCatalogueParams {
  final ProductCatalogue product;
  final String accountId;

  const AddProductToCatalogueParams({
    required this.product,
    required this.accountId,
  });
}

/// Caso de uso: Agregar producto al catálogo
///
/// **Responsabilidad:**
/// - Agrega un producto al catálogo de la cuenta del negocio
/// - Delega la operación al repositorio
@lazySingleton
class AddProductToCatalogueUseCase
    extends UseCase<void, AddProductToCatalogueParams> {
  final CatalogueRepository _repository;

  AddProductToCatalogueUseCase(this._repository);

  /// Ejecuta la adición del producto al catálogo
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(AddProductToCatalogueParams params) async {
    try {
      await _repository.addProductToCatalogue(params.product, params.accountId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          'Error al agregar producto al catálogo: ${e.toString()}'));
    }
  }
}
