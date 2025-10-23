import '../entities/user.dart';

abstract class AccountRepository {
  Future<List<AdminProfile>> getUserAccounts(String email);
  Future<AccountProfile?> getAccount(String accountId);

  /// Guarda el ID de la cuenta seleccionada actualmente
  Future<void> saveSelectedAccountId(String accountId);

  /// Obtiene el ID de la cuenta seleccionada actualmente
  Future<String?> getSelectedAccountId();

  /// Elimina el ID de la cuenta seleccionada
  Future<void> removeSelectedAccountId();
}
