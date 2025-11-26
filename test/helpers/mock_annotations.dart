import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Catalogue Feature
import 'package:sellweb/features/catalogue/domain/repositories/catalogue_repository.dart';
import 'package:sellweb/features/catalogue/data/datasources/catalogue_remote_datasource.dart';

// Auth Feature
import 'package:sellweb/features/auth/domain/repositories/auth_repository.dart';
import 'package:sellweb/features/auth/domain/repositories/account_repository.dart';

/// Anotaciones de Mockito para generar mocks automáticamente
/// 
/// Ejecutar: flutter pub run build_runner build --delete-conflicting-outputs
/// 
/// Esto generará: test/helpers/mock_annotations.mocks.dart
@GenerateMocks([
  // External Dependencies
  FirebaseFirestore,
  FirebaseAuth,
  SharedPreferences,
  
  // Catalogue Feature - Repositories
  CatalogueRepository,
  
  // Catalogue Feature - DataSources
  CatalogueRemoteDataSource,
  
  // Auth Feature - Repositories
  AuthRepository,
  AccountRepository,
])
void main() {}
