import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';

///
/// Contiene los casos de uso relacionados con la venta.
///
class SellUseCases {
  /// - [addProduct]: Agrega un producto a la lista de productos seleccionados.
  List<ProductCatalogue> addProduct(
      List<ProductCatalogue> selectedProducts, ProductCatalogue product) {
    final index = selectedProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      selectedProducts[index].quantity +=
          (product.quantity > 0 ? product.quantity : 1);
    } else {
      final prod = product;
      if (prod.quantity == 0) prod.quantity = 1;
      selectedProducts.add(prod);
    }
    return List<ProductCatalogue>.from(selectedProducts);
  }

  /// - [removeProduct]: Elimina o disminuye la cantidad de un producto de la lista seleccionada.
  List<ProductCatalogue> removeProduct(
      List<ProductCatalogue> selectedProducts, ProductCatalogue product) {
    final index = selectedProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      if (selectedProducts[index].quantity > 1) {
        selectedProducts[index].quantity--;
      } else {
        selectedProducts.removeAt(index);
      }
    }
    return List<ProductCatalogue>.from(selectedProducts);
  }

  /// - [getTicket]: Genera un ticket a partir de la lista de productos seleccionados.
  TicketModel getTicket(List<ProductCatalogue> selectedProducts) {
    final ticket = TicketModel(
      listPoduct: [],
      creation: Timestamp.now(),
    );
    
    // Usar el setter para establecer los productos de manera encapsulada
    ticket.products = selectedProducts;
    
    return ticket;
  }
}
