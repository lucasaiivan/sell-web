import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/services/demo_account/data/demo_config.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/core/services/demo_account/generators/catalogue_demo_generator.dart';
import 'package:sellweb/core/services/demo_account/generators/users_demo_generator.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';

/// Scope de tickets a generar
enum DemoTicketScope {
  /// Tickets del último mes (150 tickets, últimos 30 días)
  monthly,
  
  /// Tickets del último año (500 tickets, distribución concentrada en últimos 60 días)
  annual,
}

/// Generador de datos demo para ventas y transacciones
///
/// **Responsabilidad:**
/// - Generar tickets/transacciones históricas
/// - Soportar generación mensual (30 días) y anual (365 días)
/// - Distribución horaria realista (horas pico)
/// - Variedad de productos, cantidades y medios de pago
/// - Coherencia con productos y usuarios demo
class SalesDemoGenerator {
  SalesDemoGenerator._();

  // ==========================================
  // TICKETS/TRANSACCIONES
  // ==========================================

  /// Genera tickets/transacciones demo según el scope especificado
  ///
  /// **Parámetros:**
  /// - `scope`: [DemoTicketScope.monthly] para 150 tickets (30 días)
  ///            [DemoTicketScope.annual] para 500 tickets (365 días)
  ///
  /// **Retorna:** Lista de tickets generados
  static List<TicketModel> generateDemoTickets({
    DemoTicketScope scope = DemoTicketScope.monthly,
  }) {
    switch (scope) {
      case DemoTicketScope.monthly:
        return _generateMonthlyTickets();
      case DemoTicketScope.annual:
        return _generateAnnualTickets();
    }
  }

  // ==========================================
  // GENERACIÓN MENSUAL (30 días)
  // ==========================================

  /// Genera tickets para los últimos 30 días
  ///
  /// **Retorna:** ~150 tickets con:
  /// - Distribución realista: 3-8 tickets por día
  /// - Horarios comerciales: 8am - 10pm
  /// - Montos variados
  /// - Mix de productos por ticket: 1-10 items
  /// - Diferentes medios de pago
  static List<TicketModel> _generateMonthlyTickets() {
    final tickets = <TicketModel>[];
    final products = CatalogueDemoGenerator.generateDemoProducts();
    final users = UsersDemoGenerator.generateDemoAdminUsers();
    final random = Random(kDemoRandomSeed);
    
    final now = DateTime.now();
    int ticketId = 1;

    // Identificar productos de lenta rotación (15% del catálogo)
    final slowMovingCount = (products.length * kDemoSlowMovingProductsPercentage).ceil();
    final slowMovingProducts = products.sublist(0, slowMovingCount).map((p) => p.id).toSet();

    // Generar tickets para últimos 30 días
    for (int day = 30; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      
      // 3-8 tickets por día (más los fines de semana)
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final ticketsPerDay = isWeekend 
          ? kDemoMinTicketsPerWeekend + random.nextInt(kDemoMaxTicketsPerWeekend - kDemoMinTicketsPerWeekend)
          : kDemoMinTicketsPerWeekday + random.nextInt(kDemoMaxTicketsPerWeekday - kDemoMinTicketsPerWeekday);

      for (int i = 0; i < ticketsPerDay; i++) {
        final ticket = _createTicket(
          ticketId: ticketId,
          date: date,
          products: products,
          users: users,
          random: random,
          slowMovingProducts: slowMovingProducts,
        );
        
        tickets.add(ticket);
        ticketId++;
      }
    }

    // Asegurar que al menos algunos productos lentos tengan 1-2 ventas
    // para que aparezcan en la lista (ya que 0 ventas los hace invisibles)
    final slowProductsList = products.sublist(0, slowMovingCount);
    for (final slowProduct in slowProductsList) {
      // 30% de probabilidad de forzar una venta extra
      if (random.nextDouble() < 0.3) {
        final ticket = _createTicket(
          ticketId: ticketId,
          date: now.subtract(Duration(hours: random.nextInt(24 * 10))), // Últimos 10 días
          products: [slowProduct], // Solo este producto disponible para selección
          users: users,
          random: random,
          slowMovingProducts: null, // No restringir ya que forzamos este producto
        );
        tickets.add(ticket);
        ticketId++;
      }
    }

    return tickets;
  }

  // ==========================================
  // GENERACIÓN ANUAL (365 días)
  // ==========================================

  /// Genera tickets para el último año (para analytics)
  ///
  /// **Retorna:** ~500 tickets con:
  /// - Distribución temporal concentrada en últimos 60 días
  /// - Horas pico: 12:00-14:00 y 18:00-21:00 (60% de transacciones)
  /// - Productos de lenta rotación: 10-15%
  /// - Vendedores: 60% superusuario, 40% empleado
  static List<TicketModel> _generateAnnualTickets() {
    final tickets = <TicketModel>[];
    final products = CatalogueDemoGenerator.generateDemoProducts();
    final users = UsersDemoGenerator.generateDemoAdminUsers();
    final activeUsers = users.where((u) => !u.inactivate).toList();
    
    final random = Random(kDemoRandomSeed);
    final now = DateTime.now();
    int ticketId = 1;
    
    // Configuración de distribución temporal
    final distributionConfig = [
      // Últimos 2 días: 100 transacciones
      {'daysBack': 0, 'transactions': kDemoTicketsPerRecentDay},
      {'daysBack': 1, 'transactions': kDemoTicketsPerRecentDay},
      
      // Días 3-60: 250 transacciones (~4.3 por día)
      ...List.generate(kDemoMediumDensityDays, (i) => {
        'daysBack': i + 2,
        'transactions': i < 28 ? 5 : kDemoTicketsPerMediumDay,
      }),
      
      // Días 61-365: 150 transacciones (~0.5 por día)
      ...List.generate(kDemoLowDensityDays, (i) {
        final day = i + 60;
        // Distribuir algunos días con 1-2 transacciones, otros con 0
        final hasTransactions = (day % 2 == 0) || (day % 7 < 2);
        return {
          'daysBack': day,
          'transactions': hasTransactions ? (day % 5 == 0 ? 2 : 1) : 0,
        };
      }),
    ];
    
    // Tracking de productos de lenta rotación
    final slowMovingCount = (products.length * kDemoSlowMovingProductsPercentage).ceil();
    final slowMovingProducts = products.sublist(0, slowMovingCount).map((p) => p.id).toSet();
    
    // Generar transacciones según distribución
    for (final dayConfig in distributionConfig) {
      final daysBack = dayConfig['daysBack'] as int;
      final transactionsCount = dayConfig['transactions'] as int;
      
      if (transactionsCount == 0) continue;
      
      final date = now.subtract(Duration(days: daysBack));
      
      // Ajustar por fin de semana
      final isSaturday = date.weekday == DateTime.saturday;
      final isSunday = date.weekday == DateTime.sunday;
      
      int adjustedTransactions = transactionsCount;
      if (isSunday) {
        adjustedTransactions = (transactionsCount * 1.5).ceil();
      } else if (isSaturday) {
        adjustedTransactions = (transactionsCount * 1.3).ceil();
      }
      
      for (int i = 0; i < adjustedTransactions; i++) {
        final isPeakHour = random.nextDouble() < kDemoPeakHourProbability;
        
        final ticket = _createTicket(
          ticketId: ticketId,
          date: date,
          products: products,
          users: activeUsers,
          random: random,
          isPeakHour: isPeakHour,
          slowMovingProducts: slowMovingProducts,
          preferSuperAdmin: true,
        );
        
        tickets.add(ticket);
        ticketId++;
      }
    }
    
    return tickets;
  }

  // ==========================================
  // GENERACIÓN DE TICKET INDIVIDUAL
  // ==========================================

  /// Crea un ticket individual con todos sus detalles
  static TicketModel _createTicket({
    required int ticketId,
    required DateTime date,
    required List<ProductCatalogue> products,
    required List<AdminProfile> users,
    required Random random,
    bool isPeakHour = false,
    Set<String>? slowMovingProducts,
    bool preferSuperAdmin = false,
  }) {
    // Determinar hora
    int hour;
    if (isPeakHour) {
      // Horas pico: 12-14 (almuerzo) o 18-21 (tarde)
      if (random.nextDouble() < 0.5) {
        hour = kDemoLunchPeakStart + random.nextInt(kDemoLunchPeakEnd - kDemoLunchPeakStart);
      } else {
        hour = kDemoEveningPeakStart + random.nextInt(kDemoEveningPeakEnd - kDemoEveningPeakStart);
      }
    } else {
      hour = kDemoOpeningHour + random.nextInt(kDemoClosingHour - kDemoOpeningHour);
    }
    
    final minute = random.nextInt(60);
    final second = random.nextInt(60);
    final ticketTime = DateTime(date.year, date.month, date.day, hour, minute, second);
    
    // Seleccionar vendedor
    final seller = preferSuperAdmin && random.nextDouble() < kDemoSuperAdminSalesPercentage
        ? users.firstWhere((u) => u.superAdmin, orElse: () => users[0])
        : users[random.nextInt(users.length)];
    
    // Número de productos (más en hora pico)
    final numProducts = isPeakHour
        ? (3 + random.nextInt(10))
        : (kDemoMinProductsPerTicket + random.nextInt(kDemoMaxProductsPerTicket - kDemoMinProductsPerTicket));
    
    // Seleccionar productos
    final selectedProducts = <ProductCatalogue>[];
    final usedProductIds = <String>{};
    
    for (int j = 0; j < numProducts; j++) {
      ProductCatalogue product;
      int attempts = 0;
      
      do {
        // Evitar productos de lenta rotación en la mayoría de casos
        // Aumentado a 0.98 (2% chance) para asegurar que se vendan muy poco
        if (slowMovingProducts != null && random.nextDouble() < 0.98) {
          final availableProducts = products.where((p) => !slowMovingProducts.contains(p.id)).toList();
          product = availableProducts[random.nextInt(availableProducts.length)];
        } else {
          product = products[random.nextInt(products.length)];
        }
        attempts++;
      } while (usedProductIds.contains(product.id) && attempts < 20);
      
      if (!usedProductIds.contains(product.id)) {
        usedProductIds.add(product.id);
        
        final quantity = random.nextDouble() < 0.75
            ? (kDemoMinQuantityPerProduct + random.nextInt(3)).toDouble()
            : (3 + random.nextInt(kDemoMaxQuantityPerProduct - 2)).toDouble();
        
        selectedProducts.add(product.copyWith(quantity: quantity));
      }
    }
    
    // Calcular subtotal
    final subtotal = selectedProducts.fold<double>(
      0.0,
      (sum, p) => sum + (p.salePrice * p.quantity),
    );
    
    // Descuento ocasional
    final hasDiscount = random.nextDouble() < kDemoDiscountProbability;
    final discount = hasDiscount 
        ? (kDemoMinDiscount + random.nextDouble() * (kDemoMaxDiscount - kDemoMinDiscount))
        : 0.0;
    final total = subtotal - (subtotal * discount / 100);
    
    // Medio de pago
    final payModeRoll = random.nextDouble();
    String payMode;
    if (payModeRoll < kDemoPaymentMethodDistribution['cash']!) {
      payMode = PaymentMethod.cash.code;
    } else if (payModeRoll < (kDemoPaymentMethodDistribution['cash']! + kDemoPaymentMethodDistribution['transfer']!)) {
      payMode = PaymentMethod.transfer.code;
    } else if (payModeRoll < 0.90) {
      payMode = PaymentMethod.card.code;
    } else {
      payMode = PaymentMethod.qr.code;
    }
    
    return TicketModel(
      id: 'demo_ticket_${ticketId.toString().padLeft(6, '0')}',
      sellerName: seller.name,
      sellerId: seller.id,
      cashRegisterName: '1',
      cashRegisterId: 'demo_cash_register_1',
      payMode: payMode,
      priceTotal: total,
      valueReceived: payMode == PaymentMethod.cash.code 
          ? (total + (random.nextDouble() * 500))
          : total,
      discount: hasDiscount ? discount : 0.0,
      discountIsPercentage: hasDiscount,
      currencySymbol: kDemoCurrencySymbol,
      transactionType: 'sale',
      annulled: false,
      listPoduct: selectedProducts.map((p) => p.toMap()).toList(),
      creation: Timestamp.fromDate(ticketTime),
    );
  }
}
