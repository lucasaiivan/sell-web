import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/provider.dart';

/// Parámetros para GetProvidersStreamUseCase
class GetProvidersStreamParams {
  final String accountId;

  const GetProvidersStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream de proveedores
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de los proveedores
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetProvidersStreamUseCase {
  final CatalogueRepository _repository;

  GetProvidersStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de proveedores
  ///
  /// Retorna Stream<List<Provider>> con los proveedores
  Stream<List<Provider>> call(GetProvidersStreamParams params) {
    return _repository.getProvidersStream(params.accountId);
  }
}
