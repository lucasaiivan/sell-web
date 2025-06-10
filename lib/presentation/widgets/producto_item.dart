import 'package:flutter/material.dart';
import 'package:sellweb/domain/entities/catalogue.dart'; 

class ProductoItem extends StatelessWidget {
  final ProductCatalogue producto;
  const ProductoItem({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(producto.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Precio: ${producto.salePrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        if (producto.quantity > 0)
          Positioned(
            right: 8,
            top: 8,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black87,
              child: Text(
                '${producto.quantity}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
