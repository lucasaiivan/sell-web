import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/storage/app_data_persistence_service.dart';
import '../../core/utils/helpers/uid_helper.dart';
import '../entities/cash_register_model.dart';
import '../entities/ticket_model.dart';
import '../entities/catalogue.dart';
import '../repositories/cash_register_repository.dart';

/// # SellUsecases - Casos de Uso de Ventas y Tickets
///
/// ## RESPONSABILIDAD ÚNICA
/// Esta clase contiene TODA la lógica de negocio relacionada con **TICKETS**.
/// Separada de CashRegisterUsecases para cumplir con el Principio de Responsabilidad Única (SRP).
///
/// ## ALCANCE
/// - Construcción y preparación de tickets
/// - Gestión de productos en tickets
/// - Configuración de pagos y descuentos
/// - Asociaciones con vendedores y cajas
/// - Persistencia en Firebase (historial de transacciones)
/// - Persistencia local (último ticket vendido)
/// - Anulación de tickets
///
/// ## DEPENDENCIAS
/// - `CashRegisterRepository`: Para persistir tickets en Firebase Firestore
/// - `AppDataPersistenceService`: Para persistir último ticket en SharedPreferences
///
/// ## PATRÓN CLEAN ARCHITECTURE
/// ```
/// Presentation Layer (SellProvider/CashRegisterProvider)
///         ↓
/// Domain Layer (SellUsecases) ← ESTAMOS AQUÍ
///         ↓
/// Data Layer (CashRegisterRepository/Firebase)
/// ```
///
/// ## USO
/// ```dart
/// final sellUsecases = SellUsecases(
///   repository: cashRegisterRepository,
///   persistenceService: appDataPersistenceService,
/// );
///
/// // Crear ticket vacío
/// final ticket = sellUsecases.createEmptyTicket();
///
/// // Agregar productos
/// ticket = sellUsecases.addProductToTicket(ticket, product);
///
/// // Preparar para venta
/// ticket = sellUsecases.prepareSaleTicket(
///   ticket,
///   sellerId: userId,
///   sellerName: userName,
///   activeCashRegister: cashRegister,
/// );
///
/// // Guardar en Firebase y local
/// await sellUsecases.saveTicketToTransactionHistory(
///   accountId: accountId,
///   ticket: ticket,
/// );
/// ```
///
/// ## SEPARACIÓN DE RESPONSABILIDADES
/// - **CashRegisterUsecases**: Operaciones de CAJA REGISTRADORA (abrir, cerrar, movimientos)
/// - **SellUsecases**: Operaciones de TICKETS (crear, modificar, guardar, anular) ← ESTE ARCHIVO
/// - **CatalogueUsecases**: Operaciones de CATÁLOGO (buscar productos, categorías)
///
/// @author Flutter Team
/// @since 2024
class SellUsecases {
  final CashRegisterRepository _repository;
  final AppDataPersistenceService _persistenceService;

  /// Constructor con inyección de dependencias
  SellUsecases({
    required CashRegisterRepository repository,
    required AppDataPersistenceService persistenceService,
  })  : _repository = repository,
        _persistenceService = persistenceService;

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

  /// Prepara un ticket para ser guardado en el historial de transacciones
  /// 
  /// RESPONSABILIDAD: Validación y transformación antes de persistir
  /// - Generar ID si no existe
  /// - Calcular precio total
  /// - Valores por defecto para caja
  /// - Validar datos mínimos
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

  // ==========================================
  // PERSISTENCIA EN FIREBASE (HISTORIAL)
  // ==========================================

  /// Guarda un ticket en el historial de transacciones de Firebase
  /// 
  /// RESPONSABILIDAD: Persistir ticket en Firestore
  /// - Validar datos mínimos
  /// - Guardar en historial (Firebase)
  /// - Opcionalmente guardar como último vendido (local)
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

  // ==========================================
  // ANULACIÓN DE TICKETS
  // ==========================================

  /// Procesa la anulación de un ticket
  /// 
  /// RESPONSABILIDAD: Lógica de negocio para anular tickets
  /// - Validar ticket no anulado previamente
  /// - Marcar como anulado
  /// - Actualizar en Firebase
  /// - Si hay caja activa, restar de ventas
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

    // LÓGICA DE NEGOCIO: Si hay caja activa, actualizar billing sin modificar sales
    if (activeCashRegister != null && ticket.cashRegisterId == activeCashRegister.id) {
      // ✅ Usar método específico para anulaciones que NO incrementa sales
      // - Decrementa billing (restar precio del ticket)
      // - Decrementa discount (restar descuento del ticket)  
      // - Incrementa annulledTickets (+1)
      // - NO modifica sales (ventas efectivas no incluyen anulaciones)
      await _repository.updateBillingOnAnnullment(
        accountId: accountId,
        cashRegisterId: activeCashRegister.id,
        billingDecrement: ticket.priceTotal, // Pasar valor positivo
        discountDecrement: ticket.getDiscountAmount, // Usar el monto calculado del descuento
      );
    }

    return annulledTicket;
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

  // ==========================================
  // CONSULTA DE TRANSACCIONES (TICKETS HISTÓRICOS)
  // ==========================================

  /// Obtiene las transacciones del día actual
  /// 
  /// RESPONSABILIDAD: Consultar tickets vendidos hoy, con filtro opcional por caja
  /// 
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `cashRegisterId`: (Opcional) ID de caja para filtrar
  /// 
  /// RETORNA: Lista de tickets como Map (para flexibilidad en consultas)
  Future<List<Map<String, dynamic>>> getTodayTransactions({
    required String accountId,
    String cashRegisterId = '',
  }) async { 
    // Definir el rango de fechas para hoy
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)); 
    
    // Obtener todas las transacciones de hoy
    final result = await getTransactionsByDateRange(
      accountId: accountId,
      startDate: startOfDay,
      endDate: endOfDay, 
    );

    // Filtrar por cashRegisterId si se proporciona
    if (cashRegisterId.isNotEmpty) {
      return result.where((doc) => doc['cashRegisterId'] == cashRegisterId).toList();
    } 
    return result;
  }

  /// Obtiene transacciones por rango de fechas
  /// 
  /// RESPONSABILIDAD: Consultar tickets vendidos en un período específico
  /// 
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `startDate`: Fecha de inicio del rango
  /// - `endDate`: Fecha de fin del rango
  /// 
  /// RETORNA: Lista de tickets como Map
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
  /// 
  /// RESPONSABILIDAD: Escuchar cambios en tickets en tiempo real
  /// 
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// 
  /// RETORNA: Stream con lista de tickets actualizados
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId) {
    return _repository.getTransactionsStream(accountId);
  }
}
