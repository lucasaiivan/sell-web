import '../entities/cash_register_model.dart';

/// Repositorio abstracto para operaciones del sistema de caja registradora
///
/// Define los contratos para:
/// - Gestión de cajas registradoras activas
/// - Historial de arqueos de caja
/// - Descripciones fijas para movimientos
/// - Flujos de caja (ingresos y egresos)
abstract class CashRegisterRepository {
  // ==========================================
  // CAJAS REGISTRADORAS ACTIVAS
  // ==========================================

  /// Obtiene las cajas registradoras activas de una cuenta
  Future<List<CashRegister>> getActiveCashRegisters(String accountId);

  /// Stream de cajas registradoras activas
  Stream<List<CashRegister>> getActiveCashRegistersStream(String accountId);

  /// Crea o actualiza una caja registradora activa
  Future<void> setCashRegister(String accountId, CashRegister cashRegister);

  /// Elimina una caja registradora activa
  Future<void> deleteCashRegister(String accountId, String cashRegisterId);

  // ==========================================
  // HISTORIAL DE ARQUEOS
  // ==========================================

  /// Obtiene todo el historial de arqueos de caja de una cuenta
  Future<List<CashRegister>> getCashRegisterHistory(String accountId);

  /// Stream del historial de arqueos de caja
  Stream<List<CashRegister>> getCashRegisterHistoryStream(String accountId);

  /// Obtiene los arqueos de caja de los últimos N días
  Future<List<CashRegister>> getCashRegisterByDays(String accountId, int days);

  /// Obtiene los arqueos de caja entre dos fechas específicas
  Future<List<CashRegister>> getCashRegisterByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtiene los arqueos de caja del día actual
  Future<List<CashRegister>> getTodayCashRegisters(String accountId);

  /// Agrega un registro de arqueo al historial (cuando se cierra una caja)
  Future<void> addCashRegisterToHistory(
      String accountId, CashRegister cashRegister);

  /// Elimina un registro del historial de arqueos
  Future<void> deleteCashRegisterFromHistory(
      String accountId, CashRegister cashRegister);

  // ==========================================
  // DESCRIPCIONES FIJAS PARA NOMBRES DE CAJA
  // ==========================================

  /// Crea una descripción fija para nombres de caja registradora
  Future<void> createCashRegisterFixedDescription(String accountId, String description);

  /// Obtiene las descripciones fijas para nombres de caja registradora de una cuenta
  Future<List<Map<String, dynamic>>> getCashRegisterFixedDescriptions(String accountId);

  /// Elimina una descripción fija para nombres de caja registradora
  Future<void> deleteCashRegisterFixedDescription(String accountId, String descriptionId);

  // ==========================================
  // OPERACIONES DE CAJA
  // ==========================================

  /// Abre una nueva caja registradora
  Future<CashRegister> openCashRegister({
    required String accountId,
    required String description,
    required double initialCash,
    required String cashierId,
  });

  /// Cierra una caja registradora y la mueve al historial
  Future<CashRegister> closeCashRegister({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  });

  /// Registra un ingreso de caja
  Future<void> addCashInflow({
    required String accountId,
    required String cashRegisterId,
    required CashFlow cashFlow,
  });

  /// Registra un egreso de caja
  Future<void> addCashOutflow({
    required String accountId,
    required String cashRegisterId,
    required CashFlow cashFlow,
  });

  /// Actualiza los totales de ventas y facturación
  Future<void> updateSalesAndBilling({
    required String accountId,
    required String cashRegisterId, 
    required double billingIncrement,
    required double discountIncrement,
  });

  // ==========================================
  // TRANSACCIONES HISTÓRICAS
  // ==========================================

  /// Guarda un ticket de venta en el historial de transacciones
  Future<void> saveTicketTransaction({
    required String accountId,
    required String ticketId,
    required Map<String, dynamic> transactionData,
  });

  /// Obtiene las transacciones de ventas filtradas por rango de fechas
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Stream de transacciones de ventas con actualizaciones en tiempo real
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId);

  /// Obtiene el detalle de una transacción específica
  Future<Map<String, dynamic>?> getTransactionDetail({
    required String accountId,
    required String transactionId,
  });

  /// Elimina una transacción del historial
  Future<void> deleteTransaction({
    required String accountId,
    required String transactionId,
  });
}
