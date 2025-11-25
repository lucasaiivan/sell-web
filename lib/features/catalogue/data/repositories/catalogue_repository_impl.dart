import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/features/catalogue/domain/repositories/catalogue_repository.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/product.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_price.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';

@LazySingleton(as: CatalogueRepository)
class CatalogueRepositoryImpl implements CatalogueRepository {
  CatalogueRepositoryImpl();

  // stream : Devolverá un stream de productos del catálogo  de la cuenta del negocio seleccionada.
  @override
  Stream<QuerySnapshot> getCatalogueStream(String accountId) {
    if (accountId.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .snapshots();
  }

  // future : buscará un producto por su ID en la (base de datos) publica de productos
  @override
  Future<Product?> getPublicProductByCode(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('/APP/ARG/PRODUCTOS')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return Product.fromMap(query.docs.first.data());
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
      final ref = FirebaseFirestore.instance
          .collection('/ACCOUNTS/$accountId/CATALOGUE');
      final productMap = product.toMap();
      await ref.doc(product.id).set(productMap, SetOptions(merge: true));
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
      final ref = FirebaseFirestore.instance.collection('/APP/ARG/PRODUCTOS');
      final productMap = product.toJson();
      await ref.doc(product.id).set(productMap, SetOptions(merge: false));
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
      final ref = FirebaseFirestore.instance
          .collection('/ACCOUNTS/$accountId/CATALOGUE')
          .doc(productId);

      await ref.update({
        'sales': FieldValue.increment(quantity),
        'upgrade': Timestamp.now(), // Actualizar timestamp de modificación
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
      final ref = FirebaseFirestore.instance
          .collection('/ACCOUNTS/$accountId/CATALOGUE')
          .doc(productId);

      await ref.update({
        'quantityStock': FieldValue.increment(-quantity),
        'upgrade': Timestamp.now(), // Actualizar timestamp de modificación
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
      final ref = FirebaseFirestore.instance
          .collection('/APP/ARG/PRODUCTOS/$productCode/PRICES')
          .doc(productPrice.idAccount);

      await ref.set(productPrice.toJson(), SetOptions(merge: true));
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
      final ref = FirebaseFirestore.instance
          .collection('/ACCOUNTS/$accountId/CATALOGUE')
          .doc(productId);

      // Solo actualizar el estado de favorito, sin modificar el timestamp upgrade
      await ref.update({
        'favorite': isFavorite,
      });
    } catch (e) {
      throw Exception('Error al actualizar favorito del producto: $e');
    }
  }

  @override
  Stream<List<Category>> getCategoriesStream(String accountId) {
    return FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATEGORY/')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromDocumentSnapshot(documentSnapshot: doc))
            .toList());
  }

  @override
  Stream<List<Provider>> getProvidersStream(String accountId) {
    return FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/PROVIDER/')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Provider.fromDocumentSnapshot(documentSnapshot: doc))
            .toList());
  }

  @override
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'}) {
    return FirebaseFirestore.instance
        .collection('/APP/$country/MARCAS/')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Mark.fromMap(doc.data())).toList());
  }

  @override
  Future<void> createBrand(Mark brand, {String country = 'ARG'}) async {
    if (brand.id.isEmpty) {
      throw ArgumentError('La marca debe tener un ID válido');
    }

    try {
      final ref =
          FirebaseFirestore.instance.collection('/APP/$country/MARCAS/');
      final brandMap = brand.toJson();
      await ref.doc(brand.id).set(brandMap, SetOptions(merge: false));
    } catch (e) {
      throw Exception('Error al crear marca en Firestore: $e');
    }
  }

  @override
  Future<List<ProductCatalogue>> getProducts(String accountId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .get();
    return snapshot.docs
        .map((doc) => ProductCatalogue.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<ProductCatalogue?> getProductById(String accountId, String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .doc(productId)
        .get();
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
    await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .doc(productId)
        .delete();
  }

  @override
  Future<List<Product>> searchGlobalProducts(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('/APP/ARG/PRODUCTOS')
        .where('code', isEqualTo: query)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  @override
  Future<List<Category>> getCategories(String accountId) async {
    if (accountId.isNotEmpty) {
       final snapshot = await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATEGORY/')
        .get();
       return snapshot.docs
        .map((doc) => Category.fromDocumentSnapshot(documentSnapshot: doc))
        .toList();
    }
    return [];
  }

  @override
  Future<void> updateStock(String accountId, String productId, int newStock) async {
    await FirebaseFirestore.instance
        .collection('/ACCOUNTS/$accountId/CATALOGUE')
        .doc(productId)
        .update({
          'quantityStock': newStock,
          'upgrade': Timestamp.now(),
        });
  }
}
