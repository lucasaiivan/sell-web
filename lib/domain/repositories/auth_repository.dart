import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthProfile?> signInWithGoogle();
  Future<AuthProfile?> signInSilently();
  Future<void> signOut();
  Stream<AuthProfile?> get user;

  /// Inicia sesión anónima en Firebase
  Future<AuthProfile?> signInAnonymously();
}
