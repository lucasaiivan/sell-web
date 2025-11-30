import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Agrega un producto al ticket (incrementa cantidad si ya existe)
///
/// RESPONSABILIDAD: Gestionar productos en ticket temporal
/// - Validar producto (ID válido, precio no negativo)
/// - Incrementar cantidad si ya existe
/// - Agregar nuevo producto si no existe
/// - Opcionalmente reemplazar cantidad existente
@lazySingleton
class AddProductToTicketUseCase
    implements UseCase<TicketModel, AddProductToTicketParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      AddProductToTicketParams params) async {
    try {
      // Validaciones
      if (params.product.id.isEmpty) {
        return Left(ValidationFailure('El producto debe tener un ID válido'));
      }

      if (params.product.salePrice < 0) {
        return Left(
            ValidationFailure('El precio de venta no puede ser negativo'));
      }

      bool productExists = false;
      final List<ProductCatalogue> updatedProducts =
          List.from(params.currentTicket.products);

      for (var i = 0; i < updatedProducts.length; i++) {
        if (updatedProducts[i].id == params.product.id) {
          productExists = true;

          if (params.replaceQuantity) {
            final quantityToUse = params.product.quantity > 0
                ? params.product.quantity
                : updatedProducts[i].quantity;
            updatedProducts[i] =
                params.product.copyWith(quantity: quantityToUse);
          } else {
            final newQuantity = updatedProducts[i].quantity +
                (params.product.quantity > 0 ? params.product.quantity : 1);
            updatedProducts[i] =
                updatedProducts[i].copyWith(quantity: newQuantity);
          }
          break;
        }
      }

      if (!productExists) {
        final quantityToAdd =
            params.product.quantity > 0 ? params.product.quantity : 1;
        updatedProducts.add(params.product.copyWith(quantity: quantityToAdd));
      }

      final newTicket = params.currentTicket.copyWith();
      newTicket.products = updatedProducts;

      return Right(newTicket);
    } catch (e) {
      return Left(ServerFailure('Error al agregar producto: $e'));
    }
  }
}

class AddProductToTicketParams {
  final TicketModel currentTicket;
  final ProductCatalogue product;
  final bool replaceQuantity;

  AddProductToTicketParams({
    required this.currentTicket,
    required this.product,
    this.replaceQuantity = false,
  });
}
