import '../entities/admin_profile.dart';
import '../entities/account_profile.dart';

/// Contrato del repositorio de cuentas
///
/// Define las operaciones para gestionar cuentas y perfiles de administrador.
/// Esta es una interfaz pura sin implementación.
///
/// **Responsabilidad:**
/// - Define contratos para operaciones de cuentas
/// - Gestión de cuentas asociadas a un usuario
/// - Persistencia de selección de cuenta actual
/// - No contiene lógica de negocio ni implementación
/// - Es implementado por AccountRepositoryImpl en la capa de datos
///
/// **Operaciones:**
/// - `getUserAccounts`: Obtiene las cuentas asociadas a un email
/// - `getAccount`: Obtiene datos de una cuenta específica
/// - `saveSelectedAccountId`: Guarda la cuenta seleccionada actualmente
/// - `getSelectedAccountId`: Obtiene la cuenta seleccionada
/// - `removeSelectedAccountId`: Elimina la selección de cuenta
abstract class AccountRepository {
  /// Obtiene todas las cuentas (AdminProfile) asociadas a un email
  ///
  /// Retorna lista de perfiles de administrador donde el usuario tiene acceso
  /// [email] Email del usuario autenticado
  Future<List<AdminProfile>> getUserAccounts(String email);

  /// Obtiene los datos completos de una cuenta específica
  ///
  /// Retorna el perfil de la cuenta o null si no existe
  /// [accountId] ID de la cuenta a obtener
  Future<AccountProfile?> getAccount(String accountId);

  /// Guarda el ID de la cuenta seleccionada actualmente
  ///
  /// Persiste localmente para recordar la última cuenta usada
  /// [accountId] ID de la cuenta a guardar como seleccionada
  Future<void> saveSelectedAccountId(String accountId);

  /// Obtiene el ID de la cuenta seleccionada actualmente
  ///
  /// Retorna el ID guardado o null si no hay ninguna seleccionada
  Future<String?> getSelectedAccountId();

  /// Elimina el ID de la cuenta seleccionada
  ///
  /// Limpia la persistencia local de la cuenta seleccionada
  Future<void> removeSelectedAccountId();
}
