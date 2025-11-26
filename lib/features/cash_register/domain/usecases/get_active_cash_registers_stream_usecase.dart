import 'package:injectable/injectable.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetActiveCashRegistersStreamUseCase
class GetActiveCashRegistersStreamParams {
  final String accountId;

  const GetActiveCashRegistersStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream de cajas activas
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de las cajas activas
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetActiveCashRegistersStreamUseCase {
  final CashRegisterRepository _repository;

  GetActiveCashRegistersStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de cajas activas
  ///
  /// Retorna Stream<List<CashRegister>> con las cajas activas
  Stream<List<CashRegister>> call(GetActiveCashRegistersStreamParams params) {
    return _repository.getActiveCashRegistersStream(params.accountId);
  }
}
