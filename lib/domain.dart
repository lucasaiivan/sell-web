// Dominio: Definición de la entidad User y el caso de uso para autenticación
abstract class AuthRepository {
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get user;
}

class User {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  User({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}

class SignInWithGoogleUseCase {
  final AuthRepository repository;
  SignInWithGoogleUseCase(this.repository);
  Future<User?> call() => repository.signInWithGoogle();
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase(this.repository);
  Future<void> call() => repository.signOut();
}

class GetUserStreamUseCase {
  final AuthRepository repository;
  GetUserStreamUseCase(this.repository);
  Stream<User?> call() => repository.user;
}
