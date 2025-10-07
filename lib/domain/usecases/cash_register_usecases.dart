
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/storage/app_data_persistence_service.dart';
import '../../core/utils/helpers/uid_helper.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/entities/catalogue.dart';
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
class CashRegisterUsecases {
  final CashRegisterRepository _repository;
  final AppDataPersistenceService _persistenceService;

  CashRegisterUsecases(
    this._repository, {
    AppDataPersistenceService? persistenceService,
  }) : _persistenceService = persistenceService ?? AppDataPersistenceService.instance;

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

    // TRANSFORMACIÓN: Descripción por defecto si está vacía
    final finalDescription = description.trim().isEmpty
        ? 'Caja ${DateTime.now().day}/${DateTime.now().month}'
        : description.trim();

    return await _repository.openCashRegister(
      accountId: accountId,
      description: finalDescription,
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
  /// Actualiza los totales de ventas, facturación y descuentos
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
  // TRANSACCIONES HISTÓRICAS
  // ==========================================

  /// Guarda un ticket de venta en el historial de transacciones Y en persistencia local
  /// 
  /// RESPONSABILIDAD: Coordinar guardado en Firebase y SharedPreferences
  /// - Valida datos del ticket
  /// - Guarda en historial de transacciones (Firebase)
  /// - Actualiza último ticket vendido (SharedPreferences)
  /// 
  /// La transacción se registra SIEMPRE, independientemente de si existe una caja registradora
  Future<void> saveTicketToTransactionHistory({
    required String accountId,
    required TicketModel ticket,
    bool saveAsLastSold = true, // Por defecto, guarda también como último vendido
  }) async {
    // VALIDACIONES BÁSICAS
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío');
    }

    if (ticket.id.isEmpty) {
      throw Exception('El ID del ticket no puede estar vacío');
    }

    if (ticket.sellerId.isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    // Validar que el ticket tenga productos
    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe contener al menos un producto');
    }

    // Validar que el monto total sea positivo
    if (ticket.priceTotal <= 0) {
      throw Exception('El monto total de la venta debe ser mayor a cero');
    }

    // NOTA: No validamos cashRegisterId porque las transacciones deben registrarse
    // siempre, incluso sin caja registradora activa

    // Usar directamente el toMap() del ticket que ya incluye todos los campos necesarios
    // incluyendo transactionType y el timestamp de creación
    final transactionData = ticket.toMap();

    // 1. Guardar en Firestore (historial de transacciones)
    await _repository.saveTicketTransaction(
      accountId: accountId,
      ticketId: ticket.id,
      transactionData: transactionData,
    );

    // 2. Actualizar último ticket vendido en SharedPreferences (si se solicita)
    if (saveAsLastSold) {
      try {
        await saveLastSoldTicket(ticket);
      } catch (e) {
        // No fallar la operación si hay error en persistencia local
        // El ticket ya está guardado en Firebase
        if (kDebugMode) {
          print('⚠️ Ticket guardado en Firebase pero error en persistencia local: $e');
        }
      }
    }
  }
 

  /// Obtiene las transacciones de ventas de un periodo específico
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate, 
  }) async {
    if (startDate.isAfter(endDate)) {
      throw Exception('La fecha de inicio no puede ser posterior a la fecha de fin');
    }

    return await _repository.getTransactionsByDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate, 
    );
  }

  /// = Obtiene las transacciones del día actual =
  Future<List<Map<String, dynamic>>> getTodayTransactions({required String accountId,String cashRegisterId=''}) async { 
    // definir el rango de fechas para hoy
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)); 
  // obtener todas las transacciones de hoy
    final result = await getTransactionsByDateRange(
      accountId: accountId,
      startDate: startOfDay,
      endDate: endOfDay, 
    );

    // filtrar por cashRegisterId si se proporciona
    if (cashRegisterId.isNotEmpty) {
      return result.where((doc) => doc['cashRegisterId'] == cashRegisterId).toList();
    } 
    return result;
  }

  /// Stream de transacciones de ventas con actualizaciones en tiempo real
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId) {
    return _repository.getTransactionsStream(accountId);
  }

  /// Obtiene el detalle de una transacción específica
  Future<Map<String, dynamic>?> getTransactionDetail({
    required String accountId,
    required String transactionId,
  }) async {
    return await _repository.getTransactionDetail(
      accountId: accountId,
      transactionId: transactionId,
    );
  }

  /// Elimina una transacción del historial (solo para casos excepcionales)
  Future<void> deleteTransaction({
    required String accountId,
    required String transactionId,
  }) async {
    await _repository.deleteTransaction(
      accountId: accountId,
      transactionId: transactionId,
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

    await _repository.createCashRegisterFixedDescription(
        accountId, description.trim());
  }

  /// Obtiene las descripciones fijas disponibles para nombres de caja registradora
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
  Future<void> deleteCashRegisterFixedDescription({
    required String accountId,
    required String description,
  }) async {
    await _repository.deleteCashRegisterFixedDescription(
        accountId, description);
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

  // ==========================================
  // PREPARACIÓN Y VALIDACIÓN DE TICKETS
  // ==========================================

  /// Prepara un ticket para ser guardado en el historial de transacciones
  /// Aplica todas las transformaciones y validaciones necesarias
  TicketModel prepareTicketForTransaction(TicketModel ticket) {
    // VALIDACIÓN: El ticket debe tener productos
    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe contener al menos un producto');
    }

    // TRANSFORMACIÓN: Generar ID si no existe
    final ticketId = ticket.id.trim().isEmpty 
        ? UidHelper.generateUid() 
        : ticket.id;

    // TRANSFORMACIÓN: Calcular precio total si no está definido
    final priceTotal = ticket.priceTotal > 0 
        ? ticket.priceTotal 
        : ticket.calculatedTotal;

    // VALIDACIÓN: El precio total debe ser positivo
    if (priceTotal <= 0) {
      throw Exception('El monto total de la venta debe ser mayor a cero');
    }

    // TRANSFORMACIÓN: Valores por defecto para caja registradora
    final cashRegisterName = ticket.cashRegisterId.trim().isEmpty
        ? 'Sin caja asignada'
        : ticket.cashRegisterName;

    final cashRegisterId = ticket.cashRegisterId.trim().isEmpty
        ? ''
        : ticket.cashRegisterId;

    // VALIDACIÓN: Debe tener información del vendedor
    if (ticket.sellerId.trim().isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    // Retornar ticket preparado
    return ticket.copyWith(
      id: ticketId,
      priceTotal: priceTotal,
      cashRegisterName: cashRegisterName,
      cashRegisterId: cashRegisterId,
    );
  }

  /// Procesa la anulación de un ticket
  /// Valida y prepara el ticket anulado con todas las reglas de negocio
  Future<TicketModel> processTicketAnnullment({
    required String accountId,
    required TicketModel ticket,
    CashRegister? activeCashRegister,
  }) async {
    // VALIDACIÓN: El ticket no debe estar ya anulado
    if (ticket.annulled) {
      throw Exception('El ticket ya está anulado');
    }

    // VALIDACIÓN: El ticket debe tener un ID válido
    if (ticket.id.trim().isEmpty) {
      throw Exception('El ticket debe tener un ID válido');
    }

    // TRANSFORMACIÓN: Crear ticket anulado
    final annulledTicket = ticket.copyWith(annulled: true);

    // LÓGICA DE NEGOCIO: Actualizar el ticket en el historial
    await _repository.saveTicketTransaction(
      accountId: accountId,
      ticketId: ticket.id,
      transactionData: annulledTicket.toMap(),
    );

    // LÓGICA DE NEGOCIO: Si hay caja activa, restar de las ventas
    if (activeCashRegister != null && ticket.cashRegisterId == activeCashRegister.id) {
      // Decrementar billing y sales en la caja activa
      await _repository.updateSalesAndBilling(
        accountId: accountId,
        cashRegisterId: activeCashRegister.id,
        billingIncrement: -ticket.priceTotal,
        discountIncrement: -ticket.discount,
      );

      // Incrementar contador de tickets anulados
      // Nota: Esto requeriría un método específico en el repository
      // Por ahora, se maneja en la capa de datos
    }

    return annulledTicket;
  }

  /// Valida los datos de un movimiento de caja (ingreso o egreso)
  /// Retorna true si es válido, lanza excepción si no
  void validateCashMovement({
    required String description,
    required double amount,
  }) {
    // VALIDACIÓN: Descripción obligatoria
    if (description.trim().isEmpty) {
      throw Exception('La descripción del movimiento es obligatoria');
    }

    // VALIDACIÓN: Monto debe ser mayor a cero
    if (amount <= 0) {
      throw Exception('El monto debe ser mayor a cero');
    }
  }

  /// Valida los datos de apertura de caja antes de procesarlos
  /// Retorna un mapa con los datos validados y transformados
  Map<String, dynamic> validateAndPrepareOpeningData({
    required String description,
    required double initialCash,
    required String accountId,
    required String cashierId,
  }) {
    // VALIDACIONES
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

    // TRANSFORMACIONES
    final finalDescription = description.trim().isEmpty
        ? 'Caja ${DateTime.now().day}/${DateTime.now().month}'
        : description.trim();

    return {
      'description': finalDescription,
      'initialCash': initialCash,
      'accountId': accountId,
      'cashierId': cashierId,
      'isValid': true,
    };
  }

  /// Valida los datos de cierre de caja antes de procesarlos
  void validateClosingData({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  }) {
    // VALIDACIONES
    if (accountId.trim().isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío');
    }

    if (cashRegisterId.trim().isEmpty) {
      throw Exception('El ID de la caja registradora no puede estar vacío');
    }

    if (finalBalance < 0) {
      throw Exception('El balance final no puede ser negativo');
    }
  }

  // ==========================================
  // PERSISTENCIA LOCAL - ÚLTIMO TICKET VENDIDO
  // ==========================================

  /// Guarda el último ticket vendido en almacenamiento local (SharedPreferences)
  /// 
  /// RESPONSABILIDAD: Persistir el último ticket para recuperarlo después
  /// - Valida que el ticket tenga datos mínimos
  /// - Serializa el ticket a JSON
  /// - Guarda en SharedPreferences
  Future<void> saveLastSoldTicket(TicketModel ticket) async {
    // VALIDACIÓN: El ticket debe tener un ID
    if (ticket.id.trim().isEmpty) {
      throw Exception('El ticket debe tener un ID para ser guardado');
    }

    // VALIDACIÓN: El ticket debe tener productos
    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe tener al menos un producto');
    }

    // VALIDACIÓN: El ticket debe tener precio total
    if (ticket.priceTotal <= 0) {
      throw Exception('El ticket debe tener un precio total válido');
    }

    try {
      // TRANSFORMACIÓN: Serializar ticket a JSON
      final ticketJson = jsonEncode(ticket.toJson());
      
      // PERSISTENCIA: Guardar en SharedPreferences
      await _persistenceService.saveLastSoldTicket(ticketJson);
    } catch (e) {
      throw Exception('Error al guardar último ticket: $e');
    }
  }

  /// Obtiene el último ticket vendido desde almacenamiento local
  /// 
  /// RESPONSABILIDAD: Recuperar el último ticket guardado
  /// - Lee de SharedPreferences
  /// - Deserializa JSON a TicketModel
  /// - Maneja errores de formato
  Future<TicketModel?> getLastSoldTicket() async {
    try {
      // RECUPERACIÓN: Leer de SharedPreferences
      final ticketJson = await _persistenceService.getLastSoldTicket();
      
      if (ticketJson == null || ticketJson.isEmpty) {
        return null;
      }

      // TRANSFORMACIÓN: Deserializar JSON a TicketModel
      try {
        final ticketMap = jsonDecode(ticketJson) as Map<String, dynamic>;
        return TicketModel.sahredPreferencefromMap(ticketMap);
      } catch (e) {
        // Si hay error al deserializar, limpiar dato corrupto
        await clearLastSoldTicket();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el último ticket vendido (por ejemplo, para marcarlo como anulado)
  /// 
  /// RESPONSABILIDAD: Actualizar ticket existente en almacenamiento local
  /// - Valida que el ticket exista
  /// - Actualiza con el nuevo estado
  Future<void> updateLastSoldTicket(TicketModel ticket) async {
    // Reutilizar la lógica de guardado
    await saveLastSoldTicket(ticket);
  }

  /// Elimina el último ticket vendido del almacenamiento local
  /// 
  /// RESPONSABILIDAD: Limpiar dato cuando ya no es necesario
  Future<void> clearLastSoldTicket() async {
    try {
      await _persistenceService.clearLastSoldTicket();
    } catch (e) {
      throw Exception('Error al limpiar último ticket: $e');
    }
  }

  /// Verifica si existe un último ticket guardado
  /// 
  /// RESPONSABILIDAD: Validar existencia sin cargar datos
  Future<bool> hasLastSoldTicket() async {
    try {
      final ticketJson = await _persistenceService.getLastSoldTicket();
      return ticketJson != null && ticketJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Procesa la anulación de un ticket Y actualiza el último ticket vendido si corresponde
  /// 
  /// RESPONSABILIDAD: Coordinar anulación en historial y persistencia local
  /// - Anula el ticket en el historial (Firebase)
  /// - Si es el último ticket vendido, actualiza en local
  Future<TicketModel> processTicketAnnullmentWithLocalUpdate({
    required String accountId,
    required TicketModel ticket,
    CashRegister? activeCashRegister,
    bool updateLastSold = false,
  }) async {
    // Procesar anulación normal
    final annulledTicket = await processTicketAnnullment(
      accountId: accountId,
      ticket: ticket,
      activeCashRegister: activeCashRegister,
    );

    // Si se solicita, actualizar en persistencia local
    if (updateLastSold) {
      await updateLastSoldTicket(annulledTicket);
    }

    return annulledTicket;
  }

  // ==========================================
  // OPERACIONES DE CONSTRUCCIÓN DE TICKETS
  // ==========================================

  /// Crea un ticket vacío con valores predeterminados
  /// 
  /// RESPONSABILIDAD: Inicializar ticket con estado limpio
  /// - Timestamp actual
  /// - Lista de productos vacía
  /// - Valores predeterminados para campos opcionales
  TicketModel createEmptyTicket() {
    return TicketModel(
      listPoduct: [],
      creation: Timestamp.now(),
    );
  }

  /// Actualiza campos específicos de un ticket preservando el resto
  /// 
  /// RESPONSABILIDAD: Construcción inmutable de tickets
  /// - Preserva productos existentes
  /// - Actualiza solo campos especificados
  /// - Valida valores de entrada
  /// 
  /// Este método reemplaza _createTicketWithValues del Provider
  TicketModel updateTicketFields(
    TicketModel currentTicket, {
    String? id,
    Timestamp? creation,
    bool? annulled,
    String? payMode,
    double? valueReceived,
    String? cashRegisterName,
    String? cashRegisterId,
    String? sellerName,
    String? sellerId,
    double? priceTotal,
    double? discount,
    bool? discountIsPercentage,
    String? transactionType,
    String? currencySymbol,
  }) {
    // VALIDACIONES DE NEGOCIO
    if (discount != null && discount < 0) {
      throw Exception('El descuento no puede ser negativo');
    }

    if (valueReceived != null && valueReceived < 0) {
      throw Exception('El valor recibido no puede ser negativo');
    }

    if (priceTotal != null && priceTotal < 0) {
      throw Exception('El precio total no puede ser negativo');
    }

    // CONSTRUCCIÓN INMUTABLE: Crear nuevo ticket con campos actualizados
    final newTicket = TicketModel(
      id: id ?? currentTicket.id,
      annulled: annulled ?? currentTicket.annulled,
      listPoduct: currentTicket.internalProductList.map((p) => Map<String, dynamic>.from(p)).toList(), // Preservar productos
      creation: creation ?? currentTicket.creation,
      payMode: payMode ?? currentTicket.payMode,
      valueReceived: valueReceived ?? currentTicket.valueReceived,
      cashRegisterName: cashRegisterName ?? currentTicket.cashRegisterName,
      cashRegisterId: cashRegisterId ?? currentTicket.cashRegisterId,
      sellerName: sellerName ?? currentTicket.sellerName,
      sellerId: sellerId ?? currentTicket.sellerId,
      priceTotal: priceTotal ?? currentTicket.priceTotal,
      discount: discount ?? currentTicket.discount,
      discountIsPercentage: discountIsPercentage ?? currentTicket.discountIsPercentage,
      transactionType: transactionType ?? currentTicket.transactionType,
      currencySymbol: currencySymbol ?? currentTicket.currencySymbol,
    );

    return newTicket;
  }

  // ==========================================
  // OPERACIONES CON PRODUCTOS EN TICKETS
  // ==========================================

  /// Agrega un producto al ticket (incrementa cantidad si ya existe)
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para agregar productos
  /// - Buscar si el producto ya existe en el ticket
  /// - Si existe: incrementar cantidad o reemplazar según parámetro
  /// - Si no existe: agregar nuevo producto con cantidad inicial
  /// - Validar cantidad mínima
  TicketModel addProductToTicket(
    TicketModel currentTicket,
    ProductCatalogue product, {
    bool replaceQuantity = false,
  }) {
    // VALIDACIONES DE NEGOCIO
    if (product.id.isEmpty) {
      throw Exception('El producto debe tener un ID válido');
    }

    if (product.salePrice < 0) {
      throw Exception('El precio de venta no puede ser negativo');
    }

    // LÓGICA DE NEGOCIO: Buscar producto existente
    bool productExists = false;
    final List<ProductCatalogue> updatedProducts = List.from(currentTicket.products);

    for (var i = 0; i < updatedProducts.length; i++) {
      if (updatedProducts[i].id == product.id) {
        productExists = true;

        if (replaceQuantity) {
          // TRANSFORMACIÓN: Reemplazar producto preservando cantidad si es necesario
          final quantityToUse = product.quantity > 0
              ? product.quantity
              : updatedProducts[i].quantity;
          updatedProducts[i] = product.copyWith(quantity: quantityToUse);
        } else {
          // LÓGICA: Incrementar cantidad
          final newQuantity = updatedProducts[i].quantity + 
              (product.quantity > 0 ? product.quantity : 1);
          updatedProducts[i] = updatedProducts[i].copyWith(quantity: newQuantity);
        }
        break;
      }
    }

    // LÓGICA: Agregar producto nuevo si no existe
    if (!productExists) {
      final quantityToAdd = product.quantity > 0 ? product.quantity : 1;
      updatedProducts.add(product.copyWith(quantity: quantityToAdd));
    }

    // CONSTRUCCIÓN INMUTABLE: Crear nuevo ticket con productos actualizados
    final newTicket = updateTicketFields(currentTicket);
    newTicket.products = updatedProducts;

    return newTicket;
  }

  /// Elimina un producto del ticket
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para eliminar productos
  /// - Filtrar producto por ID
  /// - Preservar resto de productos
  /// - Retornar ticket actualizado
  TicketModel removeProductFromTicket(
    TicketModel currentTicket,
    ProductCatalogue product,
  ) {
    // VALIDACIONES DE NEGOCIO
    if (product.id.isEmpty) {
      throw Exception('El producto debe tener un ID válido');
    }

    // LÓGICA: Filtrar producto a eliminar
    final updatedProducts = currentTicket.products
        .where((item) => item.id != product.id)
        .toList();

    // CONSTRUCCIÓN INMUTABLE: Crear nuevo ticket con productos actualizados
    final newTicket = updateTicketFields(currentTicket);
    newTicket.products = updatedProducts;

    return newTicket;
  }

  // ==========================================
  // CONFIGURACIÓN DE FORMA DE PAGO Y VALORES
  // ==========================================

  /// Configura la forma de pago del ticket
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para método de pago
  /// - Validar forma de pago permitida
  /// - Si no es efectivo, resetear valor recibido a 0
  /// - Actualizar ticket inmutablemente
  TicketModel setTicketPaymentMode(
    TicketModel currentTicket,
    String payMode,
  ) {
    // VALIDACIONES DE NEGOCIO
    final allowedPayModes = ['effective', 'card', 'mercadopago', ''];
    if (!allowedPayModes.contains(payMode)) {
      throw Exception('Forma de pago no válida: $payMode');
    }

    // LÓGICA: Si no es efectivo, resetear valor recibido
    final valueReceived = payMode != 'effective' ? 0.0 : currentTicket.valueReceived;

    // ACTUALIZACIÓN INMUTABLE
    return updateTicketFields(
      currentTicket,
      payMode: payMode,
      valueReceived: valueReceived,
    );
  }

  /// Configura el descuento del ticket
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para descuentos
  /// - Validar descuento no negativo
  /// - Actualizar ticket inmutablemente
  TicketModel setTicketDiscount(
    TicketModel currentTicket, {
    required double discount,
    bool isPercentage = false,
  }) {
    // VALIDACIONES DE NEGOCIO
    if (discount < 0) {
      throw Exception('El descuento no puede ser negativo');
    }

    // ACTUALIZACIÓN INMUTABLE
    return updateTicketFields(
      currentTicket,
      discount: discount,
      discountIsPercentage: isPercentage,
    );
  }

  /// Configura el valor recibido en efectivo
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para valor recibido
  /// - Validar valor no negativo
  /// - Actualizar ticket inmutablemente
  TicketModel setTicketReceivedCash(
    TicketModel currentTicket,
    double value,
  ) {
    // VALIDACIONES DE NEGOCIO
    if (value < 0) {
      throw Exception('El valor recibido no puede ser negativo');
    }

    // ACTUALIZACIÓN INMUTABLE
    return updateTicketFields(
      currentTicket,
      valueReceived: value,
    );
  }

  // ==========================================
  // ASOCIACIONES DE NEGOCIO (CAJA/VENDEDOR)
  // ==========================================

  /// Asocia un ticket con una caja registradora
  /// 
  /// RESPONSABILIDAD: Vincular ticket con caja activa
  /// - Validar datos de caja
  /// - Actualizar campos de caja en ticket
  TicketModel associateTicketWithCashRegister(
    TicketModel currentTicket,
    CashRegister cashRegister,
  ) {
    // VALIDACIONES DE NEGOCIO
    if (cashRegister.id.isEmpty) {
      throw Exception('La caja registradora debe tener un ID válido');
    }

    if (cashRegister.description.trim().isEmpty) {
      throw Exception('La caja registradora debe tener una descripción');
    }

    // ACTUALIZACIÓN INMUTABLE
    return updateTicketFields(
      currentTicket,
      cashRegisterId: cashRegister.id,
      cashRegisterName: cashRegister.description,
    );
  }

  /// Asigna un vendedor al ticket
  /// 
  /// RESPONSABILIDAD: Vincular ticket con vendedor
  /// - Validar datos del vendedor
  /// - Actualizar campos de vendedor en ticket
  TicketModel assignSellerToTicket(
    TicketModel currentTicket, {
    required String sellerId,
    required String sellerName,
  }) {
    // VALIDACIONES DE NEGOCIO
    if (sellerId.trim().isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    if (sellerName.trim().isEmpty) {
      throw Exception('El nombre del vendedor no puede estar vacío');
    }

    // ACTUALIZACIÓN INMUTABLE
    return updateTicketFields(
      currentTicket,
      sellerId: sellerId,
      sellerName: sellerName,
    );
  }

  // ==========================================
  // PREPARACIÓN COMPLETA DE VENTA
  // ==========================================

  /// Prepara un ticket completo para venta
  /// 
  /// RESPONSABILIDAD: Validación y preparación final antes de guardar
  /// - Asignar vendedor
  /// - Calcular precio total
  /// - Validar ticket completo
  /// - Generar ID si no existe
  /// 
  /// Este método reemplaza _prepareTicketForSale del Provider
  TicketModel prepareSaleTicket(
    TicketModel currentTicket, {
    required String sellerId,
    required String sellerName,
    CashRegister? activeCashRegister,
  }) {
    // PASO 1: Asignar vendedor
    var updatedTicket = assignSellerToTicket(
      currentTicket,
      sellerId: sellerId,
      sellerName: sellerName,
    );

    // PASO 2: Asociar con caja registradora si está disponible
    if (activeCashRegister != null) {
      updatedTicket = associateTicketWithCashRegister(
        updatedTicket,
        activeCashRegister,
      );
    }

    // PASO 3: Calcular y asignar precio total
    updatedTicket = updateTicketFields(
      updatedTicket,
      priceTotal: updatedTicket.calculatedTotal,
    );

    // PASO 4: Generar ID si no existe
    if (updatedTicket.id.isEmpty) {
      updatedTicket = updateTicketFields(
        updatedTicket,
        id: UidHelper.generateUid(),
      );
    }

    // PASO 5: Validar ticket completo antes de retornar
    _validateSaleTicket(updatedTicket);

    return updatedTicket;
  }

  /// Valida que un ticket esté listo para venta
  /// 
  /// RESPONSABILIDAD: Validación de reglas de negocio
  /// - Ticket tiene productos
  /// - Precio total válido
  /// - Vendedor asignado
  void _validateSaleTicket(TicketModel ticket) {
    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe tener al menos un producto');
    }

    if (ticket.priceTotal <= 0) {
      throw Exception('El ticket debe tener un precio total válido');
    }

    if (ticket.sellerId.isEmpty) {
      throw Exception('El ticket debe tener un vendedor asignado');
    }

    if (ticket.sellerName.isEmpty) {
      throw Exception('El ticket debe tener el nombre del vendedor');
    }

    // VALIDACIÓN: Verificar consistencia de precio
    final calculatedTotal = ticket.calculatedTotal;
    if ((ticket.priceTotal - calculatedTotal).abs() > 0.01) {
      if (kDebugMode) {
        print('⚠️ Advertencia: Precio total (${ticket.priceTotal}) no coincide con calculado ($calculatedTotal)');
      }
    }
  }
}
