import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product_catalogue.dart';
import '../entities/product.dart';

/// Parámetros para SaveProductUseCase
class SaveProductParams {
  final ProductCatalogue product;
  final String accountId;
  final bool isCreatingMode;
  final bool existedInCatalogue;

  const SaveProductParams({
    required this.product,
    required this.accountId,
    required this.isCreatingMode,
    required this.existedInCatalogue,
  });
}

/// Resultado del guardado de producto
class SaveProductResult {
  final ProductCatalogue updatedProduct;
  final String message;

  const SaveProductResult({
    required this.updatedProduct,
    required this.message,
  });
}

/// Caso de uso: Guardar producto con lógica de negocio completa
///
/// **Responsabilidad:**
/// - Determina el tipo de producto (SKU, nuevo, verificado, pendiente)
/// - Aplica las reglas de negocio según el tipo
/// - Maneja la creación en BD global y catálogo privado
/// - Gestiona el contador de followers
///
/// ## Flujo de guardado según tipo de producto:
///
/// ### 1. Producto SKU (interno del comercio)
/// - Se guarda SOLO en el catálogo privado
/// - Status: 'sku'
/// - NO se crea documento en BD global
///
/// ### 2. Producto con código válido - NUEVO (no existe en BD global)
/// - Se crea documento en BD global con status 'pending' y followers = 1
/// - Se guarda en catálogo privado
///
/// ### 3. Producto con código válido - EXISTENTE en BD global
/// - Status 'pending': Se puede editar, se actualiza BD global y catálogo privado
/// - Status 'verified': Solo se editan atributos del catálogo (precios, stock, etc.)
///   - Se incrementa followers si es primera vez que se agrega al catálogo
@lazySingleton
class SaveProductUseCase extends UseCase<SaveProductResult, SaveProductParams> {
  final CatalogueRepository _repository;

  SaveProductUseCase(this._repository);

  /// Ejecuta el guardado del producto con toda la lógica de negocio
  ///
  /// Retorna [Right(SaveProductResult)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, SaveProductResult>> call(
      SaveProductParams params) async {
    try {
      var updatedProduct = params.product;
      final isSku =
          updatedProduct.isSku || updatedProduct.code.startsWith('SKU-');
      final isVerified = updatedProduct.isVerified;
      final isPending = updatedProduct.isPending;
      final isNewProduct = params.isCreatingMode;
      final existedInCatalogue = params.existedInCatalogue;
      final hasNoStatus = updatedProduct.status.isEmpty;

      String resultMessage;

      // ═══════════════════════════════════════════════════════════════════════
      // LÓGICA DE GUARDADO SEGÚN TIPO DE PRODUCTO
      // ═══════════════════════════════════════════════════════════════════════

      if (isSku) {
        // ─────────────────────────────────────────────────────────────────────
        // CASO 1: Producto SKU interno
        // Solo se guarda en catálogo privado, sin tocar BD global
        // ─────────────────────────────────────────────────────────────────────
        updatedProduct = updatedProduct.copyWith(
          status: 'sku',
        );
        resultMessage =
            isNewProduct ? 'Producto SKU creado' : 'Producto SKU actualizado';
      } else if (isNewProduct && hasNoStatus) {
        // ─────────────────────────────────────────────────────────────────────
        // CASO 2: Producto NUEVO con código válido (no existe en BD global)
        // Se crea en BD global como 'pending' con followers = 1
        // Condición: isCreatingMode=true y status vacío (producto completamente nuevo)
        // ─────────────────────────────────────────────────────────────────────
        final globalProduct = Product(
          id: updatedProduct.id,
          code: updatedProduct.code,
          description: updatedProduct.description,
          image: updatedProduct.image,
          idMark: updatedProduct.idMark,
          nameMark: updatedProduct.nameMark,
          imageMark: updatedProduct.imageMark,
          reviewed: false,
          followers: 1, // Primer follower es el creador
          favorite: false,
          creation: DateTime.now(),
          upgrade: DateTime.now(),
          idUserCreation: params.accountId,
          idUserUpgrade: params.accountId,
          variants: updatedProduct.variants,
          unit: updatedProduct.unit,
          status: 'pending',
        );

        await _repository.createPublicProduct(globalProduct);

        // Asegurar que el producto tenga el status correcto
        updatedProduct = updatedProduct.copyWith(
          status: 'pending',
        );
        resultMessage = 'Producto creado en base de datos global';
      } else if (isNewProduct && isVerified) {
        // ─────────────────────────────────────────────────────────────────────
        // CASO 3: Agregando producto VERIFICADO de BD global al catálogo
        // Solo incrementar followers (el producto ya existe en BD global)
        // ─────────────────────────────────────────────────────────────────────
        if (!existedInCatalogue) {
          await _repository.incrementProductFollowers(updatedProduct.id);
        }
        // Mantener status verified, solo se editan atributos del catálogo
        updatedProduct = updatedProduct.copyWith(
          status: 'verified',
        );
        resultMessage = 'Producto verificado agregado al catálogo';
      } else if (isNewProduct && isPending) {
        // ─────────────────────────────────────────────────────────────────────
        // CASO 4: Agregando producto PENDIENTE de BD global al catálogo
        // Incrementar followers si no existía en catálogo local
        // ─────────────────────────────────────────────────────────────────────
        if (!existedInCatalogue) {
          await _repository.incrementProductFollowers(updatedProduct.id);
        }
        // Mantener status pending
        updatedProduct = updatedProduct.copyWith(
          status: 'pending',
        );
        resultMessage = 'Producto pendiente agregado al catálogo';
      } else if (!isNewProduct && isPending) {
        // ─────────────────────────────────────────────────────────────────────
        // CASO 5: Editando producto PENDIENTE existente en catálogo
        // Actualizar tanto en catálogo privado como en BD pública
        // ─────────────────────────────────────────────────────────────────────
        final globalProduct = Product(
          id: updatedProduct.id,
          code: updatedProduct.code,
          description: updatedProduct.description,
          image: updatedProduct.image,
          idMark: updatedProduct.idMark,
          nameMark: updatedProduct.nameMark,
          imageMark: updatedProduct.imageMark,
          reviewed: false,
          followers: updatedProduct.followers,
          favorite: updatedProduct.favorite,
          creation: updatedProduct.documentCreation,
          upgrade: DateTime.now(),
          idUserCreation: updatedProduct.documentIdCreation,
          idUserUpgrade: params.accountId,
          variants: updatedProduct.variants,
          unit: updatedProduct.unit,
          status: 'pending',
        );

        // Actualizar en BD pública (merge = true para no perder followers)
        await _repository.createPublicProduct(globalProduct);

        updatedProduct = updatedProduct.copyWith(
          status: 'pending',
        );
        resultMessage =
            'Producto pendiente actualizado en BD global y catálogo';
      } else {
        // Actualización de producto existente en catálogo (otros casos)
        resultMessage = 'Producto actualizado correctamente';
      }

      // ═══════════════════════════════════════════════════════════════════════
      // GUARDAR EN CATÁLOGO PRIVADO
      // ═══════════════════════════════════════════════════════════════════════
      await _repository.addProductToCatalogue(updatedProduct, params.accountId);

      return Right(SaveProductResult(
        updatedProduct: updatedProduct,
        message: resultMessage,
      ));
    } catch (e) {
      return Left(ServerFailure('Error al guardar producto: ${e.toString()}'));
    }
  }
}
