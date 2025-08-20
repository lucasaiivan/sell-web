/// Constantes generales de la aplicación
/// Centraliza configuraciones, límites y valores por defecto.
class AppConstants {
  // ==========================================
  // INFORMACIÓN DE LA APP
  // ==========================================
  static const String appName = 'Sell Web';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de ventas web con Flutter';

  // ==========================================
  // CONFIGURACIÓN DE TIMEOUTS
  // ==========================================
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);

  // ==========================================
  // LÍMITES Y PAGINACIÓN
  // ==========================================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int maxSearchResults = 50;

  // ==========================================
  // LÍMITES DE ARCHIVOS Y MEDIA
  // ==========================================
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxPdfSize = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx'];

  // ==========================================
  // CONFIGURACIÓN DE VENTAS
  // ==========================================
  static const double maxDiscountPercentage = 0.50; // 50%
  static const int maxItemsPerTicket = 100;
  static const int maxTicketsPerDay = 1000;
  static const double minSaleAmount = 0.01;

  // ==========================================
  // CONFIGURACIÓN DE PRODUCTOS
  // ==========================================
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 500;
  static const double maxProductPrice = 999999.99;
  static const int maxProductStock = 99999;

  // ==========================================
  // CONFIGURACIÓN DE IMPRESIÓN
  // ==========================================
  static const int thermalPrinterWidth = 48; // caracteres por línea
  static const int maxPrintRetries = 3;
  static const Duration printTimeout = Duration(seconds: 10);

  // ==========================================
  // CONFIGURACIÓN DE CACHÉ
  // ==========================================
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // cantidad de elementos
  static const Duration localStorageRetention = Duration(days: 30);

  // ==========================================
  // CONFIGURACIÓN DE AUTENTICACIÓN
  // ==========================================
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 3;
  static const Duration loginCooldown = Duration(minutes: 15);

  // ==========================================
  // CONFIGURACIÓN DE ANIMACIONES
  // ==========================================
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ==========================================
  // CONFIGURACIÓN DE DEMO
  // ==========================================
  static const String demoAccountId = 'demo';
  static const String demoCashRegisterId = 'demo_cash_register';
  static const int demoProductsCount = 50;

  // ==========================================
  // EXPRESIONES REGULARES
  // ==========================================
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );
  static final RegExp priceRegex = RegExp(
    r'^\d+(\.\d{1,2})?$',
  );

  // ==========================================
  // MENSAJES DE ERROR COMUNES
  // ==========================================
  static const Map<String, String> errorMessages = {
    'network': 'Error de conexión. Verifique su internet.',
    'timeout': 'Tiempo de espera agotado. Intente nuevamente.',
    'unauthorized': 'No tiene permisos para realizar esta acción.',
    'notFound': 'El recurso solicitado no fue encontrado.',
    'serverError': 'Error interno del servidor. Intente más tarde.',
    'invalidData': 'Los datos proporcionados no son válidos.',
    'offline': 'Sin conexión a internet.',
  };

  // ==========================================
  // ICONOS POR DEFECTO
  // ==========================================
  static const String defaultProductImage = 'assets/product_default.png';
  static const String defaultUserImage = 'assets/user_default.png';
  static const String appLogo = 'assets/launcher.png';

  // ==========================================
  // CONFIGURACIÓN DE FORMATEO
  // ==========================================
  static const String defaultCurrency = '\$';
  static const String defaultLocale = 'es_AR';
  static const int defaultDecimalPlaces = 2;

  // ==========================================
  // URLs Y ENLACES
  // ==========================================
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportEmail = 'support@example.com';
  static const String helpUrl = 'https://example.com/help';
}
