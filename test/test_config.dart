import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Configuración global para todos los tests
/// 
/// Proporciona setup y teardown comunes para mantener tests aislados

class TestConfig {
  static final GetIt getIt = GetIt.instance;

  /// Setup que se ejecuta antes de cada test
  static void setUp() {
    // Reset GetIt para cada test
    getIt.reset();
  }

  /// Teardown que se ejecuta después de cada test
  static void tearDown() {
    // Limpiar GetIt
    getIt.reset();
  }

  /// Setup para tests que requieren DI
  static void setUpWithDI() {
    setUp();
    // Aquí se pueden registrar mocks comunes si es necesario
  }

  /// Helper para ejecutar tests con timeout personalizado
  static Future<void> runWithTimeout(
    Future<void> Function() testFunction, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await testFunction().timeout(timeout);
  }
}

/// Extension para simplificar el uso de TestConfig en tests
extension TestConfigExtension on dynamic {
  /// Setup rápido para tests
  void useTestConfig() {
    setUp(TestConfig.setUp);
    tearDown(TestConfig.tearDown);
  }

  /// Setup rápido para tests con DI
  void useTestConfigWithDI() {
    setUp(TestConfig.setUpWithDI);
    tearDown(TestConfig.tearDown);
  }
}
