import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/mark.dart';

/// Parámetros para GetBrandsStreamUseCase
class GetBrandsStreamParams {
  final String country;

  const GetBrandsStreamParams({this.country = 'ARG'});
}

/// Caso de uso: Obtener stream de marcas
///
/// **Responsabilidad:**
/// - Proporciona un stream en tiempo real de las marcas públicas
/// - Delega la operación al repositorio
///
/// **Nota:** Este es un caso especial que retorna Stream en vez de Future<Either>
/// porque necesita emitir cambios en tiempo real desde Firestore
@lazySingleton
class GetBrandsStreamUseCase {
  final CatalogueRepository _repository;

  GetBrandsStreamUseCase(this._repository);

  /// Ejecuta la obtención del stream de marcas
  ///
  /// Retorna Stream<List<Mark>> con las marcas
  Stream<List<Mark>> call(GetBrandsStreamParams params) {
    return _repository.getBrandsStream(country: params.country);
  }
}
