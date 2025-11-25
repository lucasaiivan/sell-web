import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/catalogue/domain/usecases/catalogue_usecases.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/data/repositories/catalogue_repository_impl.dart';

/// Tests unitarios para CatalogueProvider
/// 
/// Verifica la funcionalidad principal del provider:
/// - Inicialización
/// - Búsqueda y filtrado
/// - Gestión de estado con productos de demo
/// 
/// NOTA: Estos tests usan productos de demostración en lugar de Firebase
/// para evitar dependencias externas. Los tests de integración con Firebase
/// deberían realizarse por separado.
void main() {
  late CatalogueProvider catalogueProvider;

  setUp(() {
    // Crear instancias reales de los use cases con repositorios vacíos
    // Para testing, usamos el modo demo que no requiere Firebase
    final catalogueRepository = CatalogueRepositoryImpl();
    final catalogueUseCases = CatalogueUseCases(catalogueRepository);
    
    catalogueProvider = CatalogueProvider(
      catalogueUseCases: catalogueUseCases,
    );
  });

  tearDown(() {
    catalogueProvider.dispose();
  });

  group('CatalogueProvider - Inicialización', () {
    test('debe iniciar con estado loading en true', () {
      expect(catalogueProvider.isLoading, true);
    });

    test('debe tener lista de productos vacía al inicio', () {
      expect(catalogueProvider.products, isEmpty);
    });

    test('debe tener filtro none al inicio', () {
      expect(catalogueProvider.activeFilter, CatalogueFilter.none);
    });

    test('debe tener query de búsqueda vacío al inicio', () {
      expect(catalogueProvider.currentSearchQuery, isEmpty);
    });
  });

  group('CatalogueProvider - Búsqueda', () {
    test('searchProducts debe retornar productos que coincidan con el query', () {
      // Arrange
      final testProducts = [
        ProductCatalogue.fromMap({
          'id': '1',
          'description': 'Coca Cola 2.5L',
          'code': '7790315000001',
          'image': '',
          'idMark': 'coca-cola',
          'nameMark': 'Coca Cola',
          'imageMark': '',
          'idProvider': '',
          'nameProvider': '',
          'imageProvider': '',
          'purchasePrice': 1000.0,
          'salePrice': 1500.0,
          'stock': true,
          'quantityStock': 10,
          'alertStock': 5,
          'sales': 0,
          'profit': 500.0,
          'favorite': false,
          'idCategory': '',
          'nameCategory': '',
          'creation': DateTime.now().millisecondsSinceEpoch,
          'upgrade': DateTime.now().millisecondsSinceEpoch,
          'documentIdCreation': '',
          'documentIdUpgrade': '',
        }),
        ProductCatalogue.fromMap({
          'id': '2',
          'description': 'Pepsi 2L',
          'code': '7790310000001',
          'image': '',
          'idMark': 'pepsi',
          'nameMark': 'Pepsi',
          'imageMark': '',
          'idProvider': '',
          'nameProvider': '',
          'imageProvider': '',
          'purchasePrice': 900.0,
          'salePrice': 1400.0,
          'stock': true,
          'quantityStock': 8,
          'alertStock': 5,
          'sales': 0,
          'profit': 500.0,
          'favorite': false,
          'idCategory': '',
          'nameCategory': '',
          'creation': DateTime.now().millisecondsSinceEpoch,
          'upgrade': DateTime.now().millisecondsSinceEpoch,
          'documentIdCreation': '',
          'documentIdUpgrade': '',
        }),
      ];

      // Cargar productos de demo para testing
      catalogueProvider.loadDemoProducts(testProducts);

      // Act
      final results = catalogueProvider.searchProducts(query: 'coca');

      // Assert
      expect(results.length, 1);
      expect(results.first.description, contains('Coca'));
    });

    test('getProductByCode debe encontrar producto por código exacto', () {
      // Arrange
      final testProducts = [
        ProductCatalogue.fromMap({
          'id': '1',
          'description': 'Coca Cola 2.5L',
          'code': '7790315000001',
          'image': '',
          'idMark': 'coca-cola',
          'nameMark': 'Coca Cola',
          'imageMark': '',
          'idProvider': '',
          'nameProvider': '',
          'imageProvider': '',
          'purchasePrice': 1000.0,
          'salePrice': 1500.0,
          'stock': true,
          'quantityStock': 10,
          'alertStock': 5,
          'sales': 0,
          'profit': 500.0,
          'favorite': false,
          'idCategory': '',
          'nameCategory': '',
          'creation': DateTime.now().millisecondsSinceEpoch,
          'upgrade': DateTime.now().millisecondsSinceEpoch,
          'documentIdCreation': '',
          'documentIdUpgrade': '',
        }),
      ];

      catalogueProvider.loadDemoProducts(testProducts);

      // Act
      final product = catalogueProvider.getProductByCode('7790315000001');

      // Assert
      expect(product, isNotNull);
      expect(product?.code, '7790315000001');
    });

    test('getProductByCode debe retornar null si no encuentra el producto', () {
      // Arrange
      catalogueProvider.loadDemoProducts([]);

      // Act
      final product = catalogueProvider.getProductByCode('999999999');

      // Assert
      expect(product, isNull);
    });
  });

  group('CatalogueProvider - Filtros', () {
    test('applyFilter debe actualizar activeFilter', () {
      // Act
      catalogueProvider.applyFilter(CatalogueFilter.favorites);

      // Assert
      expect(catalogueProvider.activeFilter, CatalogueFilter.favorites);
    });

    test('hasActiveFilter debe retornar true cuando hay filtro activo', () {
      // Act
      catalogueProvider.applyFilter(CatalogueFilter.lowStock);

      // Assert
      expect(catalogueProvider.hasActiveFilter, true);
    });

    test('clearFilter debe resetear el filtro a none', () {
      // Arrange
      catalogueProvider.applyFilter(CatalogueFilter.favorites);

      // Act
      catalogueProvider.clearFilter();

      // Assert
      expect(catalogueProvider.activeFilter, CatalogueFilter.none);
      expect(catalogueProvider.hasActiveFilter, false);
    });

    test('isFiltering debe retornar true cuando hay query o filtro activo', () {
      // Arrange
      catalogueProvider.applyFilter(CatalogueFilter.favorites);

      // Assert
      expect(catalogueProvider.isFiltering, true);
    });
  });

  group('CatalogueProvider - Estado', () {
    test('loadDemoProducts debe cargar productos y actualizar estado', () {
      // Arrange
      final testProducts = [
        ProductCatalogue.fromMap({
          'id': '1',
          'description': 'Test Product',
          'code': '123456',
          'image': '',
          'idMark': 'test',
          'nameMark': 'Test',
          'imageMark': '',
          'idProvider': '',
          'nameProvider': '',
          'imageProvider': '',
          'purchasePrice': 100.0,
          'salePrice': 150.0,
          'stock': true,
          'quantityStock': 10,
          'alertStock': 5,
          'sales': 0,
          'profit': 50.0,
          'favorite': false,
          'idCategory': '',
          'nameCategory': '',
          'creation': DateTime.now().millisecondsSinceEpoch,
          'upgrade': DateTime.now().millisecondsSinceEpoch,
          'documentIdCreation': '',
          'documentIdUpgrade': '',
        }),
      ];

      // Act
      catalogueProvider.loadDemoProducts(testProducts);

      // Assert
      expect(catalogueProvider.products.length, 1);
      expect(catalogueProvider.isLoading, false);
    });

    test('clearSearchResults debe limpiar el query de búsqueda', () {
      // Arrange
      catalogueProvider.loadDemoProducts([]);
      catalogueProvider.searchProductsWithDebounce(query: 'test');

      // Act
      catalogueProvider.clearSearchResults();

      // Assert
      expect(catalogueProvider.currentSearchQuery, isEmpty);
    });
  });
}
