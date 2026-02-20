
import 'package:injectable/injectable.dart';
import '../repositories/cash_register_repository.dart';

@lazySingleton
class GetTodayTransactionsStreamUseCase {
  final CashRegisterRepository _repository;

  GetTodayTransactionsStreamUseCase(this._repository);

  Stream<List<Map<String, dynamic>>> call({
    required String accountId,
    String cashRegisterId = '',
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _repository
        .getTransactionsStream(
      accountId,
      startDate: startOfDay,
      endDate: endOfDay,
    )
        .map((todayTransactions) {
      if (cashRegisterId.isNotEmpty) {
        return todayTransactions.where((transaction) {
          return transaction['cashRegisterId'] == cashRegisterId;
        }).toList();
      }
      return todayTransactions;
    });
  }
}
