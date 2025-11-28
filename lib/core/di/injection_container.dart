import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injection_container.config.dart';

/// Service Locator global para inyección de dependencias
final getIt = GetIt.instance;

/// Configura todas las dependencias usando injectable
@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
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

  /// Instancia de SharedPreferences (async precomputed)
  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn();
}
