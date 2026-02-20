/// Interface: Provider Inicializable por Cuenta
///
/// **Responsabilidad:**
/// - Define contrato para providers que necesitan inicializarse con un accountId
/// - Garantiza consistencia en el patrón de inicialización
///
/// **Implementaciones:** CatalogueProvider, CashRegisterProvider, AnalyticsProvider
abstract class InitializableProvider {
  /// Inicializa el provider para una cuenta específica
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta a inicializar
  ///
  /// **Debe:**
  /// - Suscribirse a streams de Firestore para la cuenta
  /// - Cargar estado persistido si aplica
  /// - Preparar el provider para operaciones con la cuenta
  Future<void> initialize(String accountId);

  /// Limpia recursos y cancela suscripciones
  ///
  /// **Llamado cuando:**
  /// - Se cambia de cuenta
  /// - Se cierra sesión
  /// - Se destruye el provider
  void cleanup();
}
