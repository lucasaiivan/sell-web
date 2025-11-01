import '../../domain/entities/cash_register_model.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/repositories/cash_register_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Casos de uso para el sistema de caja registradora
///
/// RESPONSABILIDAD:
/// - Gestión de cajas (abrir, cerrar, consultar)
/// - Flujos de caja (ingresos, egresos, ventas)
/// - Persistencia de tickets en Firebase
/// - Historial de transacciones
/// - Anulación de tickets
/// - Análisis y reportes
///
/// Para gestión temporal de tickets (productos, cálculos), ver SellUsecases
class CashRegisterUsecases {
  final CashRegisterRepository _repository;

  CashRegisterUsecases(this._repository);

  // ==========================================
  // GESTIÓN DE CAJAS ACTIVAS
  // ==========================================

  /// Abre una nueva caja registradora
  Future<CashRegister> openCashRegister({
    required String accountId,
    required String description,
    required double initialCash,
    required String cashierId,
    required String cashierName,
  }) async {
    if (description.trim().isEmpty) {
      throw Exception('La descripción es obligatoria');
    }

    if (initialCash < 0) {
      throw Exception('El monto inicial no puede ser negativo');
    }

    if (accountId.trim().isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío');
    }

    if (cashierId.trim().isEmpty) {
      throw Exception('El ID del cajero no puede estar vacío');
    }

    if (cashierName.trim().isEmpty) {
      throw Exception('El nombre del cajero no puede estar vacío');
    }

    final finalDescription = description.trim().isEmpty
        ? 'Caja ${DateTime.now().day}/${DateTime.now().month}'
        : description.trim();

    return await _repository.openCashRegister(
      accountId: accountId,
      description: finalDescription,
      initialCash: initialCash,
      cashierId: cashierId,
      cashierName: cashierName,
    );
  }

  /// Cierra una caja registradora
  Future<CashRegister> closeCashRegister({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  }) async {
    if (accountId.trim().isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío');
    }

    if (cashRegisterId.trim().isEmpty) {
      throw Exception('El ID de la caja registradora no puede estar vacío');
    }

    if (finalBalance < 0) {
      throw Exception('El balance final no puede ser negativo');
    }

    return await _repository.closeCashRegister(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      finalBalance: finalBalance,
    );
  }

  /// Obtiene todas las cajas registradoras activas
  Future<List<CashRegister>> getActiveCashRegisters(String accountId) async {
    return await _repository.getActiveCashRegisters(accountId);
  }

  /// Stream de cajas registradoras activas
  Stream<List<CashRegister>> getActiveCashRegistersStream(String accountId) {
    return _repository.getActiveCashRegistersStream(accountId);
  }

  // ==========================================
  // GESTIÓN DE FLUJOS DE CAJA
  // ==========================================

  /// Registra un ingreso de caja
  Future<void> addCashInflow({
    required String accountId,
    required String cashRegisterId,
    required String description,
    required double amount,
    required String userId,
  }) async {
    if (amount <= 0) {
      throw Exception('El monto del ingreso debe ser mayor a cero');
    }

    if (description.trim().isEmpty) {
      throw Exception('La descripción del movimiento es obligatoria');
    }

    final cashFlow = CashFlow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      description: description,
      amount: amount,
      date: DateTime.now(),
    );

    await _repository.addCashInflow(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      cashFlow: cashFlow,
    );
  }

  /// Registra un egreso de caja
  Future<void> addCashOutflow({
    required String accountId,
    required String cashRegisterId,
    required String description,
    required double amount,
    required String userId,
  }) async {
    if (amount <= 0) {
      throw Exception('El monto del egreso debe ser mayor a cero');
    }

    if (description.trim().isEmpty) {
      throw Exception('La descripción del movimiento es obligatoria');
    }

    final cashFlow = CashFlow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      description: description,
      amount: amount,
      date: DateTime.now(),
    );

    await _repository.addCashOutflow(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      cashFlow: cashFlow,
    );
  }

  /// Registra una venta en la caja registradora
  ///
  /// ⚠️ IMPORTANTE: Llamar DESPUÉS de guardar el ticket en Firebase
  Future<void> cashRegisterSale({
    required String accountId,
    required String cashRegisterId,
    required double saleAmount,
    required double discountAmount,
  }) async {
    if (saleAmount < 0) {
      throw Exception('El monto de la venta no puede ser negativo');
    }

    if (discountAmount < 0) {
      throw Exception('El monto del descuento no puede ser negativo');
    }

    await _repository.updateSalesAndBilling(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      billingIncrement: saleAmount,
      discountIncrement: discountAmount,
    );
  }

  // ==========================================
  // CONSULTAS DEL HISTORIAL
  // ==========================================

  /// Obtiene todo el historial de arqueos de caja
  Future<List<CashRegister>> getCashRegisterHistory(String accountId) async {
    return await _repository.getCashRegisterHistory(accountId);
  }

  /// Stream del historial de arqueos de caja
  Stream<List<CashRegister>> getCashRegisterHistoryStream(String accountId) {
    return _repository.getCashRegisterHistoryStream(accountId);
  }

  /// Obtiene los arqueos de los últimos 7 días
  Future<List<CashRegister>> getLastWeekCashRegisters(String accountId) async {
    return await _repository.getCashRegisterByDays(accountId, 7);
  }

  /// Obtiene los arqueos del último mes (30 días)
  Future<List<CashRegister>> getLastMonthCashRegisters(String accountId) async {
    return await _repository.getCashRegisterByDays(accountId, 30);
  }

  /// Obtiene los arqueos del mes pasado
  Future<List<CashRegister>> getPreviousMonthCashRegisters(
      String accountId) async {
    final now = DateTime.now();
    final endDate =
        DateTime(now.year, now.month, 1); // Primer día del mes actual
    final startDate =
        DateTime(now.year, now.month - 1, 1); // Primer día del mes pasado

    return await _repository.getCashRegisterByDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Obtiene los arqueos de hoy
  Future<List<CashRegister>> getTodayCashRegisters(String accountId) async {
    return await _repository.getTodayCashRegisters(accountId);
  }

  /// Obtiene arqueos por rango de fechas personalizado
  Future<List<CashRegister>> getCashRegistersByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (startDate.isAfter(endDate)) {
      throw Exception(
          'La fecha de inicio no puede ser posterior a la fecha de fin');
    }

    return await _repository.getCashRegisterByDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ==========================================
  // ANÁLISIS Y REPORTES
  // ==========================================

  /// Calcula el total de ventas en un periodo
  Future<Map<String, dynamic>> getSalesReport({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final cashRegisters = await getCashRegistersByDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );

    double totalBilling = 0;
    double totalDiscount = 0;
    int totalSales = 0;
    int totalCashRegisters = cashRegisters.length;

    for (final cashRegister in cashRegisters) {
      totalBilling += cashRegister.billing;
      totalDiscount += cashRegister.discount;
      totalSales += cashRegister.sales;
    }

    return {
      'period': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      'totalBilling': totalBilling,
      'totalDiscount': totalDiscount,
      'totalSales': totalSales,
      'totalCashRegisters': totalCashRegisters,
      'averageSaleAmount': totalSales > 0 ? totalBilling / totalSales : 0,
      'netBilling': totalBilling - totalDiscount,
    };
  }

  /// Obtiene un resumen diario de las operaciones
  Future<Map<String, dynamic>> getDailySummary(String accountId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getSalesReport(
      accountId: accountId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // ==========================================
  // GESTIÓN DE TICKETS Y TRANSACCIONES
  // ==========================================

  /// Guarda un ticket en el historial de transacciones
  Future<void> saveTicketToTransactionHistory({
    required String accountId,
    required TicketModel ticket,
  }) async {
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío');
    }

    if (ticket.id.isEmpty) {
      throw Exception('El ID del ticket no puede estar vacío');
    }

    if (ticket.sellerId.isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe contener al menos un producto');
    }

    if (ticket.priceTotal <= 0) {
      throw Exception('El monto total de la venta debe ser mayor a cero');
    }

    final transactionData = ticket.toMap();

    await _repository.saveTicketTransaction(
      accountId: accountId,
      ticketId: ticket.id,
      transactionData: transactionData,
    );
  }

  /// Procesa la anulación de un ticket
  Future<TicketModel> processTicketAnnullment({
    required String accountId,
    required TicketModel ticket,
    CashRegister? activeCashRegister,
  }) async {
    if (ticket.annulled) {
      throw Exception('El ticket ya está anulado');
    }

    if (ticket.id.trim().isEmpty) {
      throw Exception('El ticket debe tener un ID válido');
    }

    final annulledTicket = ticket.copyWith(annulled: true);

    await _repository.saveTicketTransaction(
      accountId: accountId,
      ticketId: ticket.id,
      transactionData: annulledTicket.toMap(),
    );

    if (activeCashRegister != null &&
        ticket.cashRegisterId == activeCashRegister.id) {
      await _repository.updateBillingOnAnnullment(
        accountId: accountId,
        cashRegisterId: activeCashRegister.id,
        billingDecrement: ticket.priceTotal,
        discountDecrement: ticket.getDiscountAmount,
      );
    }

    return annulledTicket;
  }

  /// Obtiene las transacciones del día actual
  Future<List<Map<String, dynamic>>> getTodayTransactions({
    required String accountId,
    String cashRegisterId = '',
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await getTransactionsByDateRange(
      accountId: accountId,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    if (cashRegisterId.isNotEmpty) {
      return result
          .where((doc) => doc['cashRegisterId'] == cashRegisterId)
          .toList();
    }
    return result;
  }

  /// Stream de transacciones del día actual con actualizaciones en tiempo real
  Stream<List<Map<String, dynamic>>> getTodayTransactionsStream({
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

  /// Obtiene transacciones por rango de fechas
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _repository.getTransactionsByDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Stream de transacciones con actualizaciones en tiempo real
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId) {
    return _repository.getTransactionsStream(accountId);
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ==========================================
  // GESTIÓN DE DESCRIPCIONES FIJAS
  // ==========================================

  /// Crea una nueva descripción fija para nombres de caja
  Future<void> createCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    if (description.trim().isEmpty) {
      throw Exception('La descripción no puede estar vacía');
    }

    await _repository.createCashRegisterFixedDescription(
        accountId, description.trim());
  }

  /// Obtiene las descripciones fijas disponibles
  Future<List<String>> getCashRegisterFixedDescriptions(
      String accountId) async {
    final descriptions =
        await _repository.getCashRegisterFixedDescriptions(accountId);
    return descriptions
        .map((desc) => desc['description'] as String? ?? '')
        .where((desc) => desc.isNotEmpty)
        .toList();
  }

  /// Elimina una descripción fija
  Future<void> deleteCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    await _repository.deleteCashRegisterFixedDescription(
        accountId, description);
  }
}
