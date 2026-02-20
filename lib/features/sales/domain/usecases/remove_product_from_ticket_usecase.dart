import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Elimina un producto del ticket
///
/// RESPONSABILIDAD: Remover producto de ticket temporal
/// - Validar ID de producto
/// - Filtrar producto de la lista
@lazySingleton
class RemoveProductFromTicketUseCase
    implements UseCase<TicketModel, RemoveProductFromTicketParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      RemoveProductFromTicketParams params) async {
    try {
      if (params.product.id.isEmpty) {
        return Left(ValidationFailure('El producto debe tener un ID válido'));
      }

      final updatedProducts = params.currentTicket.products
          .where((item) => item.id != params.product.id)
          .toList();

      final newTicket = params.currentTicket.copyWith();
      newTicket.products = updatedProducts;

      return Right(newTicket);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar producto: $e'));
    }
  }
}

class RemoveProductFromTicketParams {
  final TicketModel currentTicket;
  final ProductCatalogue product;

  RemoveProductFromTicketParams({
    required this.currentTicket,
    required this.product,
  });
}
