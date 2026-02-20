import 'package:injectable/injectable.dart';
import '../entities/mark.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para GetBrandByIdUseCase
class GetBrandByIdParams {
  final String id;
  final String country;

  const GetBrandByIdParams({
    required this.id,
    this.country = 'ARG',
  });
}

/// UseCase para obtener una marca específica por ID
///
/// **Uso:**
/// ```dart
/// final result = await getBrandByIdUseCase(
///   GetBrandByIdParams(id: 'brand-123'),
/// );
/// ```
@injectable
class GetBrandByIdUseCase {
  final CatalogueRepository _repository;

  GetBrandByIdUseCase(this._repository);

  /// Ejecuta la obtención de marca por ID
  ///
  /// Retorna `null` si la marca no existe.
  Future<Mark?> call(GetBrandByIdParams params) {
    return _repository.getBrandById(params.id, country: params.country);
  }
}
