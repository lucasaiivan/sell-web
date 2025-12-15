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

    final query = collection.where('code', isEqualTo: code).limit(1);

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

  // future : crear un nuevo producto pendiente de moderación
  @override
  Future<void> createPendingProduct(Product product) async {
    if (product.id.isEmpty) {
      throw ArgumentError('El producto debe tener un ID válido');
    }
    try {
      // ✅ Usar FirestorePaths + DataSource
      final path = FirestorePaths.productsPending();
      final docPath = '$path/${product.id}';
      final productMap = product.toJson();

      await _dataSource.setDocument(docPath, productMap, merge: false);
    } catch (e) {
      throw Exception('Error al crear producto pendiente en Firestore: $e');
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

      await _dataSource.setDocument(docPath, productPrice.toJson(),
          merge: true);
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

    return _dataSource.streamDocuments(collection).map((snapshot) => snapshot
        .docs
        .map((doc) => Category.fromDocumentSnapshot(documentSnapshot: doc))
        .toList());
  }

  @override
  Stream<List<Provider>> getProvidersStream(String accountId) {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProviders(accountId);
    final collection = _dataSource.collection(path);

    return _dataSource.streamDocuments(collection).map((snapshot) => snapshot
        .docs
        .map((doc) => Provider.fromDocumentSnapshot(documentSnapshot: doc))
        .toList());
  }

  @override
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'}) {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.brands(country: country);
    final collection = _dataSource.collection(path);

    return _dataSource.streamDocuments(collection).map((snapshot) =>
        snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList());
  }

  @override
  Future<List<Mark>> searchBrands({
    required String query,
    String country = 'ARG',
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return [];

      final path = FirestorePaths.brands(country: country);
      final collection = _dataSource.collection(path);

      // Búsqueda por prefijo usando el truco de Firestore
      // Busca documentos donde 'name' >= query y 'name' <= query + '\uf8ff'
      final snapshot = await _dataSource.getDocuments(
        collection
            .orderBy('name')
            .startAt([query]).endAt([query + '\uf8ff']).limit(limit),
      );

      return snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error al buscar marcas: $e');
    }
  }

  @override
  Future<List<Mark>> getPopularBrands({
    String country = 'ARG',
    int limit = 20,
  }) async {
    try {
      final path = FirestorePaths.brands(country: country);
      print('📍 Obteniendo marcas de: $path');
      final collection = _dataSource.collection(path);

      // Obtiene marcas verificadas ordenadas por fecha de creación
      final snapshot = await _dataSource.getDocuments(
        collection
            .where('verified', isEqualTo: true)
            .orderBy('creation', descending: true)
            .limit(limit),
      );

      print('📊 Documentos obtenidos: ${snapshot.docs.length}');
      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first.data();
        print('🔍 Primer documento raw: $firstDoc');
      }

      return snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList();
    } catch (e) {
      print('⚠️  Error con query verificadas, intentando sin filtro: $e');
      // Si falla por falta de índice, intenta sin filtro de verificación
      try {
        final path = FirestorePaths.brands(country: country);
        final collection = _dataSource.collection(path);

        final snapshot = await _dataSource.getDocuments(
          collection.orderBy('creation', descending: true).limit(limit),
        );

        print('📊 Documentos obtenidos (sin filtro): ${snapshot.docs.length}');
        if (snapshot.docs.isNotEmpty) {
          final firstDoc = snapshot.docs.first.data();
          print('🔍 Primer documento raw (sin filtro): $firstDoc');
        }

        return snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList();
      } catch (e2) {
        throw Exception('Error al obtener marcas populares: $e2');
      }
    }
  }

  @override
  Future<Mark?> getBrandById(String id, {String country = 'ARG'}) async {
    try {
      final path = FirestorePaths.brands(country: country);
      final collection = _dataSource.collection(path);

      // Buscar por ID del documento
      final query =
          collection.where(FieldPath.documentId, isEqualTo: id).limit(1);
      final snapshot = await _dataSource.getDocuments(query);

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Mark.fromMap(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error al obtener marca por ID: $e');
    }
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
  Future<void> updateBrand(Mark brand, {String country = 'ARG'}) async {
    if (brand.id.isEmpty) {
      throw ArgumentError('La marca debe tener un ID válido');
    }

    try {
      final path = FirestorePaths.brands(country: country);
      final docPath = '$path/${brand.id}';
      final brandMap = brand.toJson();

      // Actualizar el timestamp de modificación
      brandMap['upgrade'] = Timestamp.now();

      await _dataSource.setDocument(docPath, brandMap, merge: true);
    } catch (e) {
      throw Exception('Error al actualizar marca en Firestore: $e');
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
  Future<ProductCatalogue?> getProductById(
      String accountId, String productId) async {
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
  Future<void> updateStock(
      String accountId, String productId, int newStock) async {
    // ✅ Usar FirestorePaths + DataSource
    final path = FirestorePaths.accountProduct(accountId, productId);

    await _dataSource.updateDocument(path, {
      'quantityStock': newStock,
      'upgrade': Timestamp.now(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE FOLLOWERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Incrementa el contador de followers de un producto público
  ///
  /// Usa FieldValue.increment para operación atómica en Firestore.
  @override
  Future<void> incrementProductFollowers(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('El productId es obligatorio');
    }

    try {
      final publicPath = '${FirestorePaths.publicProducts()}/$productId';

      // Verificar si existe en productos públicos
      final publicDoc = _dataSource.document(publicPath);
      final publicSnapshot = await publicDoc.get();

      if (!publicSnapshot.exists) {
        throw Exception(
            'El producto $productId no existe en la base de datos pública');
      }

      await _dataSource.incrementField(publicPath, 'followers', 1);
    } catch (e) {
      throw Exception('Error al incrementar followers del producto: $e');
    }
  }

  /// Decrementa el contador de followers de un producto público
  ///
  /// Usa FieldValue.increment con valor negativo para operación atómica.
  /// El contador se mantiene en 0 como mínimo en la lógica de negocio,
  /// aunque Firestore permite valores negativos.
  @override
  Future<void> decrementProductFollowers(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('El productId es obligatorio');
    }

    try {
      final publicPath = '${FirestorePaths.publicProducts()}/$productId';

      // Verificar si existe en productos públicos
      final publicDoc = _dataSource.document(publicPath);
      final publicSnapshot = await publicDoc.get();

      if (!publicSnapshot.exists) {
        throw Exception(
            'El producto $productId no existe en la base de datos pública');
      }

      // Verificar que followers no sea 0 antes de decrementar
      final data = publicSnapshot.data();
      final currentFollowers = data?['followers'] ?? 0;
      if (currentFollowers > 0) {
        await _dataSource.incrementField(publicPath, 'followers', -1);
      }
    } catch (e) {
      throw Exception('Error al decrementar followers del producto: $e');
    }
  }
}
