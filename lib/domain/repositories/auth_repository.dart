import '../entities/user.dart';

abstract class AuthRepository {
  Future<UserAuth?> signInWithGoogle();
  Future<UserAuth?> signInSilently();
  Future<void> signOut();
  Stream<UserAuth?> get user;

  /// Inicia sesión anónima en Firebase
  Future<UserAuth?> signInAnonymously();
}
