import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/catalogue.dart';

// case use : Devolverá un stream de productos del catálogo de la cuenta del negocio seleccionada.
class GetCatalogueStreamUseCase {
  final CatalogueRepository repository;
  GetCatalogueStreamUseCase(this.repository);
  Stream<QuerySnapshot> call() => repository.getCatalogueStream();
}

// case use : Busca un producto por código de barra en una lista de productos
class GetProductByCodeUseCase {
  // Recibe la lista de productos y el código a buscar
  ProductCatalogue? call(List<ProductCatalogue> products, String code) {
    try {
      return products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }
}

// case use : Busca un producto público por código de barra
class GetPublicProductByCodeUseCase {
  final CatalogueRepository repository;
  GetPublicProductByCodeUseCase(this.repository);
  // Busca un producto público por código de barra
  Future<Product?> call(String code) => repository.getPublicProductByCode(code);
}

// case use : Verifica si un producto ya ha sido escaneado
class IsProductScannedUseCase {
  final GetProductByCodeUseCase getProductByCodeUseCase;
  IsProductScannedUseCase(this.getProductByCodeUseCase);

  bool call(List<ProductCatalogue> products, String code) {
    final product = getProductByCodeUseCase(products, code);
    return product != null;
  }
}

// case use : Agrega un producto al catálogo de la cuenta del negocio seleccionada
class AddProductToCatalogueUseCase {
  final CatalogueRepository repository;
  AddProductToCatalogueUseCase(this.repository);
  Future<void> call(ProductCatalogue product, String accountId) =>
      repository.addProductToCatalogue(product, accountId);
}

// case use : Crea un nuevo producto en la base de datos pública
class CreatePublicProductUseCase {
  final CatalogueRepository repository;
  CreatePublicProductUseCase(this.repository);
  Future<void> call(Product product) => repository.createPublicProduct(product);
}

// case use : Incrementa el contador de ventas de un producto
class IncrementProductSalesUseCase {
  final CatalogueRepository repository;
  IncrementProductSalesUseCase(this.repository);

  /// Incrementa el contador de ventas de un producto específico
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad vendida (por defecto 1)
  Future<void> call(String accountId, String productId, {int quantity = 1}) {
    return repository.incrementSales(accountId, productId, quantity);
  }
}

// case use : Decrementa el stock de un producto
class DecrementProductStockUseCase {
  final CatalogueRepository repository;
  DecrementProductStockUseCase(this.repository);

  /// Decrementa el stock de un producto específico
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad a decrementar
  Future<void> call(String accountId, String productId, int quantity) {
    return repository.decrementStock(accountId, productId, quantity);
  }
}

// case use : Registra el precio de un producto en la base de datos pública
class RegisterProductPriceUseCase {
  final CatalogueRepository repository;
  RegisterProductPriceUseCase(this.repository);

  /// Registra el precio de un producto en la base de datos pública
  /// [productPrice] - Datos del precio del producto
  /// [productCode] - Código del producto
  Future<void> call(ProductPrice productPrice, String productCode) {
    return repository.registerProductPrice(productPrice, productCode);
  }
}

// case use : Actualiza el estado de favorito de un producto
class UpdateProductFavoriteUseCase {
  final CatalogueRepository repository;
  UpdateProductFavoriteUseCase(this.repository);

  /// Actualiza el estado de favorito de un producto específico
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [isFavorite] - Nuevo estado de favorito
  Future<void> call(String accountId, String productId, bool isFavorite) {
    return repository.updateProductFavorite(accountId, productId, isFavorite);
  }
}
