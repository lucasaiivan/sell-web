import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product_price.dart';

/// Parámetros para RegisterProductPriceUseCase
class RegisterProductPriceParams {
  final ProductPrice productPrice;
  final String productCode;

  const RegisterProductPriceParams({
    required this.productPrice,
    required this.productCode,
  });
}

/// Caso de uso: Registrar precio de producto
///
/// **Responsabilidad:**
/// - Registra el precio de un producto en la base de datos pública
/// - Delega la operación al repositorio
@lazySingleton
class RegisterProductPriceUseCase extends UseCase<void, RegisterProductPriceParams> {
  final CatalogueRepository _repository;

  RegisterProductPriceUseCase(this._repository);

  /// Ejecuta el registro del precio del producto
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(RegisterProductPriceParams params) async {
    try {
      await _repository.registerProductPrice(params.productPrice, params.productCode);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al registrar precio del producto: ${e.toString()}'));
    }
  }
}
