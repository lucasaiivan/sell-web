import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/catalogue_usecases.dart';

class CatalogueProvider extends ChangeNotifier {
  final GetProductsStreamUseCase getProductsStreamUseCase;
  CatalogueProvider({required this.getProductsStreamUseCase});

  Stream<QuerySnapshot> get productsStream => getProductsStreamUseCase();
}
