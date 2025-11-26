import 'package:cloud_firestore/cloud_firestore.dart';
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
    final today = DateTime.now();
    final transactionsStream = _repository.getTransactionsStream(accountId);

    return transactionsStream.map((allTransactions) {
      final todayTransactions = allTransactions.where((transaction) {
        if (transaction['creation'] == null) return false;

        final creation = transaction['creation'] as Timestamp;
        final transactionDate = creation.toDate();

        final isToday = transactionDate.year == today.year &&
            transactionDate.month == today.month &&
            transactionDate.day == today.day;

        if (!isToday) return false;

        if (cashRegisterId.isNotEmpty) {
          return transaction['cashRegisterId'] == cashRegisterId;
        }

        return true;
      }).toList();

      return todayTransactions;
    });
  }
}
