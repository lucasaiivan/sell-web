import '../../../core/constants/app_constants.dart';

/// Validadores específicos para reglas de negocio
class BusinessValidators {
  /// Valida si un precio es válido para el negocio
  static bool isValidPrice(double price) {
    return price >= AppConstants.minSaleAmount && 
           price <= AppConstants.maxProductPrice;
  }

  /// Valida si un stock es válido
  static bool isValidStock(int stock) {
    return stock >= 0 && stock <= AppConstants.maxProductStock;
  }

  /// Valida si un descuento es válido
  static bool isValidDiscount(double discount) {
    return discount >= 0 && discount <= AppConstants.maxDiscountPercentage;
  }

  /// Valida si la cantidad de items en un ticket es válida
  static bool isValidTicketItemCount(int itemCount) {
    return itemCount > 0 && itemCount <= AppConstants.maxItemsPerTicket;
  }

  /// Valida nombre de producto
  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre del producto es requerido';
    }

    if (name.length > AppConstants.maxProductNameLength) {
      return 'El nombre no puede exceder ${AppConstants.maxProductNameLength} caracteres';
    }

    // Verificar que no contenga solo números
    if (RegExp(r'^\d+$').hasMatch(name.trim())) {
      return 'El nombre no puede ser solo números';
    }

    // Verificar caracteres especiales excesivos
    if (RegExp(r'[<>"' + "']").hasMatch(name)) {
      return 'El nombre contiene caracteres no permitidos';
    }

    return null;
  }

  /// Valida descripción de producto
  static String? validateProductDescription(String? description) {
    if (description != null && description.length > AppConstants.maxProductDescriptionLength) {
      return 'La descripción no puede exceder ${AppConstants.maxProductDescriptionLength} caracteres';
    }
    return null;
  }

  /// Valida precio de producto
  static String? validateProductPrice(String? priceString) {
    if (priceString == null || priceString.isEmpty) {
      return 'El precio es requerido';
    }

    final price = double.tryParse(priceString);
    if (price == null) {
      return 'Precio inválido';
    }

    if (!isValidPrice(price)) {
      return 'Precio debe estar entre \$${AppConstants.minSaleAmount} y \$${AppConstants.maxProductPrice}';
    }

    return null;
  }

  /// Valida stock de producto
  static String? validateProductStock(String? stockString) {
    if (stockString == null || stockString.isEmpty) {
      return 'El stock es requerido';
    }

    final stock = int.tryParse(stockString);
    if (stock == null) {
      return 'Stock inválido';
    }

    if (!isValidStock(stock)) {
      return 'Stock debe estar entre 0 y ${AppConstants.maxProductStock}';
    }

    return null;
  }

  /// Valida código de barras
  static String? validateBarcode(String? barcode) {
    if (barcode == null || barcode.isEmpty) {
      return null; // El código de barras es opcional
    }

    // Verificar longitud (códigos comunes: EAN-8, EAN-13, UPC-A)
    if (barcode.length != 8 && 
        barcode.length != 12 && 
        barcode.length != 13) {
      return 'Código de barras debe tener 8, 12 o 13 dígitos';
    }

    // Verificar que solo contenga números
    if (!RegExp(r'^\d+$').hasMatch(barcode)) {
      return 'Código de barras solo puede contener números';
    }

    return null;
  }

  /// Valida categoría de producto
  static String? validateProductCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return 'La categoría es requerida';
    }

    if (category.length > 50) {
      return 'La categoría no puede exceder 50 caracteres';
    }

    return null;
  }

  /// Valida descuento aplicado a un producto o venta
  static String? validateDiscountPercentage(String? discountString) {
    if (discountString == null || discountString.isEmpty) {
      return null; // El descuento es opcional
    }

    final discount = double.tryParse(discountString);
    if (discount == null) {
      return 'Descuento inválido';
    }

    if (!isValidDiscount(discount)) {
      return 'Descuento debe estar entre 0% y ${(AppConstants.maxDiscountPercentage * 100).toInt()}%';
    }

    return null;
  }

  /// Valida cantidad de producto en carrito/ticket
  static String? validateQuantity(String? quantityString) {
    if (quantityString == null || quantityString.isEmpty) {
      return 'La cantidad es requerida';
    }

    final quantity = int.tryParse(quantityString);
    if (quantity == null) {
      return 'Cantidad inválida';
    }

    if (quantity <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }

    if (quantity > 999) { // Límite razonable por item
      return 'Cantidad máxima por producto: 999';
    }

    return null;
  }

  /// Valida método de pago
  static bool isValidPaymentMethod(String? paymentMethod) {
    const validMethods = ['efectivo', 'tarjeta', 'transferencia', 'credito'];
    return paymentMethod != null && validMethods.contains(paymentMethod.toLowerCase());
  }

  /// Valida nombre de caja registradora
  static String? validateCashRegisterName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre de la caja es requerido';
    }

    if (name.length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }

    // Verificar caracteres especiales que podrían causar problemas
    if (RegExp(r'[<>"/\\|?*]').hasMatch(name)) {
      return 'El nombre contiene caracteres no permitidos';
    }

    return null;
  }

  /// Valida si una venta puede procesarse
  static String? validateSaleProcessing({
    required List<dynamic> items,
    required String paymentMethod,
    String? cashRegisterId,
  }) {
    // Verificar que hay items
    if (items.isEmpty) {
      return 'No hay productos en el ticket';
    }

    // Verificar cantidad de items
    if (!isValidTicketItemCount(items.length)) {
      return 'Demasiados items en el ticket (máximo: ${AppConstants.maxItemsPerTicket})';
    }

    // Verificar método de pago
    if (!isValidPaymentMethod(paymentMethod)) {
      return 'Método de pago inválido';
    }

    // Verificar caja registradora (si es requerida)
    if (cashRegisterId == null || cashRegisterId.isEmpty) {
      return 'Debe seleccionar una caja registradora';
    }

    return null; // Todo válido
  }

  /// Valida configuración de impresora térmica
  static String? validatePrinterConfig({
    required String name,
    required String vendorId,
    required String productId,
  }) {
    if (name.trim().isEmpty) {
      return 'El nombre de la impresora es requerido';
    }

    if (vendorId.trim().isEmpty) {
      return 'El Vendor ID es requerido';
    }

    if (productId.trim().isEmpty) {
      return 'El Product ID es requerido';
    }

    // Verificar que los IDs sean numéricos (hexadecimales)
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(vendorId)) {
      return 'Vendor ID debe ser hexadecimal';
    }

    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(productId)) {
      return 'Product ID debe ser hexadecimal';
    }

    return null;
  }

  /// Valida si un usuario puede realizar una acción específica
  static bool canPerformAction({
    required String action,
    required Map<String, dynamic> userPermissions,
  }) {
    // Implementar lógica de permisos según el negocio
    switch (action) {
      case 'create_product':
      case 'edit_product':
      case 'delete_product':
        return userPermissions['manage_products'] == true;
        
      case 'process_sale':
        return userPermissions['process_sales'] == true;
        
      case 'manage_cash_register':
        return userPermissions['manage_cash_registers'] == true;
        
      case 'view_reports':
        return userPermissions['view_reports'] == true;
        
      default:
        return false;
    }
  }
}
