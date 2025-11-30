import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/analytics/presentation/providers/analytics_provider.dart';
import 'initializable_provider.dart';

/// Provider: Gestor de Ámbito de Cuenta
///
/// **Responsabilidad:**
/// - Gestionar el ciclo de vida de providers específicos de cuenta
/// - Inicializar y destruir providers al cambiar de cuenta
/// - Proporcionar acceso centralizado a providers de cuenta
///
/// **Dependencias:** CatalogueProvider, CashRegisterProvider, AnalyticsProvider
/// **Inyección DI:** @injectable
@injectable
class AccountScopeProvider extends ChangeNotifier {
  final CatalogueProvider catalogueProvider;
  final CashRegisterProvider cashRegisterProvider;
  final AnalyticsProvider analyticsProvider;

  String? _currentAccountId;
  bool _isInitialized = false;

  AccountScopeProvider(
    this.catalogueProvider,
    this.cashRegisterProvider,
    this.analyticsProvider,
  );

  /// ID de la cuenta actual inicializada
  String? get currentAccountId => _currentAccountId;

  /// Indica si el scope está inicializado para una cuenta
  bool get isInitialized => _isInitialized;

  /// Inicializa todos los providers para una cuenta específica
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta a inicializar
  ///
  /// **Comportamiento:**
  /// - Si ya está inicializado con esta cuenta, no hace nada
  /// - Limpia providers anteriores si había otra cuenta
  /// - Inicializa todos los providers en paralelo para la nueva cuenta
  Future<void> initializeForAccount(String accountId) async {
    if (accountId.isEmpty) return;

    // Evitar re-inicialización innecesaria
    if (_currentAccountId == accountId && _isInitialized) {
      return;
    }

    // Limpiar cuenta anterior si existe
    if (_currentAccountId != null && _currentAccountId != accountId) {
      _cleanupProviders();
    }

    _currentAccountId = accountId;
    _isInitialized = false;

    // Inicializar todos los providers en paralelo
    await Future.wait([
      _initializeProvider(catalogueProvider, accountId),
      _initializeProvider(cashRegisterProvider, accountId),
      _initializeProvider(analyticsProvider, accountId),
    ]);

    _isInitialized = true;
    notifyListeners();
  }

  /// Inicializa un provider individual manejando errores
  Future<void> _initializeProvider(
    InitializableProvider provider,
    String accountId,
  ) async {
    try {
      await provider.initialize(accountId);
    } catch (e) {
      debugPrint('❌ Error inicializando provider: $e');
      // No lanzar error, permitir que otros providers se inicialicen
    }
  }

  /// Limpia recursos de todos los providers
  ///
  /// **Estrategia:**
  /// - Llama a cleanup() para cancelar suscripciones de Firestore
  /// - NO llama a dispose() porque los providers son singleton de DI
  /// - Los providers resetean su estado interno pero NO se destruyen
  void _cleanupProviders() {
    try {
      // Todos los providers ahora implementan InitializableProvider
      catalogueProvider.cleanup();
      cashRegisterProvider.cleanup();
      analyticsProvider.cleanup();

      if (kDebugMode) {
        print('✅ AccountScopeProvider: Providers limpiados correctamente');
      }
    } catch (e) {
      debugPrint('❌ Error limpiando providers: $e');
    }
  }

  /// Resetea el scope completamente
  void reset() {
    _cleanupProviders();
    _currentAccountId = null;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupProviders();
    super.dispose();
  }
}
