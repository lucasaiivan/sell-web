import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';

/// Parámetros para UpdateBillingOnAnnullmentUseCase
class UpdateBillingOnAnnullmentParams {
  final String accountId;
  final String cashRegisterId;
  final double billingDecrement;
  final double discountDecrement;

  const UpdateBillingOnAnnullmentParams({
    required this.accountId,
    required this.cashRegisterId,
    required this.billingDecrement,
    required this.discountDecrement,
  });
}

/// Caso de uso: Actualizar facturación por anulación
///
/// **Responsabilidad:**
/// - Actualiza billing y discount al anular un ticket
/// - Incrementa contador de tickets anulados
/// - NO modifica el contador de ventas efectivas
/// - Valida que los montos no sean negativos
/// - Delega la operación al repositorio
@lazySingleton
class UpdateBillingOnAnnullmentUseCase
    extends UseCase<void, UpdateBillingOnAnnullmentParams> {
  final CashRegisterRepository _repository;

  UpdateBillingOnAnnullmentUseCase(this._repository);

  /// Ejecuta la actualización por anulación
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(
      UpdateBillingOnAnnullmentParams params) async {
    // Validaciones de negocio
    if (params.billingDecrement < 0) {
      return Left(ValidationFailure(
          'El decremento de facturación no puede ser negativo'));
    }

    if (params.discountDecrement < 0) {
      return Left(ValidationFailure(
          'El decremento de descuento no puede ser negativo'));
    }

    try {
      await _repository.updateBillingOnAnnullment(
        accountId: params.accountId,
        cashRegisterId: params.cashRegisterId,
        billingDecrement: params.billingDecrement,
        discountDecrement: params.discountDecrement,
      );
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al actualizar anulación: ${e.toString()}'));
    }
  }
}
