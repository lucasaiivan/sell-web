import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

/// Service Locator global para inyección de dependencias
final getIt = GetIt.instance;

/// Configura todas las dependencias usando injectable
@InjectableInit()
void configureDependencies() {
  getIt.init();
}

/// Módulo para registrar dependencias externas (Firebase, SharedPreferences, etc.)
@module
abstract class ExternalModule {
  /// Instancia de FirebaseFirestore
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
