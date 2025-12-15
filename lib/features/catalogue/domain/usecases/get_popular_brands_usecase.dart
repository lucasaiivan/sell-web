import 'package:injectable/injectable.dart';
import '../entities/mark.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para GetPopularBrandsUseCase
class GetPopularBrandsParams {
  final String country;
  final int limit;

  const GetPopularBrandsParams({
    this.country = 'ARG',
    this.limit = 20,
  });
}

/// UseCase para obtener las marcas más populares (verificadas y recientes)
///
/// Retorna marcas verificadas ordenadas por fecha de creación.
/// Útil para mostrar opciones iniciales sin necesidad de búsqueda.
///
/// **Uso:**
/// ```dart
/// final result = await getPopularBrandsUseCase(
///   const GetPopularBrandsParams(limit: 20),
/// );
/// ```
@injectable
class GetPopularBrandsUseCase {
  final CatalogueRepository _repository;

  GetPopularBrandsUseCase(this._repository);

  /// Ejecuta la obtención de marcas populares
  Future<List<Mark>> call(GetPopularBrandsParams params) {
    return _repository.getPopularBrands(
      country: params.country,
      limit: params.limit,
    );
  }
}
