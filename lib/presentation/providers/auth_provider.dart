import 'package:sellweb/domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart'; 
import '../../domain/usecases/account_usecase.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {

  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInSilentlyUseCase signInSilentlyUseCase;
  final SignOutUseCase signOutUseCase;
  final GetUserStreamUseCase getUserStreamUseCase;
  final GetUserAccountsUseCase getUserAccountsUseCase;

  UserAuth? _user;
  UserAuth? get user => _user;
  List<ProfileAccountModel> _accountsAssociateds = [];
  List<ProfileAccountModel> get accountsAssociateds => _accountsAssociateds;
  bool _isLoadingAccounts = false;
  bool get isLoadingAccounts => _isLoadingAccounts;
  

  AuthProvider({
    required this.signInWithGoogleUseCase,
    required this.signInSilentlyUseCase,
    required this.signOutUseCase,
    required this.getUserStreamUseCase,
    required this.getUserAccountsUseCase,
  }) { 
    // Escucha los cambios en el usuario autenticado y actualiza el estado
    getUserStreamUseCase().listen((user) async {
      _user = user;
      if (_user != null) {
        // Notifica a los listeners que el usuario ha cambiado
        await getUserAssociatedAccount();
      } else {
        // Si el usuario es nulo, limpia las cuentas asociadas
        _accountsAssociateds = [];
        notifyListeners();
      }
    });
    
    // Intenta autenticación silenciosa al inicializar
    _initializeSilentSignIn();
  }
  
  /// Inicializa autenticación silenciosa para mejorar UX
  Future<void> _initializeSilentSignIn() async {
    await signInSilently();
  }
  // Inicia sesión con Google usando el caso de uso
  Future<void> signInWithGoogle() async {
    await signInWithGoogleUseCase();
  }
  // Cierra sesión usando el caso de uso
  Future<void> signOut() async {
    await signOutUseCase();
  }
  // Obtiene las cuentas asociadas al usuario actual, incluyendo demo si es anónimo
  Future<void> getUserAssociatedAccount() async {
    if (_user == null) return;
    _isLoadingAccounts = true;
    notifyListeners();
    if (_user!.isAnonymous == true) {
      _accountsAssociateds = [];
      _isLoadingAccounts = false;
      notifyListeners();
      return;
    }
    if (_user?.email == null) {
      _isLoadingAccounts = false;
      notifyListeners();
      return;
    }
    _accountsAssociateds = await getUserAccountsUseCase.getProfilesAccountsAsociateds(_user!.email!);
    _isLoadingAccounts = false;
    notifyListeners();
  }
  /// Inicia sesión como invitado usando Firebase Auth anónimo
  Future<void> signInAsGuest() async {
    final user = await SignInAnonymouslyUseCase(signInWithGoogleUseCase.repository).call();
    _user = user;
    _accountsAssociateds = [];
    notifyListeners();
  }
  // Intenta iniciar sesión silenciosamente con Google
  Future<void> signInSilently() async {
    await signInSilentlyUseCase();
  }
  // ProfileAccountModel : devuelve los datos del perfil de la cuenta asociada del id pasado por parametro
  ProfileAccountModel? getProfileAccountById(String id) {
    return _accountsAssociateds.firstWhere(
      (account) => account.id == id,
      orElse: () => ProfileAccountModel(),
    );  
  }
}
