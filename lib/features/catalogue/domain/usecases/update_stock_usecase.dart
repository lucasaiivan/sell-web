import 'package:injectable/injectable.dart';
import '../repositories/catalogue_repository.dart';

/// Caso de uso para actualizar el stock de un producto.
/// 
/// Encapsula la lógica de negocio y validaciones para
/// modificar la cantidad en stock.
@lazySingleton
class UpdateStockUseCase {
  final CatalogueRepository repository;

  UpdateStockUseCase(this.repository);

  /// Ejecuta el caso de uso
  /// 
  /// [accountId] - ID de la cuenta
  /// [productId] - ID del producto
  /// [newStock] - Nueva cantidad en stock (debe ser >= 0)
  /// 
  /// Throws [ArgumentError] si newStock es negativo
  Future<void> call({
    required String accountId,
    required String productId,
    required int newStock,
  }) async {
    // Validación de negocio
    if (newStock < 0) {
      throw ArgumentError('El stock no puede ser negativo');
    }

    await repository.updateStock(accountId, productId, newStock);
  }
}
