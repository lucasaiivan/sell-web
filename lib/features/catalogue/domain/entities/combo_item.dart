/// Item que representa la referencia a un producto dentro de un combo
class ComboItem {
  /// ID del producto referenciado
  final String productId;
  
  /// Nombre del item (snapshot para mostrar sin fetch adicional)
  final String name;

  /// Cantidad de este producto incluida en el combo
  final double quantity;
  
  /// Precio original unitario al momento de armar el combo (referencia)
  final double originalSalePrice;
  
  /// Precio de coste/costo unitario del producto  
  final double purchasePrice;

  ComboItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.originalSalePrice = 0.0,
    this.purchasePrice = 0.0,
  });

  factory ComboItem.fromMap(Map<String, dynamic> map) {
    return ComboItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      originalSalePrice: (map['originalSalePrice'] ?? 0.0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'originalSalePrice': originalSalePrice,
      'purchasePrice': purchasePrice,
    };
  }
  
  Map<String, dynamic> toJson() => toMap();
}
