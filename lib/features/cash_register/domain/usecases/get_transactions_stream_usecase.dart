import 'package:injectable/injectable.dart';
import '../repositories/cash_register_repository.dart';

/// Parámetros para GetTransactionsStreamUseCase
class GetTransactionsStreamParams {
  final String accountId;

  const GetTransactionsStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream de transacciones
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de transacciones de ventas
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetTransactionsStreamUseCase {
  final CashRegisterRepository _repository;

  GetTransactionsStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de transacciones
  ///
  /// Retorna Stream<List<Map<String, dynamic>>> con las transacciones
  Stream<List<Map<String, dynamic>>> call(GetTransactionsStreamParams params) {
    return _repository.getTransactionsStream(params.accountId);
  }
}
