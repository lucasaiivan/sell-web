import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Helpers reutilizables para todos los tests
/// 
/// Proporciona fixtures y builders para crear datos de prueba

class TestHelpers {
  // ==================== SALES FIXTURES ====================
  
  /// Ticket vacío para testing
  static TicketModel get emptyTicket => TicketModel(
        id: 'test-ticket-001',
        payMode: 'effective',
        sellerName: 'Test Seller',
        sellerId: 'seller-001',
        cashRegisterName: '1',
        cashRegisterId: 'register-001',
        priceTotal: 0.0,
        valueReceived: 0.0,
        discount: 0.0,
        discountIsPercentage: false,
        transactionType: 'sale',
        annulled: false,
        listPoduct: [],
        creation: Timestamp.now(),
      );

  /// Ticket con productos para testing
  static TicketModel get ticketWithProducts {
    final products = [
      testProduct1.toMap(),
      testProduct2.toMap(),
    ];
    
    return TicketModel(
      id: 'test-ticket-002',
      payMode: 'effective',
      sellerName: 'Test Seller',
      sellerId: 'seller-001',
      cashRegisterName: '1',
      cashRegisterId: 'register-001',
      priceTotal: 150.0,
      valueReceived: 200.0,
      discount: 0.0,
      discountIsPercentage: false,
      transactionType: 'sale',
      annulled: false,
      listPoduct: products,
      creation: Timestamp.now(),
    );
  }

  // ==================== CATALOGUE FIXTURES ====================
  
  /// Producto de prueba 1
  static ProductCatalogue get testProduct1 => ProductCatalogue(
        id: 'prod-001',
        code: 'TEST001',
        description: 'Producto Test 1',
        salePrice: 50.0,
        purchasePrice: 30.0,
        quantity: 1,
        stock: false,
        quantityStock: 100,
        category: 'Test Category',
        provider: 'Test Provider',
        favorite: false,
        sales: 0,
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
      );

  /// Producto de prueba 2
  static ProductCatalogue get testProduct2 => ProductCatalogue(
        id: 'prod-002',
        code: 'TEST002',
        description: 'Producto Test 2',
        salePrice: 100.0,
        purchasePrice: 60.0,
        quantity: 1,
        stock: true,
        quantityStock: 50,
        category: 'Test Category',
        provider: 'Test Provider',
        favorite: true,
        sales: 10,
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
      );

  /// Producto sin stock
  static ProductCatalogue get productOutOfStock => ProductCatalogue(
        id: 'prod-003',
        code: 'TEST003',
        description: 'Producto Sin Stock',
        salePrice: 75.0,
        purchasePrice: 45.0,
        quantity: 1,
        stock: false,
        quantityStock: 0,
        category: 'Test Category',
        provider: 'Test Provider',
        favorite: false,
        sales: 0,
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        documentCreation: DateTime.now(),
        documentUpgrade: DateTime.now(),
      );

  // ==================== BUILDERS ====================
  
  /// Builder para crear tickets personalizados
  static TicketModel buildTicket({
    String? id,
    String? payMode,
    List<Map<String, dynamic>>? listPoduct,
    double? priceTotal,
    double? discount,
    String? transactionType,
    bool? annulled,
  }) {
    return TicketModel(
      id: id ?? 'test-ticket-${DateTime.now().millisecondsSinceEpoch}',
      payMode: payMode ?? 'effective',
      sellerName: 'Test Seller',
      sellerId: 'seller-001',
      cashRegisterName: '1',
      cashRegisterId: 'register-001',
      priceTotal: priceTotal ?? 0.0,
      valueReceived: 0.0,
      discount: discount ?? 0.0,
      discountIsPercentage: false,
      transactionType: transactionType ?? 'sale',
      annulled: annulled ?? false,
      listPoduct: listPoduct ?? [],
      creation: Timestamp.now(),
    );
  }

  /// Builder para crear productos personalizados
  static ProductCatalogue buildProduct({
    String? id,
    String? code,
    String? description,
    double? salePrice,
    double? purchasePrice,
    int? quantity,
    bool? stock,
    int? quantityStock,
    bool? favorite,
    int? sales,
  }) {
    return ProductCatalogue(
      id: id ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
      code: code ?? 'TEST${DateTime.now().millisecondsSinceEpoch}',
      description: description ?? 'Test Product',
      salePrice: salePrice ?? 50.0,
      purchasePrice: purchasePrice ?? 30.0,
      quantity: quantity ?? 1,
      stock: stock ?? false,
      quantityStock: quantityStock ?? 100,
      category: 'Test Category',
      provider: 'Test Provider',
      favorite: favorite ?? false,
      sales: sales ?? 0,
      creation: DateTime.now(),
      upgrade: DateTime.now(),
      documentCreation: DateTime.now(),
      documentUpgrade: DateTime.now(),
    );
  }

  // ==================== UTILITIES ====================
  
  /// Convierte un producto a formato JSON para ticket
  static Map<String, dynamic> productToTicketJson(ProductCatalogue product, {int quantity = 1}) {
    final productMap = product.toMap();
    productMap['quantity'] = quantity;
    return productMap;
  }

  /// Calcula el total de un ticket basado en productos
  static double calculateTicketTotal(List<Map<String, dynamic>> products, {double discount = 0.0}) {
    final subtotal = products.fold<double>(
      0.0,
      (sum, product) {
        final price = (product['salePrice'] as num).toDouble();
        final qty = (product['quantity'] as num).toInt();
        return sum + (price * qty);
      },
    );
    return subtotal - discount;
  }
}
