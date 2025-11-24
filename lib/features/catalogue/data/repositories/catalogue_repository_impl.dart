import 'package:injectable/injectable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_catalogue.dart';
import '../../domain/repositories/catalogue_repository.dart';
import '../datasources/catalogue_remote_datasource.dart';

/// Implementación del repositorio de catálogo.
/// 
/// Actúa como intermediario entre el dominio y la capa de datos,
/// convirtiendo modelos a entidades y viceversa.
@LazySingleton(as: CatalogueRepository)
class CatalogueRepositoryImpl implements CatalogueRepository {
  final CatalogueRemoteDataSource remoteDataSource;

  CatalogueRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ProductCatalogue>> getProducts(String accountId) async {
    final models = await remoteDataSource.getProducts(accountId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ProductCatalogue?> getProductById(
      String accountId, String productId) async {
    final model = await remoteDataSource.getProductById(accountId, productId);
    return model?.toEntity();
  }

  @override
  Future<void> createProduct(
      String accountId, ProductCatalogue product) async {
    // Aquí necesitamos importar el modelo para la conversión
    // Por ahora asumimos que tenemos un método fromEntity en el modelo
    throw UnimplementedError('Necesita conversión de entidad a modelo');
  }

  @override
  Future<void> updateProduct(
      String accountId, ProductCatalogue product) async {
    throw UnimplementedError('Necesita conversión de entidad a modelo');
  }

  @override
  Future<void> deleteProduct(String accountId, String productId) async {
    await remoteDataSource.deleteProduct(accountId, productId);
  }

  @override
  Future<List<Product>> searchGlobalProducts(String query) async {
    final models = await remoteDataSource.searchGlobalProducts(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Category>> getCategories() async {
    final models = await remoteDataSource.getCategories();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateStock(
      String accountId, String productId, int newStock) async {
    await remoteDataSource.updateStock(accountId, productId, newStock);
  }
}
