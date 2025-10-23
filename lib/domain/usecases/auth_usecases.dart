import '../repositories/auth_repository.dart';
import '../entities/user.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;
  SignInWithGoogleUseCase(this.repository);
  Future<AuthProfile?> call() => repository.signInWithGoogle();
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase(this.repository);
  Future<void> call() => repository.signOut();
}

class GetUserStreamUseCase {
  final AuthRepository repository;
  GetUserStreamUseCase(this.repository);
  Stream<AuthProfile?> call() => repository.user;
}

class SignInAnonymouslyUseCase {
  final AuthRepository repository;
  SignInAnonymouslyUseCase(this.repository);

  /// Inicia sesión anónima en Firebase
  Future<AuthProfile?> call() => repository.signInAnonymously();
}

class SignInSilentlyUseCase {
  final AuthRepository repository;
  SignInSilentlyUseCase(this.repository);
  Future<AuthProfile?> call() => repository.signInSilently();
}
