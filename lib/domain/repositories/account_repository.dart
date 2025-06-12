import '../entities/user.dart';

abstract class AccountRepository {
  Future<List<AdminModel>> getUserAccounts(String email);
  Future<ProfileAccountModel?> getAccount(String accountId);
}
