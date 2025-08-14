import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/catalogue_repository.dart';
import '../domain/entities/catalogue.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  final String? id;
  CatalogueRepositoryImpl({this.id});

  // stream : Devolverá un stream de productos del catálogo  de la cuenta del negocio seleccionada.
  @override
  Stream<QuerySnapshot> getCatalogueStream() {
    if (id == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('/ACCOUNTS/$id/CATALOGUE')
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
  Future<void> registerProductPrice(ProductPrice productPrice, String productCode) async {
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
}
