import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Instancia de FirebaseStorage
  @lazySingleton
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Instancia de AppDataPersistenceService
  @lazySingleton
  AppDataPersistenceService get appDataPersistenceService => AppDataPersistenceService.instance;

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn();
}
