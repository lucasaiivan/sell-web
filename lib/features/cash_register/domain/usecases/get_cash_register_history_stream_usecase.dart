import 'package:injectable/injectable.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetCashRegisterHistoryStreamUseCase
class GetCashRegisterHistoryStreamParams {
  final String accountId;

  const GetCashRegisterHistoryStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream del historial de cajas
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real del historial de arqueos
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetCashRegisterHistoryStreamUseCase {
  final CashRegisterRepository _repository;

  GetCashRegisterHistoryStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream del historial
  ///
  /// Retorna Stream<List<CashRegister>> con el historial
  Stream<List<CashRegister>> call(GetCashRegisterHistoryStreamParams params) {
    return _repository.getCashRegisterHistoryStream(params.accountId);
  }
}
