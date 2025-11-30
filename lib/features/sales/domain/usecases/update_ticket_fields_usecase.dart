import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Actualiza campos específicos de un ticket preservando productos
///
/// RESPONSABILIDAD: Modificar metadatos del ticket sin alterar productos
/// - Validar valores (descuentos, montos no negativos)
/// - Preservar lista de productos
/// - Aplicar cambios selectivos
@lazySingleton
class UpdateTicketFieldsUseCase
    implements UseCase<TicketModel, UpdateTicketFieldsParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      UpdateTicketFieldsParams params) async {
    try {
      // Validaciones
      if (params.discount != null && params.discount! < 0) {
        return Left(ValidationFailure('El descuento no puede ser negativo'));
      }

      if (params.valueReceived != null && params.valueReceived! < 0) {
        return Left(
            ValidationFailure('El valor recibido no puede ser negativo'));
      }

      if (params.priceTotal != null && params.priceTotal! < 0) {
        return Left(ValidationFailure('El precio total no puede ser negativo'));
      }

      final newTicket = TicketModel(
        id: params.id ?? params.currentTicket.id,
        annulled: params.annulled ?? params.currentTicket.annulled,
        listPoduct: params.currentTicket.internalProductList
            .map((p) => Map<String, dynamic>.from(p))
            .toList(),
        creation: params.creation ?? params.currentTicket.creation,
        payMode: params.payMode ?? params.currentTicket.payMode,
        valueReceived:
            params.valueReceived ?? params.currentTicket.valueReceived,
        cashRegisterName:
            params.cashRegisterName ?? params.currentTicket.cashRegisterName,
        cashRegisterId:
            params.cashRegisterId ?? params.currentTicket.cashRegisterId,
        sellerName: params.sellerName ?? params.currentTicket.sellerName,
        sellerId: params.sellerId ?? params.currentTicket.sellerId,
        priceTotal: params.priceTotal ?? params.currentTicket.priceTotal,
        discount: params.discount ?? params.currentTicket.discount,
        discountIsPercentage: params.discountIsPercentage ??
            params.currentTicket.discountIsPercentage,
        transactionType:
            params.transactionType ?? params.currentTicket.transactionType,
        currencySymbol:
            params.currencySymbol ?? params.currentTicket.currencySymbol,
      );

      return Right(newTicket);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar ticket: $e'));
    }
  }
}

class UpdateTicketFieldsParams {
  final TicketModel currentTicket;
  final String? id;
  final Timestamp? creation;
  final bool? annulled;
  final String? payMode;
  final double? valueReceived;
  final String? cashRegisterName;
  final String? cashRegisterId;
  final String? sellerName;
  final String? sellerId;
  final double? priceTotal;
  final double? discount;
  final bool? discountIsPercentage;
  final String? transactionType;
  final String? currencySymbol;

  UpdateTicketFieldsParams({
    required this.currentTicket,
    this.id,
    this.creation,
    this.annulled,
    this.payMode,
    this.valueReceived,
    this.cashRegisterName,
    this.cashRegisterId,
    this.sellerName,
    this.sellerId,
    this.priceTotal,
    this.discount,
    this.discountIsPercentage,
    this.transactionType,
    this.currencySymbol,
  });
}
