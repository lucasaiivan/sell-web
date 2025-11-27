/// Rutas centralizadas de Firebase Storage
/// 
/// **Responsabilidad:**
/// - Proveer paths type-safe de Storage
/// - Evitar hardcoding de rutas en features
/// - Documentar estructura de Storage
/// 
/// **Uso:**
/// ```dart
/// final path = StoragePaths.productImage(accountId, productId);
/// final url = await storageDataSource.uploadFile(path, bytes);
/// ```
/// 
/// **Beneficios:**
/// - Refactor-safe: cambiar estructura en un solo lugar
/// - Type-safe: parámetros requeridos en compile-time
/// - Self-documenting: estructura de Storage visible
class StoragePaths {
  StoragePaths._(); // Prevent instantiation

  // ==========================================
  // PRODUCTOS
  // ==========================================

  /// Imagen de producto en catálogo de cuenta
  /// Ruta: ACCOUNTS/{accountId}/PRODUCTS/{productId}.jpg
  static String productImage(String accountId, String productId) =>
      'ACCOUNTS/$accountId/PRODUCTS/$productId.jpg';

  /// Imagen de producto público
  /// Ruta: APP/ARG/PRODUCTOS/{productId}.jpg
  static String publicProductImage(String productId, {String country = 'ARG'}) =>
      'APP/$country/PRODUCTOS/$productId.jpg';

  // ==========================================
  // MARCAS
  // ==========================================

  /// Imagen de marca pública
  /// Ruta: APP/ARG/MARCAS/{brandId}.jpg
  static String publicBrandImage(String brandId, {String country = 'ARG'}) =>
      'APP/$country/MARCAS/$brandId.jpg';

  /// Imagen de marca en catálogo de cuenta
  /// Ruta: ACCOUNTS/{accountId}/BRANDS/{brandId}.jpg
  static String accountBrandImage(String accountId, String brandId) =>
      'ACCOUNTS/$accountId/BRANDS/$brandId.jpg';

  // ==========================================
  // PERFIL DE CUENTA
  // ==========================================

  /// Imagen de perfil de cuenta
  /// Ruta: ACCOUNTS/{accountId}/PROFILE/imageProfile.jpg
  static String accountProfileImage(String accountId) =>
      'ACCOUNTS/$accountId/PROFILE/imageProfile.jpg';

  // ==========================================
  // USUARIOS
  // ==========================================

  /// Imagen de perfil de usuario
  /// Ruta: USERS/{userId}/PROFILE/avatar.jpg
  static String userProfileImage(String userId) =>
      'USERS/$userId/PROFILE/avatar.jpg';
}
