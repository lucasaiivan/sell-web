import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';

/// Parámetros para UpdateSalesAndBillingUseCase
class UpdateSalesAndBillingParams {
  final String accountId;
  final String cashRegisterId;
  final double billingIncrement;
  final double discountIncrement;

  const UpdateSalesAndBillingParams({
    required this.accountId,
    required this.cashRegisterId,
    required this.billingIncrement,
    required this.discountIncrement,
  });
}

/// Caso de uso: Actualizar ventas y facturación
///
/// **Responsabilidad:**
/// - Actualiza los totales de ventas y facturación en la caja
/// - ⚠️ SOLO para ventas efectivas (incrementa contador de ventas)
/// - Valida que los montos no sean negativos
/// - Delega la operación al repositorio
@lazySingleton
class UpdateSalesAndBillingUseCase
    extends UseCase<void, UpdateSalesAndBillingParams> {
  final CashRegisterRepository _repository;

  UpdateSalesAndBillingUseCase(this._repository);

  /// Ejecuta la actualización de ventas y facturación
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(UpdateSalesAndBillingParams params) async {
    // Validaciones de negocio
    if (params.billingIncrement < 0) {
      return Left(ValidationFailure(
          'El incremento de facturación no puede ser negativo'));
    }

    if (params.discountIncrement < 0) {
      return Left(ValidationFailure(
          'El incremento de descuento no puede ser negativo'));
    }

    try {
      await _repository.updateSalesAndBilling(
        accountId: params.accountId,
        cashRegisterId: params.cashRegisterId,
        billingIncrement: params.billingIncrement,
        discountIncrement: params.discountIncrement,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar ventas: ${e.toString()}'));
    }
  }
}
