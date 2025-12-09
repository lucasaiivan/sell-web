import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/core/utils/helpers/uid_helper.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Crea un producto rápido (sin código de barras) para venta inmediata
///
/// RESPONSABILIDAD: Crear producto temporal sin catalogación
/// - Validar precio no negativo
/// - Generar ID único
/// - Establecer valores por defecto
/// - No requiere código de barras
@lazySingleton
class CreateQuickProductUseCase
    implements UseCase<ProductCatalogue, CreateQuickProductParams> {
  @override
  Future<Either<Failure, ProductCatalogue>> call(
      CreateQuickProductParams params) async {
    try {
      if (params.salePrice < 0) {
        return Left(
            ValidationFailure('El precio de venta no puede ser negativo'));
      }

      return Right(ProductCatalogue(
        id: UidHelper.generateUid(),
        description: params.description,
        salePrice: params.salePrice,
        code: '', // Productos rápidos no tienen código
        quantity: 1,
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al crear producto rápido: $e'));
    }
  }
}

class CreateQuickProductParams {
  final String description;
  final double salePrice;

  CreateQuickProductParams({
    required this.description,
    required this.salePrice,
  });
}
