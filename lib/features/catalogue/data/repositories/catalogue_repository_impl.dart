import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/features/catalogue/domain/repositories/catalogue_repository.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/product.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_price.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';

/// Repository implementation usando nuevo sistema refactorizado
/// 
/// **Cambios principales:**
/// - Usa [FirestoreDataSource] inyectado (no FirebaseFirestore directo)
/// - Usa [FirestorePaths] para rutas type-safe
/// - ErrorMapper se aplicará cuando se agregue Either<Failure, T>
/// 
/// **Próximos pasos:**
/// - Migrar a Either<Failure, T> en lugar de Future<T>
/// - Aplicar ErrorMapper en catch blocks
@LazySingleton(as: CatalogueRepository)
class CatalogueRepositoryImpl implements CatalogueRepository {
  final IFirestoreDataSource _dataSource;
  
  CatalogueRepositoryImpl(this._dataSource);

  // stream : Devolverá un stream de productos del catálogo  de la cuenta del negocio seleccionada.
  @override
  Stream<QuerySnapshot> getCatalogueStream(String accountId) {
    if (accountId.isEmpty) {
      return const Stream.empty();
    }
    
    // ✅ Usar FirestorePaths para rutas type-safe
    final path = FirestorePaths.accountCatalogue(accountId);
    final collection = _dataSource.collection(path);
    
    return collection.snapshots();
  }

  // future : buscará un producto por su ID en la (base de datos) publica de productos
  @override
  Future<Product?> getPublicProductByCode(String code) async {
    // ✅ Usar FirestorePaths
    final path = FirestorePaths.publicProducts();
    final collection = _dataSource.collection(path);
    
    final query = collection
        .where('code', isEqualTo: code)
        .limit(1);
    
    final snapshot = await _dataSource.getDocuments(query);
    
    if (snapshot.docs.isNotEmpty) {
      return Product.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  //  future : agregar un nuevo producto al catálogo de la cuenta del negocio seleccionada
  @override
  Future<void> addProductToCatalogue(
      ProductCatalogue product, String accountId) async {
    if (product.id.isEmpty) {
      throw ArgumentError('El producto debe tener un ID válido');
    }

    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.accountProduct(accountId, product.id);
      final productMap = product.toMap();
      
      await _dataSource.setDocument(path, productMap, merge: true);
    } catch (e) {
      throw Exception('Error al guardar en Firestore: $e');
    }
  }

  // future : crear un nuevo producto en la base de datos pública de productos
  @override
  Future<void> createPublicProduct(Product product) async {
    if (product.id.isEmpty) {
      throw ArgumentError('El producto debe tener un ID válido');
    }
    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.publicProducts();
      final docPath = '$path/${product.id}';
      final productMap = product.toJson();
      
      await _dataSource.setDocument(docPath, productMap, merge: false);
    } catch (e) {
      throw Exception('Error al crear producto público en Firestore: $e');
    }
  }

  // future : incrementa el contador de ventas de un producto
  @override
  Future<void> incrementSales(
      String accountId, String productId, int quantity) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw ArgumentError('El accountId y productId son obligatorios');
    }

    if (quantity <= 0) {
      throw ArgumentError('La cantidad debe ser mayor a 0');
    }

    try {
      // ✅ Usar método optimizado de DataSource
      final path = FirestorePaths.accountProduct(accountId, productId);
      
      await _dataSource.incrementField(path, 'sales', quantity);
      
      // Actualizar timestamp
      await _dataSource.updateDocument(path, {
        'upgrade': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al incrementar ventas del producto: $e');
    }
  }

  // future : decrementa el stock de un producto
  @override
  Future<void> decrementStock(
      String accountId, String productId, int quantity) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw ArgumentError('El accountId y productId son obligatorios');
    }

    if (quantity <= 0) {
      throw ArgumentError('La cantidad debe ser mayor a 0');
    }

    try {
      // ✅ Usar método optimizado de DataSource
      final path = FirestorePaths.accountProduct(accountId, productId);
      
      await _dataSource.incrementField(path, 'quantityStock', -quantity);
      
      // Actualizar timestamp
      await _dataSource.updateDocument(path, {
        'upgrade': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al decrementar stock del producto: $e');
    }
  }

  // future : registra el precio de un producto en la base de datos pública
  @override
  Future<void> registerProductPrice(
      ProductPrice productPrice, String productCode) async {
    if (productCode.isEmpty) {
      throw ArgumentError('El código del producto es obligatorio');
    }

    if (productPrice.idAccount.isEmpty) {
      throw ArgumentError('El ID de la cuenta es obligatorio');
    }

    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.productPrices(productId: productCode);
      final docPath = '$path${productPrice.idAccount}';

      await _dataSource.setDocument(docPath, productPrice.toJson(), merge: true);
    } catch (e) {
      throw Exception('Error al registrar precio del producto: $e');
    }
  }

  // future : actualiza el estado de favorito de un producto
  @override
  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw ArgumentError('El accountId y productId son obligatorios');
    }

    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.accountProduct(accountId, productId);

      // Solo actualizar el estado de favorito, sin modificar el timestamp upgrade
      await _dataSource.updateDocument(path, {
        'favorite': isFavorite,
      });
    } catch (e) {
      throw Exception('Error al actualizar favorito del producto: $e');
    }
  }

  @override
  Stream<List<Category>> getCategoriesStream(String accountId) {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountCategories(accountId);
    final collection = _dataSource.collection(path);
    
    return _dataSource.streamDocuments(collection)
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromDocumentSnapshot(documentSnapshot: doc))
            .toList());
  }

  @override
  Stream<List<Provider>> getProvidersStream(String accountId) {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProviders(accountId);
    final collection = _dataSource.collection(path);
    
    return _dataSource.streamDocuments(collection)
        .map((snapshot) => snapshot.docs
            .map((doc) => Provider.fromDocumentSnapshot(documentSnapshot: doc))
            .toList());
  }

  @override
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'}) {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.brands(country: country);
    final collection = _dataSource.collection(path);
    
    return _dataSource.streamDocuments(collection)
        .map((snapshot) =>
            snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList());
  }

  @override
  Future<void> createBrand(Mark brand, {String country = 'ARG'}) async {
    if (brand.id.isEmpty) {
      throw ArgumentError('La marca debe tener un ID válido');
    }

    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.brands(country: country);
      final docPath = '$path/${brand.id}';
      final brandMap = brand.toJson();
      
      await _dataSource.setDocument(docPath, brandMap, merge: false);
    } catch (e) {
      throw Exception('Error al crear marca en Firestore: $e');
    }
  }

  @override
  Future<List<ProductCatalogue>> getProducts(String accountId) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountCatalogue(accountId);
    final collection = _dataSource.collection(path);
    final snapshot = await _dataSource.getDocuments(collection);
    
    return snapshot.docs
        .map((doc) => ProductCatalogue.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<ProductCatalogue?> getProductById(String accountId, String productId) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProduct(accountId, productId);
    final docRef = _dataSource.document(path);
    final doc = await docRef.get();
    
    if (doc.exists) {
      return ProductCatalogue.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> createProduct(String accountId, ProductCatalogue product) {
    return addProductToCatalogue(product, accountId);
  }

  @override
  Future<void> updateProduct(String accountId, ProductCatalogue product) {
    return addProductToCatalogue(product, accountId);
  }

  @override
  Future<void> deleteProduct(String accountId, String productId) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProduct(accountId, productId);
    await _dataSource.deleteDocument(path);
  }

  @override
  Future<List<Product>> searchGlobalProducts(String query) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.publicProducts();
    final collection = _dataSource.collection(path);
    final queryRef = collection.where('code', isEqualTo: query);
    final snapshot = await _dataSource.getDocuments(queryRef);
    
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  @override
  Future<List<Category>> getCategories(String accountId) async {
    if (accountId.isNotEmpty) {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.accountCategories(accountId);
      final collection = _dataSource.collection(path);
      final snapshot = await _dataSource.getDocuments(collection);
      
      return snapshot.docs
        .map((doc) => Category.fromDocumentSnapshot(documentSnapshot: doc))
        .toList();
    }
    return [];
  }

  @override
  Future<void> updateStock(String accountId, String productId, int newStock) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProduct(accountId, productId);
    
    await _dataSource.updateDocument(path, {
      'quantityStock': newStock,
      'upgrade': Timestamp.now(),
    });
  }
}
