import 'package:injectable/injectable.dart';
import '../entities/mark.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para SearchBrandsUseCase
class SearchBrandsParams {
  final String query;
  final String country;
  final int limit;

  const SearchBrandsParams({
    required this.query,
    this.country = 'ARG',
    this.limit = 20,
  });
}

/// UseCase para buscar marcas por nombre con paginación
///
/// Implementa búsqueda optimizada por prefijo en Firestore.
/// Solo retorna marcas que comienzan con el término de búsqueda.
///
/// **Uso:**
/// ```dart
/// final result = await searchBrandsUseCase(
///   SearchBrandsParams(query: 'Coca', limit: 20),
/// );
/// ```
@injectable
class SearchBrandsUseCase {
  final CatalogueRepository _repository;

  SearchBrandsUseCase(this._repository);

  /// Ejecuta la búsqueda de marcas
  ///
  /// Retorna lista vacía si [query] está vacío o tiene menos de 1 carácter.
  Future<List<Mark>> call(SearchBrandsParams params) {
    if (params.query.isEmpty) {
      return Future.value([]);
    }

    return _repository.searchBrands(
      query: params.query,
      country: params.country,
      limit: params.limit,
    );
  }
}
