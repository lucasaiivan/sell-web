import 'package:flutter/material.dart';
import 'package:sellweb/domain/entities/catalogue.dart'; 
import 'package:sellweb/domain/usecases/sell_usecases.dart';

class SellProvider extends ChangeNotifier {


  // lista de productos seleccionados por el usuario (carrito de compras)
  final List<ProductCatalogue> _selectedProducts = [];
  final SellUseCases _sellUseCases = SellUseCases();
  bool _ticketView = false; // si mostramos vista de ticket o no

  List<ProductCatalogue> get selectedProducts => _selectedProducts;
  bool get ticketView => _ticketView;

  /// Agrega un producto a la lista de productos.
  void addProduct(ProductCatalogue product, {bool replaceQuantity = false}) {
    final index = _selectedProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      if (replaceQuantity) {
        _selectedProducts[index].quantity = product.quantity;
      } else {
        _selectedProducts[index].quantity += (product.quantity > 0 ? product.quantity : 1);
      }
    } else {
      final prod = product;
      if (prod.quantity == 0) prod.quantity = 1;
      _selectedProducts.add(prod);
    }
    _ticketView = true; // Cambia a vista de ticket al agregar un producto
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    _selectedProducts.removeWhere((p) => p.id == product.id);
    if (_selectedProducts.isEmpty) {
      _ticketView = false; // Cambia a vista de productos si no hay productos
    }
    notifyListeners();
  }

  void setTicketView(bool value) {
    _ticketView = value;
    notifyListeners();
  }

  // Simulación de ticket
  Ticket get getTicket => _sellUseCases.getTicket(_selectedProducts);
}

class Ticket {
  final List<ProductCatalogue> listProduct;
  Ticket({required this.listProduct});
  double get getTotalPrice => listProduct.fold(0, (sum, item) => sum + (item.salePrice * item.quantity));
}
