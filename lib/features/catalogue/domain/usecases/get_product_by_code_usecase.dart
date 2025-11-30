import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_catalogue.dart';

/// Parámetros para GetProductByCodeUseCase
class GetProductByCodeParams {
  final List<ProductCatalogue> products;
  final String code;

  const GetProductByCodeParams({
    required this.products,
    required this.code,
  });
}

/// Caso de uso: Buscar producto por código en lista
///
/// **Responsabilidad:**
/// - Busca un producto por código de barra en una lista en memoria
/// - No accede al repositorio, opera sobre datos ya cargados
@lazySingleton
class GetProductByCodeUseCase
    extends UseCase<ProductCatalogue?, GetProductByCodeParams> {
  GetProductByCodeUseCase();

  /// Ejecuta la búsqueda del producto por código
  ///
  /// Retorna [Right(ProductCatalogue?)] con el producto o null si no existe,
  /// [Left(Failure)] si falla
  @override
  Future<Either<Failure, ProductCatalogue?>> call(
      GetProductByCodeParams params) async {
    try {
      final product = params.products.firstWhere((p) => p.code == params.code);
      return Right(product);
    } catch (_) {
      return const Right(null);
    }
  }
}
