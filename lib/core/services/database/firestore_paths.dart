/// Rutas centralizadas de Firestore
///
/// **Responsabilidad:**
/// - Proveer paths type-safe de colecciones
/// - Evitar hardcoding de rutas en features
/// - Documentar estructura de base de datos
///
/// **Uso:**
/// ```dart
/// final cataloguePath = FirestorePaths.accountCatalogue(accountId);
/// final ref = firestore.collection(cataloguePath);
/// ```
///
/// **Beneficios:**
/// - Refactor-safe: cambiar estructura en un solo lugar
/// - Type-safe: parámetros requeridos en compile-time
/// - Self-documenting: estructura de DB visible
class FirestorePaths {
  FirestorePaths._(); // Prevent instantiation

  // ==========================================
  // COLECCIONES PÚBLICAS (/APP)
  // ==========================================

  /// Información general de la aplicación
  static const String appInfo = '/APP/';

  /// Productos públicos por país
  static String publicProducts({String country = 'ARG'}) =>
      '/APP/$country/PRODUCTOS';

  /// Productos pendientes de moderación
  static String productsPending({String country = 'ARG'}) =>
      '/APP/$country/PRODUCTS_PENDING';

  /// Registro de precios de productos
  static String productPrices({
    required String productId,
    String country = 'ARG',
  }) =>
      '/APP/$country/PRODUCTOS/$productId/PRICES';

  /// Marcas registradas por país
  /// NOTA: Migrado de /MARCAS a /BRANDS con normalización de description
  static String brands({String country = 'ARG'}) => '/APP/$country/BRANDS';

  /// Colección antigua de marcas (deprecated - usar brands() en su lugar)
  @Deprecated('Usar brands() en su lugar. Esta colección será eliminada.')
  static String brandsOld({String country = 'ARG'}) => '/APP/$country/MARCAS';

  /// Reportes de productos
  static String productReports({String country = 'ARG'}) =>
      '/APP/$country/REPORTS';

  /// Backup de productos
  static String productsBackup({String country = 'ARG'}) =>
      '/APP/$country/PRODUCTOS_BACKUP';

  /// Backup de marcas
  static String brandsBackup({String country = 'ARG'}) =>
      '/APP/$country/BRANDS_BACKUP';

  // ==========================================
  // COLECCIONES DE CUENTAS (/ACCOUNTS)
  // ==========================================

  /// Cuentas de negocios
  static const String accounts = '/ACCOUNTS';

  /// Documento específico de cuenta
  static String account(String accountId) => '/ACCOUNTS/$accountId';

  /// Catálogo de productos de una cuenta
  static String accountCatalogue(String accountId) =>
      '/ACCOUNTS/$accountId/CATALOGUE';

  /// Documento de producto en catálogo
  static String accountProduct(String accountId, String productId) =>
      '/ACCOUNTS/$accountId/CATALOGUE/$productId';

  /// Categorías de productos
  static String accountCategories(String accountId) =>
      '/ACCOUNTS/$accountId/CATEGORY';

  /// Proveedores de una cuenta
  static String accountProviders(String accountId) =>
      '/ACCOUNTS/$accountId/PROVIDER';

  /// Transacciones/ventas
  static String accountTransactions(String accountId) =>
      '/ACCOUNTS/$accountId/TRANSACTIONS';

  /// Documento de transacción específica
  static String accountTransaction(String accountId, String transactionId) =>
      '/ACCOUNTS/$accountId/TRANSACTIONS/$transactionId';

  /// Administradores y usuarios
  static String accountUsers(String accountId) => '/ACCOUNTS/$accountId/USERS';

  /// Usuario específico de una cuenta
  static String accountUser(String accountId, String email) =>
      '/ACCOUNTS/$accountId/USERS/$email';

  // ==========================================
  // SISTEMA DE CAJA REGISTRADORA
  // ==========================================

  /// Cajas registradoras activas
  static String accountCashRegisters(String accountId) =>
      '/ACCOUNTS/$accountId/CASHREGISTERS';

  /// Caja registradora específica
  static String accountCashRegister(String accountId, String cashRegisterId) =>
      '/ACCOUNTS/$accountId/CASHREGISTERS/$cashRegisterId';

  /// Historial de arqueos de caja
  static String accountCashRegisterHistory(String accountId) =>
      '/ACCOUNTS/$accountId/RECORDS';

  /// Registro específico en historial de caja
  static String accountCashRegisterHistoryDoc(
          String accountId, String recordId) =>
      '/ACCOUNTS/$accountId/RECORDS/$recordId';

  /// Descripciones fijas para nombres de caja
  static String accountFixedDescriptions(String accountId) =>
      '/ACCOUNTS/$accountId/FIXERDESCRIPTIONS';

  // ==========================================
  // CONFIGURACIÓN Y PREFERENCIAS
  // ==========================================

  /// Colección de configuraciones de una cuenta
  static String accountSettings(String accountId) =>
      '/ACCOUNTS/$accountId/SETTINGS';

  /// Preferencias de analíticas del dashboard
  ///
  /// **Estructura del documento:**
  /// ```json
  /// {
  ///   "visibleCards": ["billing", "profit", "sales"],
  ///   "cardOrder": ["billing", "profit", "sales", "products"],
  ///   "lastUpdated": Timestamp,
  ///   "version": 1
  /// }
  /// ```
  static String analyticsPreferences(String accountId) =>
      '/ACCOUNTS/$accountId/SETTINGS/analytics_preferences';

  // ==========================================
  // COLECCIONES DE USUARIOS (/USERS)
  // ==========================================

  /// Usuarios del sistema
  static const String users = '/USERS';

  /// Documento de usuario específico
  static String user(String email) => '/USERS/$email';

  /// Cuentas administradas por un usuario
  static String userManagedAccounts(String email) => '/USERS/$email/ACCOUNTS';

  /// Cuenta específica administrada por un usuario
  static String userManagedAccount(String email, String accountId) =>
      '/USERS/$email/ACCOUNTS/$accountId';

  // ==========================================
  // STORAGE PATHS
  // ==========================================

  /// Path de imagen de perfil de cuenta
  static String accountProfileImagePath(String accountId) =>
      'ACCOUNTS/$accountId/PROFILE/imageProfile';

  /// Path de imagen de producto público
  static String publicProductImagePath(String productId) =>
      'APP/ARG/PRODUCTOS/$productId';

  /// Path de imagen de marca pública
  /// NOTA: Migrado de /MARCAS a /BRANDS
  static String publicBrandImagePath(String brandId) =>
      'APP/ARG/BRANDS/$brandId';
}

/// Extension para construir paths complejos con query params
extension FirestorePathsExt on String {
  /// Agrega subcollection al path
  String subCollection(String name) => '$this$name';

  /// Agrega documento al path
  String doc(String id) => '$this/$id';
}
