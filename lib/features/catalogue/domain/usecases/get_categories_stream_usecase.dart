import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/category.dart';

/// Parámetros para GetCategoriesStreamUseCase
class GetCategoriesStreamParams {
  final String accountId;

  const GetCategoriesStreamParams(this.accountId);
}

/// Caso de uso: Obtener stream de categorías
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de las categorías
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetCategoriesStreamUseCase {
  final CatalogueRepository _repository;

  GetCategoriesStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de categorías
  ///
  /// Retorna Stream<List<Category>> con las categorías
  Stream<List<Category>> call(GetCategoriesStreamParams params) {
    return _repository.getCategoriesStream(params.accountId);
  }
}
