import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/core/services/demo_account/generators/catalogue_demo_generator.dart';
import 'package:sellweb/core/services/demo_account/generators/users_demo_generator.dart';
import 'package:sellweb/core/services/demo_account/generators/sales_demo_generator.dart';
import 'package:sellweb/core/services/demo_account/generators/cash_demo_generator.dart';

/// Servicio centralizado para obtener todos los datos demo del modo invitado
///
/// **Responsabilidad:**
/// - Proveer acceso unificado a todos los datos de prueba
/// - Delegar generación a generadores especializados
/// - Mantener coherencia entre datos relacionados
///
/// **Uso:**
/// ```dart
/// final service = DemoAccountService();
/// final products = service.products;
/// final tickets = service.getTickets(scope: DemoTicketScope.annual);
/// ```
///
/// **Estructura interna:**
/// - Singleton pattern para instancia única
/// - Generadores modulares por dominio
/// - Configuración centralizada
class DemoAccountService {
  // ==========================================
  // SINGLETON PATTERN
  // ==========================================

  static final DemoAccountService _instance = DemoAccountService._internal();
  
  /// Factory constructor que retorna la instancia singleton
  factory DemoAccountService() => _instance;
  
  /// Constructor privado
  DemoAccountService._internal();

  // ==========================================
  // CACHÉ DE DATOS (Lazy Loading)
  // ==========================================
  
  /// Caché de productos (generados solo una vez)
  List<ProductCatalogue>? _cachedProducts;
  
  /// Caché de categorías (generadas solo una vez)
  List<Category>? _cachedCategories;
  
  /// Caché de proveedores (generados solo una vez)
  List<Provider>? _cachedProviders;
  
  /// Caché de marcas (generadas solo una vez)
  List<Mark>? _cachedBrands;
  
  /// Caché de usuarios admin (generados solo una vez)
  List<AdminProfile>? _cachedAdminUsers;
  
  /// Caché de cuenta demo (generada solo una vez)
  AccountProfile? _cachedAccount;
  
  /// Caché de perfil admin actual (generado solo una vez)
  AdminProfile? _cachedAdminProfile;
  
  /// Caché de tickets por scope (generados solo una vez por scope)
  final Map<DemoTicketScope, List<TicketModel>> _cachedTickets = {};
  
  /// Caché de arqueos de caja (generados solo una vez)
  List<CashRegister>? _cachedCashRegisters;

  // ==========================================
  // CATÁLOGO
  // ==========================================

  /// Obtiene lista de productos demo (100 productos)
  ///
  /// **Retorna:** Lista de productos con categorías, marcas y proveedores coherentes
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<ProductCatalogue> get products {
    _cachedProducts ??= CatalogueDemoGenerator.generateDemoProducts();
    return _cachedProducts!;
  }

  /// Obtiene lista de categorías demo (12 categorías)
  ///
  /// **Retorna:** Lista de categorías como entidades
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<Category> get categories {
    _cachedCategories ??= CatalogueDemoGenerator.generateDemoCategories();
    return _cachedCategories!;
  }

  /// Obtiene lista de proveedores demo (~36 proveedores)
  ///
  /// **Retorna:** Lista de proveedores únicos como entidades
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<Provider> get providers {
    _cachedProviders ??= CatalogueDemoGenerator.generateDemoProviders();
    return _cachedProviders!;
  }

  /// Obtiene lista de marcas demo (~60 marcas)
  ///
  /// **Retorna:** Lista de marcas únicas como entidades
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<Mark> get brands {
    _cachedBrands ??= CatalogueDemoGenerator.generateDemoBrands();
    return _cachedBrands!;
  }

  // ==========================================
  // USUARIOS
  // ==========================================

  /// Obtiene lista de usuarios admin demo (2 usuarios)
  ///
  /// **Retorna:** Lista con Superusuario y Empleado
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<AdminProfile> get adminUsers {
    _cachedAdminUsers ??= UsersDemoGenerator.generateDemoAdminUsers();
    return _cachedAdminUsers!;
  }

  /// Obtiene cuenta demo (AccountProfile)
  ///
  /// **Retorna:** Perfil de la cuenta demo del negocio
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  AccountProfile get account {
    _cachedAccount ??= UsersDemoGenerator.generateDemoAccount();
    return _cachedAccount!;
  }

  /// Obtiene perfil admin demo para sesión de invitado
  ///
  /// **Retorna:** AdminProfile con todos los permisos habilitados
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  AdminProfile get currentAdminProfile {
    _cachedAdminProfile ??= UsersDemoGenerator.generateDemoAdminProfile();
    return _cachedAdminProfile!;
  }

  // ==========================================
  // VENTAS/TRANSACCIONES
  // ==========================================

  /// Obtiene tickets/transacciones demo según scope
  ///
  /// **Parámetros:**
  /// - `scope`: [DemoTicketScope.monthly] para 150 tickets (30 días)
  ///            [DemoTicketScope.annual] para 500 tickets (365 días)
  ///
  /// **Retorna:** Lista de tickets generados según el alcance
  /// **Optimización:** Usa caché lazy loading por scope (genera solo en primer acceso por cada scope)
  List<TicketModel> getTickets({
    DemoTicketScope scope = DemoTicketScope.monthly,
  }) {
    _cachedTickets[scope] ??= SalesDemoGenerator.generateDemoTickets(scope: scope);
    return _cachedTickets[scope]!;
  }

  // ==========================================
  // CAJA
  // ==========================================

  /// Obtiene arqueos de caja demo (últimos 15 días)
  ///
  /// **Retorna:** Lista de arqueos con métricas coherentes
  /// **Optimización:** Usa caché lazy loading (genera solo en primer acceso)
  List<CashRegister> get cashRegisters {
    _cachedCashRegisters ??= CashDemoGenerator.generateDemoCashRegisters();
    return _cachedCashRegisters!;
  }

  // ==========================================
  // MÉTODO DE CONVENIENCIA
  // ==========================================

  /// Obtiene todos los datos demo en una sola estructura
  ///
  /// **Retorna:** [DemoAccountData] con todos los datos organizados
  DemoAccountData getAllData() => DemoAccountData(
    products: products,
    categories: categories,
    providers: providers,
    brands: brands,
    users: adminUsers,
    account: account,
    adminProfile: currentAdminProfile,
    monthlyTickets: getTickets(scope: DemoTicketScope.monthly),
    annualTickets: getTickets(scope: DemoTicketScope.annual),
    cashRegisters: cashRegisters,
  );

  // ==========================================
  // GESTIÓN DE CACHÉ
  // ==========================================

  /// Limpia todo el caché de datos demo
  ///
  /// **Uso:** Llamar cuando el usuario cambia de cuenta demo a cuenta real,
  /// o cuando se necesita regenerar los datos (útil para testing).
  ///
  /// **Efecto:** Fuerza la regeneración de datos en el próximo acceso.
  void clearCache() {
    _cachedProducts = null;
    _cachedCategories = null;
    _cachedProviders = null;
    _cachedBrands = null;
    _cachedAdminUsers = null;
    _cachedAccount = null;
    _cachedAdminProfile = null;
    _cachedTickets.clear();
    _cachedCashRegisters = null;
  }
}

// ==========================================
// CLASE DE DATOS CONSOLIDADOS
// ==========================================

/// Estructura que contiene todos los datos demo organizados
class DemoAccountData {
  final List<ProductCatalogue> products;
  final List<Category> categories;
  final List<Provider> providers;
  final List<Mark> brands;
  final List<AdminProfile> users;
  final AccountProfile account;
  final AdminProfile adminProfile;
  final List<TicketModel> monthlyTickets;
  final List<TicketModel> annualTickets;
  final List<CashRegister> cashRegisters;

  DemoAccountData({
    required this.products,
    required this.categories,
    required this.providers,
    required this.brands,
    required this.users,
    required this.account,
    required this.adminProfile,
    required this.monthlyTickets,
    required this.annualTickets,
    required this.cashRegisters,
  });

  /// Resumen de datos disponibles
  Map<String, int> get summary => {
    'productos': products.length,
    'categorías': categories.length,
    'proveedores': providers.length,
    'marcas': brands.length,
    'usuarios': users.length,
    'tickets_mensuales': monthlyTickets.length,
    'tickets_anuales': annualTickets.length,
    'arqueos': cashRegisters.length,
  };

  @override
  String toString() {
    return 'DemoAccountData(${summary.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }
}
