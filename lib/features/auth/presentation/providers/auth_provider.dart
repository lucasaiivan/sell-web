import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/auth_profile.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/entities/admin_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_in_silently_usecase.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_user_stream_usecase.dart';
import '../../domain/usecases/get_user_accounts_usecase.dart';
import '../../domain/usecases/create_business_account_usecase.dart';
import '../../domain/usecases/update_business_account_usecase.dart';

import '../../domain/usecases/delete_business_account_usecase.dart';
import '../../domain/usecases/delete_user_account_usecase.dart';

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
  final CreateBusinessAccountUseCase _createBusinessAccountUseCase;
  final UpdateBusinessAccountUseCase _updateBusinessAccountUseCase;
  final DeleteBusinessAccountUseCase _deleteBusinessAccountUseCase;
  final DeleteUserAccountUseCase _deleteUserAccountUseCase;

  final AuthRepository _authRepository;

  // Exponer repository para uso en widgets (ej: UsernameTextField)
  AuthRepository get authRepository => _authRepository;

  GetUserAccountsUseCase get getUserAccountsUseCase => _getUserAccountsUseCase;

  // Stream subscription para poder cancelarla en dispose
  StreamSubscription<AuthProfile?>? _userStreamSubscription;
  bool _isDisposed = false;

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
    this._createBusinessAccountUseCase,
    this._updateBusinessAccountUseCase,
    this._deleteBusinessAccountUseCase,
    this._deleteUserAccountUseCase,

    this._authRepository,
  ) {
    debugPrint('🚀 [AuthProvider] Constructor - Inicializando...');

    // Escucha los cambios en el usuario autenticado y actualiza el estado
    _userStreamSubscription = _getUserStreamUseCase().listen((user) async {
      debugPrint(
          '👤 [AuthProvider] Stream - Usuario actualizado: ${user?.email}');

      // Verificar si el provider fue disposed antes de actualizar
      if (_isDisposed) {
        debugPrint(
            '⚠️ [AuthProvider] Provider disposed, ignorando actualización de stream');
        return;
      }

      _user = user;
      if (_user != null) {
        // Notifica a los listeners que el usuario ha cambiado
        await getUserAssociatedAccount();
      } else {
        // Si el usuario es nulo, limpia las cuentas asociadas
        _accountsAssociateds = [];
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    });

    // Inicializar estado del usuario actual (si ya está autenticado)
    _initializeCurrentUser();
  }

  @override
  void dispose() {
    debugPrint('🗑️ [AuthProvider] Disposing provider...');
    _isDisposed = true;
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa el estado si el usuario ya está autenticado
  void _initializeCurrentUser() async {
    debugPrint(
        '🔄 [AuthProvider] _initializeCurrentUser - Verificando usuario actual...');
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

    final result = await _signInWithGoogleUseCase(const NoParams());

    result.fold(
      (failure) {
        _authError = failure.message;
        debugPrint('Error en signInWithGoogle: ${failure.message}');
      },
      (user) {
        // El éxito se maneja automáticamente por el stream en el constructor
        debugPrint('✅ Inicio de sesión con Google exitoso: ${user.email}');
      },
    );

    _isSigningInWithGoogle = false;
    notifyListeners();
  }

  // Cierra sesión usando el caso de uso
  Future<void> signOut() async {
    final result = await _signOutUseCase(const NoParams());

    result.fold(
      (failure) {
        _authError = failure.message;
        debugPrint('Error en signOut: ${failure.message}');
      },
      (_) {
        // Limpiar estados al cerrar sesión
        _authError = null;
        _isSigningInWithGoogle = false;
        _isSigningInAsGuest = false;
        debugPrint('✅ Cierre de sesión exitoso');
      },
    );

    notifyListeners();
  }

  // Obtiene las cuentas asociadas al usuario actual, incluyendo demo si es anónimo
  Future<void> getUserAssociatedAccount() async {
    debugPrint('🔍 [AuthProvider] getUserAssociatedAccount - Iniciando...');
    debugPrint(
        '🔍 [AuthProvider] Usuario: ${_user?.email}, Anónimo: ${_user?.isAnonymous}');

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
      debugPrint(
          '📡 [AuthProvider] Llamando a getProfilesAccountsAssociated con email: ${_user!.email}');
      _accountsAssociateds = await _getUserAccountsUseCase
          .getProfilesAccountsAssociated(_user!.email!);
      debugPrint(
          '✅ [AuthProvider] Cuentas obtenidas: ${_accountsAssociateds.length}');
      for (var account in _accountsAssociateds) {
        debugPrint('   - ${account.name} (${account.id})');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthProvider] Error obteniendo cuentas asociadas: $e');
      debugPrint('Stack trace: $stackTrace');
      _accountsAssociateds = [];
    } finally {
      _isLoadingAccounts = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      debugPrint('🏁 [AuthProvider] getUserAssociatedAccount - Finalizado');
    }
  }

  /// Inicia sesión como invitado usando Firebase Auth anónimo con manejo de errores
  Future<void> signInAsGuest() async {
    if (_isSigningInAsGuest) return; // Prevenir múltiples llamadas simultáneas

    _isSigningInAsGuest = true;
    _authError = null;
    notifyListeners();

    final result = await _signInAnonymouslyUseCase(const NoParams());

    result.fold(
      (failure) {
        _authError = failure.message;
        debugPrint('Error en signInAsGuest: ${failure.message}');
      },
      (user) {
        _user = user;
        _accountsAssociateds = [];
        debugPrint('✅ Inicio de sesión como invitado exitoso');
      },
    );

    _isSigningInAsGuest = false;
    notifyListeners();
  }

  /// Limpia los errores de autenticación
  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  // Intenta iniciar sesión silenciosamente con Google
  Future<void> signInSilently() async {
    final result = await _signInSilentlyUseCase(const NoParams());

    result.fold(
      (failure) {
        debugPrint('signInSilently falló: ${failure.message}');
      },
      (user) {
        debugPrint('✅ signInSilently exitoso: ${user.email}');
      },
    );
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

  /// Crea una nueva cuenta comercio
  ///
  /// **Retorna:** `true` si se creó exitosamente, `false` en caso contrario
  Future<bool> createBusinessAccount(AccountProfile account) async {
    try {
      debugPrint('📝 [AuthProvider] Creando nueva cuenta: ${account.name}');

      final result = await _createBusinessAccountUseCase.call(account);

      return result.fold(
        (failure) {
          debugPrint('❌ [AuthProvider] Error al crear cuenta: ${failure.message}');
          _authError = failure.message;
          notifyListeners();
          return false;
        },
        (createdAccount) {
          debugPrint('✅ [AuthProvider] Cuenta creada: ${createdAccount.id}');
          
          // Agregar la nueva cuenta a la lista
          _accountsAssociateds.add(createdAccount);
          notifyListeners();
          
          return true;
        },
      );
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error inesperado al crear cuenta: $e');
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una cuenta comercio existente
  ///
  /// **Retorna:** `true` si se actualizó exitosamente, `false` en caso contrario
  Future<bool> updateBusinessAccount(
    AccountProfile account,
    AdminProfile currentAdmin,
  ) async {
    try {
      debugPrint('📝 [AuthProvider] Actualizando cuenta: ${account.id}');

      final result = await _updateBusinessAccountUseCase.call(
        account: account,
        currentAdmin: currentAdmin,
      );

      return result.fold(
        (failure) {
          debugPrint('❌ [AuthProvider] Error al actualizar cuenta: ${failure.message}');
          _authError = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          debugPrint('✅ [AuthProvider] Cuenta actualizada: ${account.id}');
          
          // Actualizar la cuenta en la lista
          final index = _accountsAssociateds.indexWhere((a) => a.id == account.id);
          if (index != -1) {
            _accountsAssociateds[index] = account;
            notifyListeners();
          }
          
          return true;
        },
      );
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error inesperado al actualizar cuenta: $e');
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Construye una nueva cuenta de negocio con valores por defecto
  ///
  /// **Parámetros:**
  /// - `name`: Nombre del negocio
  /// - `currencySign`: Símbolo de moneda
  /// - `country`: País (opcional)
  /// - `province`: Provincia (opcional)
  /// - `town`: Ciudad (opcional)
  /// - `ownerId`: ID del propietario
  ///
  /// **Retorna:** Un nuevo `AccountProfile` con valores por defecto inicializados
  AccountProfile buildNewAccount({
    required String name,
    required String currencySign,
    required String ownerId,
    String? country,
    String? province,
    String? town,
  }) {
    final now = DateTime.now();
    return AccountProfile(
      name: name,
      currencySign: currencySign,
      country: country ?? '',
      province: province ?? '',
      town: town ?? '',
      ownerId: ownerId,
      creation: now,
      trialStart: now,
      trialEnd: now.add(const Duration(days: 30)),
    );
  }

  /// Obtiene la última cuenta creada de la lista de cuentas asociadas
  ///
  /// **Retorna:** La última cuenta en la lista, o `null` si la lista está vacía
  AccountProfile? getLatestCreatedAccount() {
    if (_accountsAssociateds.isEmpty) return null;
    return _accountsAssociateds.last;
  }

  Future<bool> deleteBusinessAccount(String accountId) async {
    try {
      debugPrint('🚨 [AuthProvider] Eliminando cuenta: $accountId');
      final result = await _deleteBusinessAccountUseCase(accountId);
      
      return result.fold(
         (failure) {
           debugPrint('❌ [AuthProvider] Error al eliminar cuenta: ${failure.message}');
           _authError = failure.message;
           notifyListeners();
           return false;
         },
         (_) {
           debugPrint('✅ [AuthProvider] Cuenta eliminada: $accountId');
           _accountsAssociateds.removeWhere((a) => a.id == accountId);
           notifyListeners();
           return true; 
         }
      );
    } catch (e) {
       debugPrint('❌ [AuthProvider] Error inesperado: $e');
       _authError = e.toString();
       notifyListeners();
       return false;
    }
  }

  Future<bool> deleteUserAccount() async {
    try {
       debugPrint('🚨 [AuthProvider] Eliminando usuario y todos sus datos');
       final result = await _deleteUserAccountUseCase();
       
       return result.fold(
         (failure) {
           debugPrint('❌ [AuthProvider] Error al eliminar usuario: ${failure.message}');
           _authError = failure.message;
           notifyListeners();
           return false;
         },
         (_) {
           debugPrint('✅ [AuthProvider] Usuario eliminado');
           _user = null;
           _accountsAssociateds = [];
           notifyListeners();
           return true;
         }
       );
    } catch (e) {
       debugPrint('❌ [AuthProvider] Error inesperado: $e');
       _authError = e.toString();
       notifyListeners();
       return false;
    }
  }


}
