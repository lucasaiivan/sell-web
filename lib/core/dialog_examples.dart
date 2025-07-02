import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/catalogue.dart';
import '../core/dialog.dart';

/// Ejemplos de uso del diálogo mejorado para agregar productos
class DialogExamples {
  
  /// Ejemplo 1: Mostrar diálogo para producto encontrado en base pública
  static Future<void> showDialogForExistingProduct(BuildContext context) async {
    final existingProduct = ProductCatalogue(
      id: 'existing_123',
      code: '7791234567890',
      description: 'Producto encontrado en base pública',
      nameMark: 'Marca Conocida',
      image: 'https://example.com/product.jpg',
      creation: Timestamp.now(),
      upgrade: Timestamp.now(),
      // Otros campos con valores por defecto
      salePrice: 0.0,
      quantityStock: 0,
      stock: false,
    );

    await showDialogAgregarProductoPublico(
      context,
      product: existingProduct,
      isNew: false, // Producto existente
    );
  }

  /// Ejemplo 2: Mostrar diálogo para crear nuevo producto
  static Future<void> showDialogForNewProduct(BuildContext context, String scannedCode) async {
    final newProduct = ProductCatalogue(
      id: '', // Se generará automáticamente
      code: scannedCode,
      description: '', // El usuario lo completará
      nameMark: '',
      image: '',
      creation: Timestamp.now(),
      upgrade: Timestamp.now(),
      // Otros campos con valores por defecto
      salePrice: 0.0,
      quantityStock: 0,
      stock: false,
    );

    await showDialogAgregarProductoPublico(
      context,
      product: newProduct,
      isNew: true, // Producto nuevo
    );
  }

  /// Ejemplo 3: Flujo completo de escaneo de código
  static Future<void> handleScannedCode(BuildContext context, String code) async {
    try {
      // Simular búsqueda en base pública (esto debe reemplazarse con la lógica real)
      final foundProduct = await _searchProductInPublicDatabase(code);
      
      if (foundProduct != null) {
        // Producto encontrado: mostrar diálogo para agregarlo
        await showDialogAgregarProductoPublico(
          context,
          product: foundProduct,
          isNew: false,
        );
      } else {
        // Producto no encontrado: mostrar diálogo para crearlo
        await showDialogAgregarProductoPublico(
          context,
          product: ProductCatalogue(
            id: '',
            code: code,
            description: '',
            creation: Timestamp.now(),
            upgrade: Timestamp.now(),
            salePrice: 0.0,
            quantityStock: 0,
            stock: false,
          ),
          isNew: true,
        );
      }
    } catch (e) {
      // Mostrar diálogo con error
      await showDialogAgregarProductoPublico(
        context,
        product: ProductCatalogue(
          id: '',
          code: code,
          description: '',
          creation: Timestamp.now(),
          upgrade: Timestamp.now(),
          salePrice: 0.0,
          quantityStock: 0,
          stock: false,
        ),
        errorMessage: 'Error al buscar producto: ${e.toString()}',
        isNew: true,
      );
    }
  }

  /// Simula la búsqueda en la base de datos pública
  static Future<ProductCatalogue?> _searchProductInPublicDatabase(String code) async {
    // TODO: Implementar búsqueda real usando CatalogueProvider
    // Por ahora retorna null para simular que no se encontró
    return null;
  }

  /// Ejemplo 4: Diálogo con error personalizado
  static Future<void> showDialogWithError(BuildContext context) async {
    final product = ProductCatalogue(
      id: 'test_456',
      code: '1234567890123',
      description: 'Producto de prueba',
      creation: Timestamp.now(),
      upgrade: Timestamp.now(),
      salePrice: 0.0,
      quantityStock: 0,
      stock: false,
    );

    await showDialogAgregarProductoPublico(
      context,
      product: product,
      errorMessage: 'Error de ejemplo: No se pudo conectar con el servidor',
      isNew: false,
    );
  }
}
