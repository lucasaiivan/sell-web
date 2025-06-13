import 'package:sellweb/domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart'; 
import '../../domain/usecases/account_usecase.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {

  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final GetUserStreamUseCase getUserStreamUseCase;
  final GetUserAccountsUseCase getUserAccountsUseCase;

  UserAuth? _user;
  UserAuth? get user => _user;
  List<ProfileAccountModel> _accountsAssociateds = [];
  List<ProfileAccountModel> get accountsAssociateds => _accountsAssociateds;
  

  AuthProvider({
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.getUserStreamUseCase,
    required this.getUserAccountsUseCase,
  }) { 
    getUserStreamUseCase().listen((user) async {
      _user = user;
      if (_user != null) {
        await getUserAssociatedAccount();
      }
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    await signInWithGoogleUseCase();
  }

  Future<void> signOut() async {
    await signOutUseCase();
  }
  // Obtiene las cuentas asociadas al usuario actual
  Future<void> getUserAssociatedAccount() async {
    if (_user?.email == null) return;
    _accountsAssociateds = await getUserAccountsUseCase.getProfilesAccountsAsociateds(_user!.email!);
    notifyListeners();
  }
  /// Inicia sesión como invitado usando Firebase Auth anónimo
  Future<void> signInAsGuest() async {
    final user = await SignInAnonymouslyUseCase(signInWithGoogleUseCase.repository).call();
    _user = user;
    _accountsAssociateds = [];
    notifyListeners();
  }
 
}
