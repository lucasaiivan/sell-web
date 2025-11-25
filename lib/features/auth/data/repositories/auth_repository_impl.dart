import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_profile.dart';
import '../models/auth_profile_model.dart';

/// Implementación del repositorio de autenticación
///
/// Utiliza Firebase Auth y Google Sign In para gestionar la autenticación.
/// Convierte los usuarios de Firebase a entidades de dominio [AuthProfile].
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn);

  @override
  Future<AuthProfile?> signInWithGoogle() async {
    try {
      // Usar signInSilently primero para verificar si ya hay sesión activa
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // Si no hay sesión silenciosa, intentar login interactivo
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      
      return AuthProfileModel.fromFirebaseUser(fbUser).toEntity();
    } catch (e) {
      // TODO: Implement proper logging system
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Stream<AuthProfile?> get user =>
      _firebaseAuth.authStateChanges().map((fbUser) {
        print('🔔 [AuthRepositoryImpl] authStateChanges - fbUser: ${fbUser?.email}, uid: ${fbUser?.uid}');
        if (fbUser == null) {
          print('❌ [AuthRepositoryImpl] Usuario es null');
          return null;
        }
        final authProfile = AuthProfileModel.fromFirebaseUser(fbUser).toEntity();
        print('✅ [AuthRepositoryImpl] AuthProfile creado: ${authProfile.email}');
        return authProfile;
      });

  @override
  Future<AuthProfile?> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final fbUser = userCredential.user;
      return AuthProfileModel.fromFirebaseUser(fbUser).toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthProfile?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      
      return AuthProfileModel.fromFirebaseUser(fbUser).toEntity();
    } catch (e) {
      return null;
    }
  }
}
