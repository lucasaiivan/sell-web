import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/auth_profile.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_in_silently_usecase.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_user_stream_usecase.dart';
import '../../domain/usecases/get_user_accounts_usecase.dart';

/// Provider para gestionar el estado de autenticación
///
/// **Responsabilidad:** Coordinar UI y casos de uso de autenticación
/// - Gestiona estado de usuario autenticado y cuentas asociadas
/// - Delega autenticación a UseCases
/// - Maneja estados de carga y errores para la UI
/// - No contiene lógica de negocio, solo coordinación
@injectable
class AuthProvider extends ChangeNotifier {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInSilentlyUseCase _signInSilentlyUseCase;
  final SignInAnonymouslyUseCase _signInAnonymouslyUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetUserStreamUseCase _getUserStreamUseCase;
  final GetUserAccountsUseCase _getUserAccountsUseCase;

  GetUserAccountsUseCase get getUserAccountsUseCase => _getUserAccountsUseCase;

  AuthProfile? _user;
  AuthProfile? get user => _user;
  
  List<AccountProfile> _accountsAssociateds = [];
  List<AccountProfile> get accountsAssociateds => _accountsAssociateds;
  
  bool _isLoadingAccounts = false;
  bool get isLoadingAccounts => _isLoadingAccounts;

  // Estados para manejar el proceso de autenticación
  bool _isSigningInWithGoogle = false;
  bool get isSigningInWithGoogle => _isSigningInWithGoogle;
  
  bool _isSigningInAsGuest = false;
  bool get isSigningInAsGuest => _isSigningInAsGuest;
  
  String? _authError;
  String? get authError => _authError;

  /// Retorna true si el usuario está autenticado como invitado (anónimo)
  bool get isGuest => _user?.isAnonymous == true;

  /// Retorna la lista de cuentas incluyendo la cuenta demo si corresponde
  List<AccountProfile> get accountsWithDemo {
    return _getUserAccountsUseCase.getAccountsWithDemo(
      _accountsAssociateds,
      isAnonymous: isGuest,
    );
  }

  AuthProvider(
    this._signInWithGoogleUseCase,
    this._signInSilentlyUseCase,
    this._signInAnonymouslyUseCase,
    this._signOutUseCase,
    this._getUserStreamUseCase,
    this._getUserAccountsUseCase,
  ) {
    debugPrint('🚀 [AuthProvider] Constructor - Inicializando...');
    
    // Escucha los cambios en el usuario autenticado y actualiza el estado
    _getUserStreamUseCase().listen((user) async {
      debugPrint('👤 [AuthProvider] Stream - Usuario actualizado: ${user?.email}');
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
    
    // Inicializar estado del usuario actual (si ya está autenticado)
    _initializeCurrentUser();
  }
  
  /// Inicializa el estado si el usuario ya está autenticado
  void _initializeCurrentUser() async {
    debugPrint('🔄 [AuthProvider] _initializeCurrentUser - Verificando usuario actual...');
    // El stream ya maneja la inicialización, este método es un placeholder
    // por si se necesita lógica adicional en el futuro
  }

  // Inicia sesión con Google usando el caso de uso con manejo de errores y estado de carga
  Future<void> signInWithGoogle() async {
    if (_isSigningInWithGoogle) {
      return; // Prevenir múltiples llamadas simultáneas
    }

    _isSigningInWithGoogle = true;
    _authError = null;
    notifyListeners();

    try {
      await _signInWithGoogleUseCase();
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
      await _signOutUseCase();
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
    debugPrint('🔍 [AuthProvider] getUserAssociatedAccount - Iniciando...');
    debugPrint('🔍 [AuthProvider] Usuario: ${_user?.email}, Anónimo: ${_user?.isAnonymous}');
    
    if (_user == null) {
      debugPrint('⚠️ [AuthProvider] Usuario es null, abortando');
      return;
    }
    
    _isLoadingAccounts = true;
    notifyListeners();
    
    if (_user!.isAnonymous == true) {
      debugPrint('👤 [AuthProvider] Usuario anónimo detectado, sin cuentas');
      _accountsAssociateds = [];
      _isLoadingAccounts = false;
      notifyListeners();
      return;
    }
    
    if (_user?.email == null) {
      debugPrint('⚠️ [AuthProvider] Email es null, abortando');
      _isLoadingAccounts = false;
      notifyListeners();
      return;
    }
    
    try {
      debugPrint('📡 [AuthProvider] Llamando a getProfilesAccountsAssociated con email: ${_user!.email}');
      _accountsAssociateds = await _getUserAccountsUseCase
          .getProfilesAccountsAssociated(_user!.email!);
      debugPrint('✅ [AuthProvider] Cuentas obtenidas: ${_accountsAssociateds.length}');
      for (var account in _accountsAssociateds) {
        debugPrint('   - ${account.name} (${account.id})');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthProvider] Error obteniendo cuentas asociadas: $e');
      debugPrint('Stack trace: $stackTrace');
      _accountsAssociateds = [];
    } finally {
      _isLoadingAccounts = false;
      notifyListeners();
      debugPrint('🏁 [AuthProvider] getUserAssociatedAccount - Finalizado');
    }
  }

  /// Inicia sesión como invitado usando Firebase Auth anónimo con manejo de errores
  Future<void> signInAsGuest() async {
    if (_isSigningInAsGuest) return; // Prevenir múltiples llamadas simultáneas

    _isSigningInAsGuest = true;
    _authError = null;
    notifyListeners();

    try {
      final user = await _signInAnonymouslyUseCase();
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
    await _signInSilentlyUseCase();
  }

  // ProfileAccountModel : devuelve los datos del perfil de la cuenta asociada del id pasado por parametro
  AccountProfile? getProfileAccountById(String id) {
    try {
      return _accountsAssociateds.firstWhere(
        (account) => account.id == id,
      );
    } catch (_) {
      // Si no se encuentra, retornar una cuenta vacía con fecha actual
      return AccountProfile(
        creation: DateTime.now(),
        trialStart: DateTime.now(),
        trialEnd: DateTime.now(),
      );
    }
  }
}
