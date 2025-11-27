import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Rutas y paths centralizados de Firestore y Storage
/// 
/// **Responsabilidad:**
/// - Proveer paths type-safe para colecciones y documentos
/// - Centralizar estructura de base de datos
/// - NO ejecutar operaciones (delegar a DataSources/Repositories)
/// 
/// **Patrón:** Path Provider (no God Object)
/// **Uso correcto:**
/// ```dart
/// // ❌ ANTES (God Object):
/// DatabaseCloudService.getActiveCashRegisters(accountId);
/// 
/// // ✅ AHORA (con DataSource):
/// final path = FirestorePaths.accountCashRegisters(accountId);
/// await firestoreDataSource.getDocuments(path);
/// ```
/// 
/// **Migración:** 
/// Los métodos de queries están deprecated y serán removidos.
/// Usa [FirestoreDataSource] inyectado en tus DataSources.
class DatabaseCloudService {
  // ⚠️ DEPRECATED: Usar FirestoreDataSource inyectado
  @Deprecated('Use FirestoreDataSource injected via DI')
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  @Deprecated('Use FirebaseStorage injected via DI')
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  // ==========================================
  // COLECCIONES PÚBLICAS (/APP)
  // ==========================================

  /// Información general de la aplicación
  static CollectionReference<Map<String, dynamic>> get appInfo =>
      _firestore.collection('/APP/');

  /// Productos públicos por país
  static CollectionReference<Map<String, dynamic>> publicProducts(
          {String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/PRODUCTOS');

  /// Registro de precios de productos por país
  static CollectionReference<Map<String, dynamic>> productPrices(
          {required String productId, String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/PRODUCTOS/$productId/PRICES/');

  /// Marcas registradas por país
  static CollectionReference<Map<String, dynamic>> brands(
          {String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/MARCAS/');

  /// Reportes de productos
  static CollectionReference<Map<String, dynamic>> productReports(
          {String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/REPORTS');

  /// Backup de productos
  static CollectionReference<Map<String, dynamic>> productsBackup(
          {String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/PRODUCTOS_BACKUP');

  /// Backup de marcas
  static CollectionReference<Map<String, dynamic>> brandsBackup(
          {String country = 'ARG'}) =>
      _firestore.collection('/APP/$country/BRANDS_BACKUP');

  // ==========================================
  // COLECCIONES DE CUENTAS (/ACCOUNTS)
  // ==========================================

  /// Cuentas de negocios
  static CollectionReference<Map<String, dynamic>> get accounts =>
      _firestore.collection('/ACCOUNTS/');

  /// Catálogo de productos de una cuenta específica
  static CollectionReference<Map<String, dynamic>> accountCatalogue(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/CATALOGUE/');

  /// Categorías de productos de una cuenta
  static CollectionReference<Map<String, dynamic>> accountCategories(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/CATEGORY/');

  /// Proveedores de una cuenta
  static CollectionReference<Map<String, dynamic>> accountProviders(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/PROVIDER/');

  /// Transacciones/ventas de una cuenta
  static CollectionReference<Map<String, dynamic>> accountTransactions(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/TRANSACTIONS/');

  /// Administradores y usuarios de una cuenta
  static CollectionReference<Map<String, dynamic>> accountUsers(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/USERS/');

  // ==========================================
  // SISTEMA DE CAJA REGISTRADORA
  // ==========================================

  /// Cajas registradoras activas de una cuenta
  static CollectionReference<Map<String, dynamic>> accountCashRegisters(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/CASHREGISTERS/');

  /// Historial de arqueos de caja (registros cerrados)
  static CollectionReference<Map<String, dynamic>> accountCashRegisterHistory(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/RECORDS/');

  /// Descripciones fijas para nombres de caja
  static CollectionReference<Map<String, dynamic>> accountFixedDescriptions(
          String accountId) =>
      _firestore.collection('/ACCOUNTS/$accountId/FIXERDESCRIPTIONS/');

  // ==========================================
  // COLECCIONES DE USUARIOS (/USERS)
  // ==========================================

  /// Usuarios del sistema
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('/USERS/');

  /// Cuentas administradas por un usuario
  static CollectionReference<Map<String, dynamic>> userManagedAccounts(
          String email) =>
      _firestore.collection('/USERS/$email/ACCOUNTS/');

  // ==========================================
  // REFERENCIAS DE STORAGE
  // ==========================================

  /// Imagen de perfil de cuenta
  static Reference accountProfileImage(String accountId) => _storage
      .ref()
      .child("ACCOUNTS")
      .child(accountId)
      .child("PROFILE")
      .child("imageProfile");

  /// Imagen de producto público
  static Reference publicProductImage(String productId) => _storage
      .ref()
      .child("APP")
      .child("ARG")
      .child("PRODUCTOS")
      .child(productId);

  /// Imagen de marca pública
  static Reference publicBrandImage(String brandId) =>
      _storage.ref().child("APP").child("ARG").child("MARCAS").child(brandId);

  /// Sube una imagen de producto y retorna la URL de descarga
  static Future<String> uploadProductImage(
      String productId, Uint8List fileBytes) async {
    final ref = publicProductImage(productId);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploaded_by': 'admin_panel'},
    );

    final uploadTask = await ref.putData(fileBytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Sube una imagen de marca y retorna la URL de descarga
  static Future<String> uploadBrandImage(
      String brandId, Uint8List fileBytes) async {
    final ref = publicBrandImage(brandId);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploaded_by': 'user'},
    );

    final uploadTask = await ref.putData(fileBytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  // ==========================================
  // QUERIES ESPECÍFICAS PARA CASH REGISTER
  // ==========================================

  /// Obtiene las cajas registradoras activas de una cuenta
  static Future<QuerySnapshot<Map<String, dynamic>>> getActiveCashRegisters(
          String accountId) =>
      accountCashRegisters(accountId).get();

  /// Stream de cajas registradoras activas
  static Stream<QuerySnapshot<Map<String, dynamic>>> activeCashRegistersStream(
          String accountId) =>
      accountCashRegisters(accountId).snapshots();

  /// Obtiene el historial de arqueos de caja
  static Future<QuerySnapshot<Map<String, dynamic>>> getCashRegisterHistory(
          String accountId) =>
      accountCashRegisterHistory(accountId)
          .orderBy('opening', descending: true)
          .get();

  /// Stream del historial de arqueos de caja
  static Stream<QuerySnapshot<Map<String, dynamic>>> cashRegisterHistoryStream(
          String accountId) =>
      accountCashRegisterHistory(accountId)
          .orderBy('opening', descending: true)
          .snapshots();

  /// Obtiene los arqueos de caja de los últimos N días
  static Future<QuerySnapshot<Map<String, dynamic>>> getCashRegisterByDays({
    required String accountId,
    required int days,
  }) =>
      accountCashRegisterHistory(accountId)
          .where('opening',
              isGreaterThan: DateTime.now().subtract(Duration(days: days)))
          .orderBy('opening', descending: true)
          .get();

  /// Obtiene los arqueos de caja entre dos fechas
  static Future<QuerySnapshot<Map<String, dynamic>>>
      getCashRegisterByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
          accountCashRegisterHistory(accountId)
              .where('opening', isGreaterThan: startDate)
              .where('opening', isLessThan: endDate)
              .orderBy('opening', descending: true)
              .get();

  /// Obtiene los arqueos de caja del día actual
  static Future<QuerySnapshot<Map<String, dynamic>>> getTodayCashRegisters(
          String accountId) =>
      accountCashRegisterHistory(accountId)
          .where('opening',
              isGreaterThanOrEqualTo:
                  DateTime.now().subtract(const Duration(days: 1)))
          .get();

  // ==========================================
  // OPERACIONES DE STOCK Y VENTAS
  // ==========================================

  /// Incrementa el stock de un producto
  static Future<void> incrementProductStock({
    required String accountId,
    required String productId,
    int quantity = 1,
  }) =>
      accountCatalogue(accountId)
          .doc(productId)
          .update({"quantityStock": FieldValue.increment(quantity)});

  /// Decrementa el stock de un producto
  static Future<void> decrementProductStock({
    required String accountId,
    required String productId,
    int quantity = 1,
  }) =>
      accountCatalogue(accountId)
          .doc(productId)
          .update({"quantityStock": FieldValue.increment(-quantity)});

  /// Incrementa las ventas de un producto
  static Future<void> incrementProductSales({
    required String accountId,
    required String productId,
    int quantity = 1,
  }) =>
      accountCatalogue(accountId)
          .doc(productId)
          .update({"sales": FieldValue.increment(quantity)});

  /// Incrementa los seguidores de un producto público
  static Future<void> incrementProductFollowers(String productId) =>
      publicProducts()
          .doc(productId)
          .update({"followers": FieldValue.increment(1)});

  // ==========================================
  // QUERIES DE PRODUCTOS
  // ==========================================

  /// Obtiene productos favoritos
  static Future<QuerySnapshot<Map<String, dynamic>>> getFavoriteProducts(
      {int limit = 0}) {
    final query = publicProducts().where('favorite', isEqualTo: true);
    return limit > 0 ? query.limit(limit).get() : query.get();
  }

  /// Obtiene productos por marca
  static Future<QuerySnapshot<Map<String, dynamic>>> getProductsByBrand({
    required String brandId,
    int limit = 0,
  }) {
    final query = publicProducts().where("idMark", isEqualTo: brandId);
    return limit > 0 ? query.limit(limit).get() : query.get();
  }

  /// Obtiene productos no verificados
  static Future<QuerySnapshot<Map<String, dynamic>>> getUnverifiedProducts() =>
      publicProducts().where("verified", isEqualTo: false).get();

  /// Stream de productos del catálogo de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> accountCatalogueStream(
          String accountId) =>
      accountCatalogue(accountId)
          .orderBy('upgrade', descending: true)
          .snapshots();

  /// Stream de categorías de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> accountCategoriesStream(
          String accountId) =>
      accountCategories(accountId).snapshots();

  /// Stream de proveedores de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> accountProvidersStream(
          String accountId) =>
      accountProviders(accountId).snapshots();

  /// Stream de transacciones de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> accountTransactionsStream(
          String accountId) =>
      accountTransactions(accountId)
          .orderBy("creation", descending: true)
          .snapshots();

  /// Stream de usuarios administradores de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> accountUsersStream(
          String accountId) =>
      accountUsers(accountId).snapshots();

  // ==========================================
  // QUERIES DE TRANSACCIONES CON FILTROS
  // ==========================================

  /// Stream de transacciones filtradas por fecha desde
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      transactionsFromDateStream({
    required String accountId,
    required Timestamp fromDate,
  }) =>
          accountTransactions(accountId)
              .orderBy('creation', descending: true)
              .where('creation', isGreaterThan: fromDate)
              .snapshots();

  /// Stream de transacciones filtradas por rango de fechas
  static Stream<QuerySnapshot<Map<String, dynamic>>>
      transactionsByDateRangeStream({
    required String accountId,
    required Timestamp startDate,
    required Timestamp endDate,
  }) =>
          accountTransactions(accountId)
              .orderBy('creation', descending: true)
              .where('creation', isGreaterThan: startDate)
              .where('creation', isLessThan: endDate)
              .snapshots();

  /// Future de transacciones filtradas por rango de fechas
  /// Opcionalmente puede filtrar por cashRegisterId si se proporciona
  static Future<QuerySnapshot<Map<String, dynamic>>>
      getTransactionsByDateRange({
    required String accountId,
    required Timestamp startDate,
    required Timestamp endDate,
  }) async {
    Query<Map<String, dynamic>> query = accountTransactions(accountId)
        .orderBy('creation', descending: true)
        .where('creation', isGreaterThan: startDate)
        .where('creation', isLessThan: endDate);

    final result = await query.get();

    return result;
  }

  // ==========================================
  // PRODUCTOS MÁS VENDIDOS
  // ==========================================

  /// Stream de productos más vendidos de una cuenta
  static Stream<QuerySnapshot<Map<String, dynamic>>> topSellingProductsStream({
    required String accountId,
    int limit = 50,
  }) =>
      accountCatalogue(accountId)
          .where("sales", isNotEqualTo: 0)
          .orderBy("sales", descending: true)
          .limit(limit)
          .snapshots();
}
