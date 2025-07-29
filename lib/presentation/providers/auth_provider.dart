import 'package:sellweb/domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/account_usecase.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  /// Retorna true si el usuario está autenticado como invitado (anónimo)
  bool get isGuest => _user?.isAnonymous == true;
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
  
  // Estados para manejar el proceso de autenticación
  bool _isSigningInWithGoogle = false;
  bool get isSigningInWithGoogle => _isSigningInWithGoogle;
  bool _isSigningInAsGuest = false;
  bool get isSigningInAsGuest => _isSigningInAsGuest;
  String? _authError;
  String? get authError => _authError;

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
    
    // REMOVIDO: No inicializar autenticación automática
    // La autenticación solo debe ocurrir cuando el usuario presione el botón
  }

  // Inicia sesión con Google usando el caso de uso con manejo de errores y estado de carga
  Future<void> signInWithGoogle() async {
    if (_isSigningInWithGoogle) return; // Prevenir múltiples llamadas simultáneas
    
    _isSigningInWithGoogle = true;
    _authError = null;
    notifyListeners();
    
    try {
      await signInWithGoogleUseCase();
      // El éxito se maneja automáticamente por el stream en el constructor
    } catch (e) {
      _authError = 'Error al iniciar sesión con Google: ${e.toString()}';
      debugPrint('Error en signInWithGoogle: $e');
    } finally {
      _isSigningInWithGoogle = false;
      notifyListeners();
    }
  }

  // Cierra sesión usando el caso de uso
  Future<void> signOut() async {
    try {
      await signOutUseCase();
      // Limpiar estados al cerrar sesión
      _authError = null;
      _isSigningInWithGoogle = false;
      _isSigningInAsGuest = false;
    } catch (e) {
      _authError = 'Error al cerrar sesión: ${e.toString()}';
      debugPrint('Error en signOut: $e');
    } finally {
      notifyListeners();
    }
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
    _accountsAssociateds = await getUserAccountsUseCase
        .getProfilesAccountsAsociateds(_user!.email!);
    _isLoadingAccounts = false;
    notifyListeners();
  }

  /// Inicia sesión como invitado usando Firebase Auth anónimo con manejo de errores
  Future<void> signInAsGuest() async {
    if (_isSigningInAsGuest) return; // Prevenir múltiples llamadas simultáneas
    
    _isSigningInAsGuest = true;
    _authError = null;
    notifyListeners();
    
    try {
      final user =
          await SignInAnonymouslyUseCase(signInWithGoogleUseCase.repository)
              .call();
      _user = user;
      _accountsAssociateds = [];
      // El notifyListeners() se maneja en el finally
    } catch (e) {
      _authError = 'Error al iniciar sesión como invitado: ${e.toString()}';
      debugPrint('Error en signInAsGuest: $e');
    } finally {
      _isSigningInAsGuest = false;
      notifyListeners();
    }
  }

  /// Limpia los errores de autenticación
  void clearAuthError() {
    _authError = null;
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
