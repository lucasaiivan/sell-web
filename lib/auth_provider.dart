import 'package:flutter/material.dart';
import 'domain.dart';

class AuthProvider extends ChangeNotifier {
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final GetUserStreamUseCase getUserStreamUseCase;

  User? _user;
  User? get user => _user;

  AuthProvider({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.getUserStreamUseCase,
  }) {
    getUserStreamUseCase().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    await signInWithGoogleUseCase();
  }

  Future<void> signOut() async {
    await signOutUseCase();
  }
}
