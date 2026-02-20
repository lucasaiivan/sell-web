import 'dart:math';
import 'package:sellweb/core/services/demo_account/data/demo_constants.dart';
import 'package:sellweb/core/services/demo_account/data/demo_config.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';

/// Generador de datos demo para catálogo (productos, categorías, marcas, proveedores)
///
/// **Responsabilidad:**
/// - Generar productos variados con categorías, marcas e imágenes
/// - Generar lista de categorías como entidades
/// - Generar lista de proveedores únicos como entidades
/// - Generar lista de marcas únicas como entidades
/// - Mantener coherencia entre datos relacionados
///
/// **Características:**
/// - Datos generados en memoria (no se persisten)
/// - Generación eficiente (<500ms)
/// - Datos realistas para demostración completa
class CatalogueDemoGenerator {
  CatalogueDemoGenerator._();

  // ==========================================
  // PRODUCTOS
  // ==========================================

  /// Genera una lista completa de productos demo variados y coherentes
  ///
  /// **Retorna:** Lista de 100 productos con:
  /// - 12 categorías variadas
  /// - Marcas coherentes por categoría
  /// - Proveedores específicos por categoría
  /// - Precios realistas
  /// - Stock variado
  /// - Porcentaje de ganancia realista por categoría
  /// - 20% marcados como favoritos
  static List<ProductCatalogue> generateDemoProducts() {
    final products = <ProductCatalogue>[];
    int productId = 1;

    // 1. Pre-calcular IDs para garantizar consistencia
    final categoryIds = <String, String>{};
    for (int i = 0; i < kDemoCategories.length; i++) {
      categoryIds[kDemoCategories[i]] = 'demo_category_${i + 1}';
    }

    final providerIds = <String, String>{};
    int globalProviderId = 1;
    for (final category in kDemoCategories) {
      final pList = kDemoProvidersByCategory[category] ?? [];
      for (final pName in pList) {
        providerIds[pName] = 'demo_provider_$globalProviderId';
        globalProviderId++;
      }
    }

    // 2. Generar productos
    for (final categoryName in kDemoCategories) {
      final brands = kDemoBrandsByCategory[categoryName] ?? ['Marca Demo'];
      final providers = kDemoProvidersByCategory[categoryName] ?? ['Proveedor Demo'];
      final productNames = kDemoProductNamesByCategory[categoryName] ?? ['Producto Demo'];
      final categoryId = categoryIds[categoryName] ?? 'demo_cat_unknown';

      for (int i = 0; i < productNames.length; i++) {
        final brand = brands[i % brands.length];
        // Selección cíclica de proveedor para este producto
        final providerName = providers[i % providers.length];
        // Buscar el ID global correcto para ese nombre de proveedor
        final providerId = providerIds[providerName] ?? 'demo_prov_unknown';
        
        final name = productNames[i];
        final isFavorite = (productId % 5 == 0); // 20% favoritos
        final salesCount = (10 + (productId * 7.3) % 491).toDouble();

        // Generar precio y ganancia
        final salePrice = _generatePrice(categoryName);
        final profitPercentage = _generateProfitPercentage(categoryName);
        final purchasePrice = salePrice / (1 + profitPercentage / 100);

        products.add(ProductCatalogue(
          id: 'demo_product_$productId',
          nameMark: brand,
          description: '$name - ${_getProductDescription(categoryName)}',
          code: 'DEMO${productId.toString().padLeft(4, '0')}',
          image: '', // No mostrar imágenes en demo
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          revenuePercentage: profitPercentage,
          
          // --- FIX: Asignación Correcta de IDs y Nombres ---
          provider: providerId,        // ID del proveedor (ej: demo_provider_5)
          nameProvider: providerName,  // Nombre real (ej: Distribuidora X)
          category: categoryId,        // ID de la categoría (ej: demo_category_1)
          nameCategory: categoryName,  // Nombre real (ej: Lácteos)
          // -----------------------------------------------

          quantityStock: _generateStock(),
          stock: true,
          alertStock: kDemoAlertStock,
          currencySign: kDemoCurrencySymbol,
          favorite: isFavorite,
          sales: salesCount,
          creation: DateTime.now().subtract(Duration(days: 30 - (productId % 30))),
          upgrade: DateTime.now().subtract(Duration(days: productId % 15)),
          documentCreation: DateTime.now().subtract(Duration(days: 30 - (productId % 30))),
          documentUpgrade: DateTime.now().subtract(Duration(days: productId % 15)),
          
          // Campos obligatorios requeridos por el modelo
          status: 'verified', // Productos demo siempre verificados
          unit: 'unit',       // Default unit
          variants: {},
        ));

        productId++;
      }
    }

    return products;
  }

  /// Genera precio realista según categoría
  static double _generatePrice(String category) {
    final basePrice = kDemoBasePricesByCategory[category] ?? 800.0;
    // Variación del ±30%
    final variation = (basePrice * kDemoPriceVariation) * (DateTime.now().millisecond % 100 / 100);
    return (basePrice + variation - (basePrice * 0.15)).roundToDouble();
  }

  /// Genera porcentaje de ganancia realista por categoría
  static double _generateProfitPercentage(String category) {
    final range = kDemoProfitRangesByCategory[category] ?? [20.0, 40.0];
    final min = range[0];
    final max = range[1];
    final profit = min + ((max - min) * (DateTime.now().microsecond % 100 / 100));
    return double.parse(profit.toStringAsFixed(1)); // 1 decimal
  }

  /// Genera cantidad de stock realista
  static double _generateStock() {
    return kDemoStockOptions[DateTime.now().millisecond % kDemoStockOptions.length];
  }

  /// Obtiene descripción para un producto según categoría
  static String _getProductDescription(String category) {
    return kDemoProductDescriptions[category] ?? 'Producto de supermercado de primera calidad.';
  }

  // ==========================================
  // CATEGORÍAS
  // ==========================================

  /// Genera lista de categorías como entidades
  ///
  /// **Retorna:** Lista de 12 categorías
  static List<Category> generateDemoCategories() {
    return kDemoCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryName = entry.value;
      
      return Category(
        id: 'demo_category_${index + 1}',
        name: categoryName,
        subcategories: {}, // Sin subcategorías en demo
      );
    }).toList();
  }

  // ==========================================
  // PROVEEDORES
  // ==========================================

  /// Genera lista de proveedores únicos como entidades
  ///
  /// **Retorna:** Lista de ~36 proveedores únicos
  static List<Provider> generateDemoProviders() {
    final providers = <Provider>[];
    int providerId = 1;

    // Iterar por categoría para obtener proveedores únicos
    for (final category in kDemoCategories) {
      final categoryProviders = kDemoProvidersByCategory[category] ?? [];
      
      for (final providerName in categoryProviders) {
        providers.add(Provider(
          id: 'demo_provider_$providerId',
          name: providerName,
          phone: _generateDemoPhone(),
          email: _generateDemoEmail(providerName),
        ));
        
        providerId++;
      }
    }

    return providers;
  }

  /// Genera un teléfono demo realista
  static String _generateDemoPhone() {
    final random = Random(kDemoRandomSeed);
    final areaCode = 11 + random.nextInt(89); // 11-99
    final number = 1000 + random.nextInt(8999); // 1000-9999
    final extension = 1000 + random.nextInt(8999);
    return '+54 $areaCode $number-$extension';
  }

  /// Genera un email demo basado en el nombre del proveedor
  static String _generateDemoEmail(String providerName) {
    final cleanName = providerName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u');
    return 'contacto@$cleanName.com.ar';
  }

  // ==========================================
  // MARCAS
  // ==========================================

  /// Genera lista de marcas únicas como entidades
  ///
  /// **Retorna:** Lista de ~60 marcas únicas
  static List<Mark> generateDemoBrands() {
    final brands = <Mark>[];
    int brandId = 1;
    final now = DateTime.now();

    // Iterar por categoría para obtener marcas únicas
    for (final category in kDemoCategories) {
      final categoryBrands = kDemoBrandsByCategory[category] ?? [];
      
      for (final brandName in categoryBrands) {
        brands.add(Mark(
          id: 'demo_brand_$brandId',
          name: brandName,
          description: 'Marca reconocida en la categoría de $category',
          image: '', // Sin imagen en demo
          verified: brandId % 3 == 0, // 33% verificadas
          creation: now.subtract(Duration(days: 365 - (brandId % 365))),
          upgrade: now.subtract(Duration(days: brandId % 30)),
        ));
        
        brandId++;
      }
    }

    return brands;
  }
}
