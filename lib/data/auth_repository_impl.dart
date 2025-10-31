import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/user.dart';

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
      if (fbUser == null) return null;

      return AuthProfile(
        uid: fbUser.uid,
        displayName: fbUser.displayName,
        email: fbUser.email,
        photoUrl: fbUser.photoURL,
      );
    } catch (e) {
      // Log detallado para debugging de errores de configuración
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
        if (fbUser == null) return null;
        return AuthProfile(
          uid: fbUser.uid,
          displayName: fbUser.displayName,
          email: fbUser.email,
          isAnonymous: fbUser.isAnonymous, // <-- Asegura que siempre se asigne
          photoUrl: fbUser.photoURL,
        );
      });

  @override
  Future<AuthProfile?> signInAnonymously() async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    final fbUser = userCredential.user;
    if (fbUser == null) return null;
    return AuthProfile(
      uid: fbUser.uid,
      displayName: 'Invitado',
      email: null,
      isAnonymous: true,
      photoUrl: fbUser.photoURL,
    );
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
      if (fbUser == null) return null;

      return AuthProfile(
        uid: fbUser.uid,
        displayName: fbUser.displayName,
        email: fbUser.email,
        photoUrl: fbUser.photoURL,
      );
    } catch (e) {
      return null;
    }
  }
}
