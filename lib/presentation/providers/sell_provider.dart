import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart'; 
import 'package:sellweb/domain/usecases/sell_usecases.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';

class SellProvider extends ChangeNotifier {


  // lista de productos seleccionados por el usuario (carrito de compras)
  final List<ProductCatalogue> _selectedProducts = [];
  final SellUseCases _sellUseCases = SellUseCases();
  bool _ticketView = false; // si mostramos vista de ticket o no
  List<ProductCatalogue> get selectedProducts => _selectedProducts;
  bool get ticketView => _ticketView; 
  ProfileAccountModel selectedAccount = ProfileAccountModel();
  

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

  // void : descartar ticket, limpia la lista de productos y oculta la vista de ticket
  void discartTicket() {
    _selectedProducts.clear();
    _ticketView = false;
    notifyListeners();
  }

  // agregar un producto rapido sin registrar a la lista de productos deleccionados
  void addQuickProduct({required String description, required double salePrice}) {
    var id = Publications.generateUid();
    var product = ProductCatalogue(
      id: id,
      description: description,
      salePrice: salePrice, 
    );
    addProduct(product, replaceQuantity: true);
    notifyListeners();
  }

  // Simulación de ticket
  Ticket get getTicket => _sellUseCases.getTicket(_selectedProducts);

  Future<void> selectAccount({required ProfileAccountModel account,required BuildContext context}) async {
    selectedAccount = account.copyWith(); 
    _selectedProducts.clear(); // Limpiar productos seleccionados al seleccionar cuenta
    _ticketView = false; // Ocultar la vista de ticket
    // Limpiar y recargar catálogo si se provee el contexto
    try {
      final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
      catalogueProvider.initCatalogue(account.id);
      catalogueProvider.initCatalogue(account.id);
    } catch (e) {
      // Manejo de errores si no se puede acceder al CatalogueProvider
      print('Error al inicializar el catálogo: $e');
    } 
    notifyListeners();
  }

   /// Quita la cuenta seleccionada y notifica a los listeners.
  void removeSelectedAccount() {
    selectedAccount = ProfileAccountModel();
    notifyListeners();
  }
  
}

class Ticket {
  final List<ProductCatalogue> listProduct;
  Ticket({required this.listProduct});
  double get getTotalPrice => listProduct.fold(0, (sum, item) => sum + (item.salePrice * item.quantity));
}
