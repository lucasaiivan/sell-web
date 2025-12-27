import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_catalogue.dart';

/// Parámetros para GetDemoProductsUseCase
class GetDemoProductsParams {
  final int count;

  const GetDemoProductsParams({this.count = 30});
}

/// Caso de uso: Obtener productos demo
///
/// **Responsabilidad:**
/// - Genera una lista de productos de prueba para la cuenta demo
@lazySingleton
class GetDemoProductsUseCase
    extends UseCase<List<ProductCatalogue>, GetDemoProductsParams> {
  GetDemoProductsUseCase();

  /// Ejecuta la generación de productos demo
  ///
  /// Retorna [Right(List<ProductCatalogue>)] con los productos demo
  @override
  Future<Either<Failure, List<ProductCatalogue>>> call(
      GetDemoProductsParams params) async {
    try {
      final products = List.generate(
        params.count,
        (i) => ProductCatalogue(
          id: 'demo_product_${i + 1}',
          nameMark: 'Marca Demo',
          image: '',
          description: 'Producto de prueba #${i + 1}',
          code: 'DEMO${(i + 1).toString().padLeft(3, '0')}',
          salePrice: 10.0 + i,
          quantityStock: (100 - i).toDouble(),
          stock: true,
          alertStock: 10.0,
          currencySign: '24',
          creation: DateTime.now(),
          upgrade: DateTime.now(),
          documentCreation: DateTime.now(),
          documentUpgrade: DateTime.now(),
        ),
      );

      return Right(products);
    } catch (e) {
      return Left(
          ServerFailure('Error al generar productos demo: ${e.toString()}'));
    }
  }
}
