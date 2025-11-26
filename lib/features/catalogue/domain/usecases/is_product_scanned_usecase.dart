import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_catalogue.dart';
import 'get_product_by_code_usecase.dart';

/// Parámetros para IsProductScannedUseCase
class IsProductScannedParams {
  final List<ProductCatalogue> products;
  final String code;

  const IsProductScannedParams({
    required this.products,
    required this.code,
  });
}

/// Caso de uso: Verificar si producto fue escaneado
///
/// **Responsabilidad:**
/// - Verifica si un producto existe en la lista (ya fue escaneado)
/// - Coordina con GetProductByCodeUseCase
@lazySingleton
class IsProductScannedUseCase extends UseCase<bool, IsProductScannedParams> {
  final GetProductByCodeUseCase _getProductByCodeUseCase;

  IsProductScannedUseCase(this._getProductByCodeUseCase);

  /// Ejecuta la verificación del producto
  ///
  /// Retorna [Right(bool)] indicando si el producto existe,
  /// [Left(Failure)] si falla
  @override
  Future<Either<Failure, bool>> call(IsProductScannedParams params) async {
    final result = await _getProductByCodeUseCase(
      GetProductByCodeParams(products: params.products, code: params.code),
    );

    return result.fold(
      (failure) => Left(failure),
      (product) => Right(product != null),
    );
  }
}
