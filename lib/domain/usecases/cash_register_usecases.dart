import '../../domain/entities/cash_register_model.dart';
import '../../domain/repositories/cash_register_repository.dart';

/// Casos de uso para el sistema de caja registradora
///
/// Implementa la lógica de negocio para:
/// - Apertura y cierre de caja
/// - Gestión de flujos de caja
/// - Consultas del historial
/// - Operaciones de arqueo
/// - Validaciones de negocio
/// - Transformaciones de datos
///
/// RESPONSABILIDAD ÚNICA: Solo operaciones de CAJA REGISTRADORA
/// Para operaciones con tickets, ver SellUsecases (lib/domain/usecases/sell_usecases.dart)
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
    required String cashierName,
  }) async {
    // VALIDACIONES DE NEGOCIO
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

    // TRANSFORMACIÓN: Descripción por defecto si está vacía
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

  /// Cierra una caja registradora específica
  ///
  /// Calcula automáticamente la diferencia y mueve la caja al historial
  /// Cierra una caja registradora existente
  ///
  /// RESPONSABILIDAD: Validar cierre y delegar a repositorio
  ///
  /// ⚠️ IMPORTANTE - LÓGICA DE CONTADORES:
  ///
  /// ## Contador `sales` (Ventas Efectivas) ✅
  /// - Se incrementa automáticamente (+1) en cada VENTA mediante `cashRegisterSale()`
  /// - Representa SOLO las ventas EFECTIVAS (NO incluye anulaciones)
  /// - **NO se modifica** al anular un ticket
  /// - **NO debe modificarse al cerrar caja** - ya está correcto
  ///
  /// ## Contador `annulledTickets` (Tickets Anulados)
  /// - Se incrementa (+1) cada vez que se anula un ticket
  /// - Se incrementa automáticamente en `updateBillingOnAnnullment()`
  /// - Puede requerir verificación al cerrar para corregir desincronizaciones
  ///
  /// ## Cálculo de Total de Transacciones
  /// ```dart
  /// totalTransacciones = sales + annulledTickets
  /// ventasEfectivas = sales // Directo, ya no requiere resta
  /// ```
  ///
  /// ## FLUJO AL CERRAR CAJA (ARQUEO):
  /// 1. Obtener transacciones reales de hoy:
  ///    ```dart
  ///    final todayTickets = await sellUsecases.getTodayTransactions(
  ///      accountId: accountId,
  ///      cashRegisterId: cashRegisterId
  ///    );
  ///    ```
  ///
  /// 2. Calcular contadores reales para VERIFICACIÓN:
  ///    ```dart
  ///    final realEffective = todayTickets.where((t) => t['annulled'] != true).length;
  ///    final realAnnulled = todayTickets.where((t) => t['annulled'] == true).length;
  ///    final realTotal = realEffective + realAnnulled;
  ///    ```
  ///
  /// 3. VALIDAR consistencia (NO sobrescribir):
  ///    ```dart
  ///    final currentSales = cashRegister.sales; // Ya correcto (solo ventas efectivas)
  ///    final currentAnnulled = cashRegister.annulledTickets;
  ///
  ///    // Verificar si requiere corrección
  ///    final needsUpdate = currentSales != realEffective || currentAnnulled != realAnnulled;
  ///
  ///    if (needsUpdate) {
  ///      await repository.setCashRegister(
  ///        accountId,
  ///        cashRegister.update(
  ///          sales: realEffective, // Corregir si hay desincronización
  ///          annulledTickets: realAnnulled, // Corregir si hay desincronización
  ///        ),
  ///      );
  ///    }
  ///    ```
  ///
  /// 4. Cerrar la caja con contadores validados
  ///
  /// ## ¿Por qué sales ahora es SOLO ventas efectivas?
  /// - **Claridad**: "ventas" no debería incluir anulaciones
  /// - **Simplicidad**: effectiveSales = sales (directo)
  /// - **Trazabilidad**: totalTransactions = sales + annulledTickets
  /// - **Consistencia**: Cada venta suma +1, cada anulación NO modifica sales
  ///
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `cashRegisterId`: ID de la caja a cerrar
  /// - `finalBalance`: Balance final declarado en el arqueo
  ///
  /// RETORNA: CashRegister cerrado
  ///
  /// LANZA: Exception si validaciones fallan
  Future<CashRegister> closeCashRegister({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  }) async {
    // VALIDACIONES DE NEGOCIO
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
  /// ⚠️ IMPORTANTE - ORDEN DE EJECUCIÓN:
  /// Este método DEBE llamarse DESPUÉS de guardar el ticket en Firebase.
  /// Garantiza consistencia: el contador 'sales' se incrementa SOLO si el ticket
  /// se guardó exitosamente en la base de datos.
  ///
  /// RESPONSABILIDAD:
  /// - Incrementar contador de ventas efectivas (+1)
  /// - Actualizar facturación total
  /// - Actualizar descuentos totales
  ///
  /// VALIDACIONES:
  /// - saleAmount >= 0
  /// - discountAmount >= 0
  ///
  /// USO CORRECTO:
  /// ```dart
  /// // 1. Guardar ticket en Firebase
  /// await saveTicketToTransactionHistory(ticket);
  ///
  /// // 2. SOLO si el guardado fue exitoso, incrementar contador
  /// await cashRegisterSale(
  ///   accountId: accountId,
  ///   cashRegisterId: cashRegisterId,
  ///   saleAmount: ticket.getTotalPrice,
  ///   discountAmount: ticket.discount,
  /// );
  /// ```
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
  // UTILIDADES PRIVADAS
  // ==========================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ==========================================
  // GESTIÓN DE DESCRIPCIONES FIJAS (NOMBRES DE CAJAS)
  // ==========================================

  /// Crea una nueva descripción fija para nombres de caja registradora
  ///
  /// RESPONSABILIDAD: Agregar opciones predefinidas para nombrar cajas
  ///
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `description`: Descripción/nombre a agregar
  ///
  /// LANZA: Exception si la descripción está vacía
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

  /// Obtiene las descripciones fijas disponibles para nombres de caja registradora
  ///
  /// RESPONSABILIDAD: Consultar opciones predefinidas para nombrar cajas
  ///
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  ///
  /// RETORNA: Lista de descripciones como Strings
  Future<List<String>> getCashRegisterFixedDescriptions(
      String accountId) async {
    final descriptions =
        await _repository.getCashRegisterFixedDescriptions(accountId);
    return descriptions
        .map((desc) => desc['description'] as String? ?? '')
        .where((desc) => desc.isNotEmpty)
        .toList();
  }

  /// Elimina una descripción fija para nombres de caja registradora
  ///
  /// RESPONSABILIDAD: Remover opciones predefinidas para nombrar cajas
  ///
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `description`: Descripción/nombre a eliminar
  Future<void> deleteCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    await _repository.deleteCashRegisterFixedDescription(
        accountId, description);
  }

  // ==========================================
  // NOTA: MÉTODOS DE TICKETS MOVIDOS A SellUsecases
  // ==========================================
  // Los siguientes 20 métodos fueron movidos a lib/domain/usecases/sell_usecases.dart
  // para cumplir con el Principio de Responsabilidad Única (SRP):
  //
  // - createEmptyTicket()
  // - updateTicketFields()
  // - prepareSaleTicket()
  // - prepareTicketForTransaction()
  // - _validateSaleTicket()
  // - addProductToTicket()
  // - removeProductFromTicket()
  // - setTicketPaymentMode()
  // - setTicketDiscount()
  // - setTicketReceivedCash()
  // - associateTicketWithCashRegister()
  // - assignSellerToTicket()
  // - saveTicketToTransactionHistory()
  // - processTicketAnnullment()
  // - processTicketAnnullmentWithLocalUpdate()
  // - saveLastSoldTicket()
  // - getLastSoldTicket()
  // - updateLastSoldTicket()
  // - clearLastSoldTicket()
  // - hasLastSoldTicket()
  //
  // Adicionalmente, los siguientes 3 métodos de consulta de transacciones fueron
  // movidos a SellUsecases:
  // - getTodayTransactions()
  // - getTransactionsByDateRange()
  // - getTransactionsStream()
  //
  // CashRegisterUsecases ahora se enfoca EXCLUSIVAMENTE en operaciones de caja registradora.
  // Para operaciones con tickets, usar SellUsecases.
}
