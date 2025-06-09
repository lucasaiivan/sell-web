import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get user;
}
