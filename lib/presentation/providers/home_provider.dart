import 'package:flutter/material.dart';
import 'package:sellweb/domain/entities/catalogue.dart'; 

class HomeProvider extends ChangeNotifier {
  // Simulación de ticket y productos seleccionados
  final List<ProductCatalogue> _selectedProducts = [];
  bool _ticketView = false;

  List<ProductCatalogue> get selectedProducts => _selectedProducts;
  bool get ticketView => _ticketView;

  void addProduct(ProductCatalogue product) {
    final index = _selectedProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      // Si ya existe, aumentar quantity
      _selectedProducts[index].quantity += (product.quantity > 0 ? product.quantity : 1);
    } else {
      // Si no existe, agregar con quantity mínimo 1
      final prod = product;
      if (prod.quantity == 0) prod.quantity = 1;
      _selectedProducts.add(prod);
    }
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    final index = _selectedProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      if (_selectedProducts[index].quantity > 1) {
        _selectedProducts[index].quantity--;
      } else {
        _selectedProducts.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setTicketView(bool value) {
    _ticketView = value;
    notifyListeners();
  }

  // Simulación de ticket
  Ticket get getTicket => Ticket(listProduct: _selectedProducts);
}

class Ticket {
  final List<ProductCatalogue> listProduct;
  Ticket({required this.listProduct});
  double get getTotalPrice => listProduct.fold(0, (sum, item) => sum + (item.salePrice ));
}
