import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart'; 
import 'package:sellweb/domain/entities/ticket_model.dart';
import 'package:sellweb/domain/usecases/sell_usecases.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellProvider extends ChangeNotifier {
  // lista de productos seleccionados por el usuario (carrito de compras)
  final List<ProductCatalogue> _selectedProducts = [];
  final SellUseCases _sellUseCases = SellUseCases();
  bool _ticketView = false; // si mostramos vista de ticket o no
  List<ProductCatalogue> get selectedProducts => _selectedProducts;
  bool get ticketView => _ticketView; 
  ProfileAccountModel selectedAccount = ProfileAccountModel();
  // keys para SharedPreferences
  static const String _selectedAccountKey = 'selected_account_id';
  static const String _selectedProductsKey = 'selected_products';

  SellProvider() {
    _loadSelectedAccount().whenComplete(() => _loadSelectedProducts()); 
  }

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
    _saveSelectedProducts();
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    _selectedProducts.removeWhere((p) => p.id == product.id);
    if (_selectedProducts.isEmpty) {
      _ticketView = false; // Cambia a vista de productos si no hay productos
    }
    _saveSelectedProducts();
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
    _saveSelectedProducts();
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

  // obtiene el ticket generado a partir de los productos seleccionados
  TicketModel get getTicket => _sellUseCases.getTicket(_selectedProducts);

  Future<void> _loadSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedAccountKey) ?? '';
    if (id.isNotEmpty) {
      selectedAccount.id = id;
      notifyListeners();
    }
  }

  Future<void> _saveSelectedAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAccountKey, id);
  }

  Future<void> _removeSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAccountKey);
  }

  Future<void> selectAccount({required ProfileAccountModel account, required BuildContext context}) async {
    selectedAccount = account.copyWith(); 
    _selectedProducts.clear(); // Limpiar productos seleccionados al seleccionar cuenta
    _ticketView = false; // Ocultar la vista de ticket

    // Accede al provider antes de cualquier await
    CatalogueProvider? catalogueProvider;
    try {
      catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
    } catch (e) {
      print('[SellProvider] Error al obtener el CatalogueProvider: $e');
    }

    await _saveSelectedAccount(account.id);
    await _saveSelectedProducts();

    // Inicializa el catálogo si se pudo obtener el provider
    if (catalogueProvider != null) {
      catalogueProvider.initCatalogue(account.id); 
    }

    notifyListeners();
  }

  /// Persiste la lista de productos seleccionados en SharedPreferences.
  Future<void> _saveSelectedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _selectedProducts.map((e) => e.toMap()).toList(); // Usa toMap() que serializa correctamente los Timestamps
    final json = jsonEncode(list); 
    await prefs.setString(_selectedProductsKey, json);
  }

  /// Carga la lista de productos seleccionados desde SharedPreferences.
  Future<void> _loadSelectedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_selectedProductsKey); 
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        _selectedProducts.clear();
        _selectedProducts.addAll(list.map((e) {
          try {
            return ProductCatalogue.fromMap(e as Map<String, dynamic>);
          } catch (err) {
            print('[SellProvider] Error al deserializar producto: $err, data: $e');
            return null;
          }
        }).whereType<ProductCatalogue>()); 
        notifyListeners();
      } catch (e) {
        print('[SellProvider] Error al decodificar productos: $e');
      }
    }  
  }

   /// Quita la cuenta seleccionada y notifica a los listeners.
  Future<void> removeSelectedAccount() async {
    selectedAccount = ProfileAccountModel();
    await _removeSelectedAccount();
    notifyListeners();
  }
}
