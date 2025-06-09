import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/catalogue_provider.dart';
import '../../domain/entities/catalogue.dart';

class HomePage extends StatelessWidget {
  final AuthProvider authProvider;
  const HomePage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
          stream: catalogueProvider.productsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return const Text('Error al cargar productos');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No hay productos');
            }
            final products = docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  //leading: product.image.isNotEmpty ? Image.network(product.image, width: 40, height: 40, fit: BoxFit.cover) : null,
                  title: Text(product.description.isNotEmpty ? product.description : 'Sin descripción'),
                  subtitle: Text(product.nameMark.isNotEmpty ? product.nameMark : ''),
                  trailing: Text(product.code),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
