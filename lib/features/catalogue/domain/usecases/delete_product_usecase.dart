import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/i_storage_datasource.dart';
import '../../../../core/services/storage/storage_paths.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product_catalogue.dart';

/// Parámetros para DeleteProductUseCase
class DeleteProductParams {
  final ProductCatalogue product;
  final String accountId;

  const DeleteProductParams({
    required this.product,
    required this.accountId,
  });
}

/// Caso de uso: Eliminar producto del catálogo con lógica de followers
///
/// **Responsabilidad:**
/// - Elimina el producto del catálogo privado
/// - Elimina la imagen del storage si es producto SKU
/// - Decrementa followers si es producto público (verified o pending)
/// - NO decrementa followers si es SKU interno
///
/// ## Flujo de eliminación:
///
/// ### 1. Producto SKU (status: 'sku')
/// - Se elimina del catálogo privado
/// - Se elimina la imagen del storage privado
/// - NO se toca la BD global (no existe documento público)
///
/// ### 2. Producto VERIFIED o PENDING
/// - Se elimina del catálogo privado
/// - Se decrementa el contador de followers en BD global
/// - El documento público permanece para otros comercios
/// - La imagen pública NO se elimina (otros comercios pueden usarla)
@lazySingleton
class DeleteProductUseCase extends UseCase<void, DeleteProductParams> {
  final CatalogueRepository _repository;
  final IStorageDataSource _storage;

  DeleteProductUseCase(this._repository, this._storage);

  /// Ejecuta la eliminación del producto con lógica de followers
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(DeleteProductParams params) async {
    try {
      final product = params.product;
      final accountId = params.accountId;

      // 1. Eliminar del catálogo privado
      await _repository.deleteProduct(accountId, product.id);

      // 2. Si es SKU, eliminar imagen del storage privado
      if (product.isSku && product.image.isNotEmpty) {
        try {
          final imagePath = StoragePaths.productImage(accountId, product.code);
          await _storage.deleteFile(imagePath);
        } catch (e) {
          // Log pero no fallar si la imagen no existe o ya fue eliminada
          print('⚠️ No se pudo eliminar imagen del storage: $e');
        }
      }

      // 3. Si NO es SKU interno, decrementar followers en BD global
      if (!product.isSku && (product.isVerified || product.isPending)) {
        await _repository.decrementProductFollowers(product.id);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar producto: ${e.toString()}'));
    }
  }
}
