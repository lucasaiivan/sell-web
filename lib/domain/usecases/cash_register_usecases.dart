import '../../domain/entities/cash_register_model.dart';
import '../../domain/repositories/cash_register_repository.dart';

/// Casos de uso para el sistema de caja registradora
///
/// Implementa la lógica de negocio para:
/// - Apertura y cierre de caja
/// - Gestión de flujos de caja
/// - Consultas del historial
/// - Operaciones de arqueo
class CashRegisterUsecases {
  final CashRegisterRepository _repository;

  CashRegisterUsecases(this._repository);

  // ==========================================
  // GESTIÓN DE CAJAS ACTIVAS
  // ==========================================

  /// Abre una nueva caja registradora
  ///
  /// Valida que no exista otra caja abierta con el mismo cajero
  /// y crea una nueva caja con el monto inicial especificado
  Future<CashRegister> openCashRegister({
    required String accountId,
    required String description,
    required double initialCash,
    required String cashierId,
  }) async {
    // Validar que el monto inicial sea positivo
    if (initialCash < 0) {
      throw Exception('El monto inicial no puede ser negativo');
    }
 

    return await _repository.openCashRegister(
      accountId: accountId,
      description: description.isEmpty
          ? 'Caja ${DateTime.now().day}/${DateTime.now().month}'
          : description,
      initialCash: initialCash,
      cashierId: cashierId,
    );
  }

  /// Cierra una caja registradora específica
  ///
  /// Calcula automáticamente la diferencia y mueve la caja al historial
  Future<CashRegister> closeCashRegister({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  }) async {
    // Validar que el balance final sea un número válido
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
  ///
  /// Valida que el monto sea positivo y actualiza los totales
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
  ///
  /// Valida que el monto sea positivo y actualiza los totales
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
  /// Actualiza los totales de ventas, facturación y descuentos
  Future<void> registerSale({
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
  // DESCRIPCIONES FIJAS  PARA NOMBRES DE CAJA
  // ==========================================

  /// Crea una descripción fija para nombres frecuentes de caja registradora
  Future<void> createCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    if (description.trim().isEmpty) {
      throw Exception('La descripción no puede estar vacía');
    }

    await _repository.createCashRegisterFixedDescription(accountId, description.trim());
  }

  /// Obtiene las descripciones fijas disponibles para nombres de caja registradora
  Future<List<String>> getCashRegisterFixedDescriptions(String accountId) async {
    final descriptions = await _repository.getCashRegisterFixedDescriptions(accountId);
    return descriptions
        .map((desc) => desc['description'] as String? ?? '')
        .where((desc) => desc.isNotEmpty)
        .toList();
  }

  /// Elimina una descripción fija para nombres de caja registradora
  Future<void> deleteCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    await _repository.deleteCashRegisterFixedDescription(accountId, description);
  }

  // ==========================================
  // VALIDACIONES
  // ==========================================

  /// Verifica si hay cajas registradoras activas
  Future<bool> hasActiveCashRegister(String accountId) async {
    final activeCashRegisters = await getActiveCashRegisters(accountId);
    return activeCashRegisters.isNotEmpty;
  }

  /// Obtiene la caja registradora activa (si existe)
  Future<CashRegister?> getCurrentActiveCashRegister(String accountId) async {
    final activeCashRegisters = await getActiveCashRegisters(accountId);
    return activeCashRegisters.isNotEmpty ? activeCashRegisters.first : null;
  }

  // ==========================================
  // UTILIDADES PRIVADAS
  // ==========================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
