import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/storage/app_data_persistence_service.dart';
import '../../core/utils/helpers/uid_helper.dart';
import '../entities/cash_register_model.dart';
import '../entities/ticket_model.dart';
import '../entities/catalogue.dart';

/// Casos de uso para gestión temporal de tickets de venta
///
/// RESPONSABILIDAD: Lógica de negocio de tickets en memoria (temporal)
/// - Crear y modificar tickets
/// - Gestionar productos en tickets
/// - Configurar pagos y descuentos
/// - Preparar tickets para venta
/// - Persistencia local (SharedPreferences)
///
/// NO INCLUYE:
/// - Persistencia en Firebase → Ver CashRegisterUsecases
/// - Consultas de historial → Ver CashRegisterUsecases
/// - Anulaciones persistentes → Ver CashRegisterUsecases
class SellUsecases {
  final AppDataPersistenceService _persistenceService;

  SellUsecases({
    required AppDataPersistenceService persistenceService,
  }) : _persistenceService = persistenceService;

  // ==========================================
  // CREACIÓN Y ACTUALIZACIÓN DE TICKETS
  // ==========================================

  /// Crea un ticket vacío
  TicketModel createEmptyTicket() {
    return TicketModel(
      listPoduct: [],
      creation: Timestamp.now(),
    );
  }

  /// Actualiza campos de un ticket preservando productos
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
    if (discount != null && discount < 0) {
      throw Exception('El descuento no puede ser negativo');
    }

    if (valueReceived != null && valueReceived < 0) {
      throw Exception('El valor recibido no puede ser negativo');
    }

    if (priceTotal != null && priceTotal < 0) {
      throw Exception('El precio total no puede ser negativo');
    }

    final newTicket = TicketModel(
      id: id ?? currentTicket.id,
      annulled: annulled ?? currentTicket.annulled,
      listPoduct: currentTicket.internalProductList
          .map((p) => Map<String, dynamic>.from(p))
          .toList(),
      creation: creation ?? currentTicket.creation,
      payMode: payMode ?? currentTicket.payMode,
      valueReceived: valueReceived ?? currentTicket.valueReceived,
      cashRegisterName: cashRegisterName ?? currentTicket.cashRegisterName,
      cashRegisterId: cashRegisterId ?? currentTicket.cashRegisterId,
      sellerName: sellerName ?? currentTicket.sellerName,
      sellerId: sellerId ?? currentTicket.sellerId,
      priceTotal: priceTotal ?? currentTicket.priceTotal,
      discount: discount ?? currentTicket.discount,
      discountIsPercentage:
          discountIsPercentage ?? currentTicket.discountIsPercentage,
      transactionType: transactionType ?? currentTicket.transactionType,
      currencySymbol: currencySymbol ?? currentTicket.currencySymbol,
    );

    return newTicket;
  }

  // ==========================================
  // GESTIÓN DE PRODUCTOS
  // ==========================================

  /// Agrega un producto al ticket (incrementa cantidad si ya existe)
  TicketModel addProductToTicket(
    TicketModel currentTicket,
    ProductCatalogue product, {
    bool replaceQuantity = false,
  }) {
    if (product.id.isEmpty) {
      throw Exception('El producto debe tener un ID válido');
    }

    if (product.salePrice < 0) {
      throw Exception('El precio de venta no puede ser negativo');
    }

    bool productExists = false;
    final List<ProductCatalogue> updatedProducts =
        List.from(currentTicket.products);

    for (var i = 0; i < updatedProducts.length; i++) {
      if (updatedProducts[i].id == product.id) {
        productExists = true;

        if (replaceQuantity) {
          final quantityToUse = product.quantity > 0
              ? product.quantity
              : updatedProducts[i].quantity;
          updatedProducts[i] = product.copyWith(quantity: quantityToUse);
        } else {
          final newQuantity = updatedProducts[i].quantity +
              (product.quantity > 0 ? product.quantity : 1);
          updatedProducts[i] =
              updatedProducts[i].copyWith(quantity: newQuantity);
        }
        break;
      }
    }

    if (!productExists) {
      final quantityToAdd = product.quantity > 0 ? product.quantity : 1;
      updatedProducts.add(product.copyWith(quantity: quantityToAdd));
    }

    final newTicket = updateTicketFields(currentTicket);
    newTicket.products = updatedProducts;

    return newTicket;
  }

  /// Elimina un producto del ticket
  TicketModel removeProductFromTicket(
    TicketModel currentTicket,
    ProductCatalogue product,
  ) {
    if (product.id.isEmpty) {
      throw Exception('El producto debe tener un ID válido');
    }

    final updatedProducts =
        currentTicket.products.where((item) => item.id != product.id).toList();

    final newTicket = updateTicketFields(currentTicket);
    newTicket.products = updatedProducts;

    return newTicket;
  }

  /// Crea un producto rápido (sin código de barras)
  /// 
  /// RESPONSABILIDAD: Crear producto temporal para venta rápida
  /// - Generar ID único
  /// - Validar descripción y precio
  /// - Establecer valores por defecto
  ProductCatalogue createQuickProduct({
    required String description,
    required double salePrice,
  }) {
    if (description.trim().isEmpty) {
      throw Exception('La descripción no puede estar vacía');
    }

    if (salePrice < 0) {
      throw Exception('El precio de venta no puede ser negativo');
    }

    return ProductCatalogue(
      id: UidHelper.generateUid(),
      description: description,
      salePrice: salePrice,
      code: '', // Productos rápidos no tienen código
      quantity: 1,
    );
  }

  // ==========================================
  // CONFIGURACIÓN DE PAGO Y DESCUENTO
  // ==========================================

  /// Configura la forma de pago del ticket
  TicketModel setTicketPaymentMode(
    TicketModel currentTicket,
    String payMode,
  ) {
    final allowedPayModes = ['effective', 'card', 'mercadopago', ''];
    if (!allowedPayModes.contains(payMode)) {
      throw Exception('Forma de pago no válida: $payMode');
    }

    final valueReceived =
        payMode != 'effective' ? 0.0 : currentTicket.valueReceived;

    return updateTicketFields(
      currentTicket,
      payMode: payMode,
      valueReceived: valueReceived,
    );
  }

  /// Configura el descuento del ticket
  TicketModel setTicketDiscount(
    TicketModel currentTicket, {
    required double discount,
    bool isPercentage = false,
  }) {
    if (discount < 0) {
      throw Exception('El descuento no puede ser negativo');
    }

    return updateTicketFields(
      currentTicket,
      discount: discount,
      discountIsPercentage: isPercentage,
    );
  }

  /// Configura el valor recibido en efectivo
  TicketModel setTicketReceivedCash(
    TicketModel currentTicket,
    double value,
  ) {
    if (value < 0) {
      throw Exception('El valor recibido no puede ser negativo');
    }

    return updateTicketFields(
      currentTicket,
      valueReceived: value,
    );
  }

  // ==========================================
  // ASOCIACIONES (CAJA/VENDEDOR)
  // ==========================================

  /// Asocia un ticket con una caja registradora
  TicketModel associateTicketWithCashRegister(
    TicketModel currentTicket,
    CashRegister cashRegister,
  ) {
    if (cashRegister.id.isEmpty) {
      throw Exception('La caja registradora debe tener un ID válido');
    }

    if (cashRegister.description.trim().isEmpty) {
      throw Exception('La caja registradora debe tener una descripción');
    }

    return updateTicketFields(
      currentTicket,
      cashRegisterId: cashRegister.id,
      cashRegisterName: cashRegister.description,
    );
  }

  /// Asigna un vendedor al ticket
  TicketModel assignSellerToTicket(
    TicketModel currentTicket, {
    required String sellerId,
    required String sellerName,
  }) {
    if (sellerId.trim().isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    if (sellerName.trim().isEmpty) {
      throw Exception('El nombre del vendedor no puede estar vacío');
    }

    return updateTicketFields(
      currentTicket,
      sellerId: sellerId,
      sellerName: sellerName,
    );
  }

  // ==========================================
  // PREPARACIÓN PARA VENTA
  // ==========================================

  /// Prepara un ticket completo para venta
  TicketModel prepareSaleTicket(
    TicketModel currentTicket, {
    required String sellerId,
    required String sellerName,
    CashRegister? activeCashRegister,
  }) {
    var updatedTicket = assignSellerToTicket(
      currentTicket,
      sellerId: sellerId,
      sellerName: sellerName,
    );

    if (activeCashRegister != null) {
      updatedTicket = associateTicketWithCashRegister(
        updatedTicket,
        activeCashRegister,
      );
    }

    // ✅ FIX: Usar getTotalPrice que incluye el descuento aplicado
    // Esto garantiza que priceTotal refleje el monto real cobrado al cliente
    updatedTicket = updateTicketFields(
      updatedTicket,
      priceTotal: updatedTicket.getTotalPrice,
    );

    if (updatedTicket.id.isEmpty) {
      updatedTicket = updateTicketFields(
        updatedTicket,
        id: UidHelper.generateUid(),
      );
    }

    _validateSaleTicket(updatedTicket);

    return updatedTicket;
  }

  /// Prepara un ticket para ser guardado en el historial
  TicketModel prepareTicketForTransaction(TicketModel ticket) {
    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe contener al menos un producto');
    }

    final ticketId =
        ticket.id.trim().isEmpty ? UidHelper.generateUid() : ticket.id;

    // ✅ FIX: Usar getTotalPrice que incluye descuento (monto real cobrado)
    // Si priceTotal ya está establecido correctamente, usarlo; de lo contrario, calcularlo
    final priceTotal =
        ticket.priceTotal > 0 ? ticket.priceTotal : ticket.getTotalPrice;

    if (priceTotal <= 0) {
      throw Exception('El monto total de la venta debe ser mayor a cero');
    }

    final cashRegisterName = ticket.cashRegisterId.trim().isEmpty
        ? 'Sin caja asignada'
        : ticket.cashRegisterName;

    final cashRegisterId =
        ticket.cashRegisterId.trim().isEmpty ? '' : ticket.cashRegisterId;

    if (ticket.sellerId.trim().isEmpty) {
      throw Exception('El ID del vendedor no puede estar vacío');
    }

    return ticket.copyWith(
      id: ticketId,
      priceTotal: priceTotal,
      cashRegisterName: cashRegisterName,
      cashRegisterId: cashRegisterId,
    );
  }

  /// Valida que un ticket esté listo para venta
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
  }

  // ==========================================
  // PERSISTENCIA LOCAL (SharedPreferences)
  // ==========================================

  /// Guarda el último ticket vendido localmente
  Future<void> saveLastSoldTicket(TicketModel ticket) async {
    if (ticket.id.trim().isEmpty) {
      throw Exception('El ticket debe tener un ID para ser guardado');
    }

    if (ticket.products.isEmpty) {
      throw Exception('El ticket debe tener al menos un producto');
    }

    if (ticket.priceTotal <= 0) {
      throw Exception('El ticket debe tener un precio total válido');
    }

    try {
      final ticketJson = jsonEncode(ticket.toJson());
      await _persistenceService.saveLastSoldTicket(ticketJson);
    } catch (e) {
      throw Exception('Error al guardar último ticket: $e');
    }
  }

  /// Obtiene el último ticket vendido desde almacenamiento local
  Future<TicketModel?> getLastSoldTicket() async {
    try {
      final ticketJson = await _persistenceService.getLastSoldTicket();

      if (ticketJson == null || ticketJson.isEmpty) {
        return null;
      }

      try {
        final ticketMap = jsonDecode(ticketJson) as Map<String, dynamic>;
        return TicketModel.sahredPreferencefromMap(ticketMap);
      } catch (e) {
        await clearLastSoldTicket();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el último ticket vendido
  Future<void> updateLastSoldTicket(TicketModel ticket) async {
    await saveLastSoldTicket(ticket);
  }

  /// Elimina el último ticket vendido
  Future<void> clearLastSoldTicket() async {
    try {
      await _persistenceService.clearLastSoldTicket();
    } catch (e) {
      throw Exception('Error al limpiar último ticket: $e');
    }
  }

  /// Verifica si existe un último ticket guardado
  Future<bool> hasLastSoldTicket() async {
    try {
      final ticketJson = await _persistenceService.getLastSoldTicket();
      return ticketJson != null && ticketJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
