import '../entities/user.dart';

abstract class AuthRepository {
  Future<UserAuth?> signInWithGoogle();
  Future<void> signOut();
  Stream<UserAuth?> get user;
}
