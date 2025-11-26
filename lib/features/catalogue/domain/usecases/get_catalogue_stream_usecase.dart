import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para GetCatalogueStreamUseCase
class GetCatalogueStreamParams {
  final String accountId;

  const GetCatalogueStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream de productos del catálogo
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de los productos del catálogo
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetCatalogueStreamUseCase {
  final CatalogueRepository _repository;

  GetCatalogueStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de catálogo
  ///
  /// Retorna Stream<QuerySnapshot> de Firestore con los productos
  Stream<QuerySnapshot> call(GetCatalogueStreamParams params) {
    return _repository.getCatalogueStream(params.accountId);
  }
}
