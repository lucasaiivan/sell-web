// EJEMPLO DE IMPLEMENTACIÓN CORRECTA
// Este archivo muestra cómo usar las nuevas abstracciones del core refactorizado
//
// ⚠️ NOTA: Este es un archivo de DOCUMENTACIÓN con ejemplos de código.
// No es compilable por sí solo (falta imports y clases mock).
// Usar como referencia para implementar features reales.

// ignore_for_file: unused_import, unused_local_variable, unused_element
// ignore_for_file: avoid_print, prefer_const_constructors, implementation_imports
// ignore_for_file: annotate_overrides, unrelated_type_equality_checks

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:provider/provider.dart';
import 'services/database/i_firestore_datasource.dart';
import 'package:sellweb/core/errors/errors.dart';
import 'package:sellweb/core/services/database/firestore_datasource.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';

// ==========================================
// EJEMPLO 1: REPOSITORY CON NUEVO SISTEMA
// ==========================================

/// Contrato del repositorio (domain layer)
abstract interface class IProductRepository {
  Future<Either<Failure, List<Product>>> getProducts(String accountId);
  Future<Either<Failure, Product>> getProductById(String accountId, String productId);
  Future<Either<Failure, void>> updateProduct(String accountId, Product product);
}

/// Implementación del repositorio (data layer)
/// 
/// **Patrón:** Clean Architecture con abstracción de Firebase
/// **Beneficios:**
/// - Testeable con mocks
/// - DI-friendly
/// - ErrorMapper automático
@LazySingleton(as: IProductRepository)
class ProductRepositoryImpl implements IProductRepository {
  final IFirestoreDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts(String accountId) async {
    try {
      // ✅ Usar FirestorePaths para type-safety
      final path = FirestorePaths.accountCatalogue(accountId);
      final collection = _dataSource.collection(path);
      
      // ✅ Usar DataSource inyectado
      final snapshot = await _dataSource.getDocuments(collection);
      
      // Mapear a entidades de dominio
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc).toEntity())
          .toList();
      
      return Right(products);
    } catch (e, stack) {
      // ✅ ErrorMapper traduce Firebase → Domain automáticamente
      return Left(ErrorMapper.handleException(e, stack));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(
    String accountId,
    String productId,
  ) async {
    try {
      // ✅ Path type-safe
      final path = FirestorePaths.accountProduct(accountId, productId);
      final docRef = _dataSource.document(path);
      
      final snapshot = await docRef.get();
      
      if (!snapshot.exists) {
        return const Left(NotFoundFailure('Producto no encontrado'));
      }
      
      final product = ProductModel.fromFirestore(snapshot).toEntity();
      return Right(product);
    } catch (e, stack) {
      return Left(ErrorMapper.handleException(e, stack));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(
    String accountId,
    Product product,
  ) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, product.id);
      final data = ProductModel.fromEntity(product).toFirestore();
      
      // ✅ Operación atómica
      await _dataSource.updateDocument(path, data);
      
      return const Right(null);
    } catch (e, stack) {
      return Left(ErrorMapper.handleException(e, stack));
    }
  }
}

// ==========================================
// EJEMPLO 2: MANEJO DE ERRORES EN UI
// ==========================================

class ProductsPage extends StatelessWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        // ✅ Pattern matching exhaustivo con sealed classes
        // En tu app real, usa el state pattern de tu provider
        return const CircularProgressIndicator(); // Placeholder
        
        /* Ejemplo conceptual:
        return provider.state.when(
          loading: () => const CircularProgressIndicator(),
          success: (products) => _ProductListView(products),
          failure: (failure) => _buildErrorWidget(failure),
        );
        */
      },
    );
  }

  Widget _buildErrorWidget(Failure failure) {
    // ✅ Switch exhaustivo garantizado por sealed class
    return switch (failure) {
      NetworkFailure() => _ErrorWidget(
          message: 'Sin conexión a internet',
          icon: Icons.wifi_off,
        ),
      AuthFailure() => _ErrorWidget(
          message: 'Sesión expirada',
          icon: Icons.login,
        ),
      FirestoreFailure(code: final code) => _ErrorWidget(
          message: 'Error de base de datos: $code',
          icon: Icons.error,
        ),
      PermissionFailure() => _ErrorWidget(
          message: 'No tienes permisos',
          icon: Icons.lock,
        ),
      ValidationFailure(fieldErrors: final errors) => _ValidationErrorWidget(
          errors: errors ?? {},
        ),
      NotFoundFailure() => _ErrorWidget(
          message: 'Producto no encontrado',
          icon: Icons.search_off,
        ),
      _ => _ErrorWidget(
          message: failure.message,
          icon: Icons.error_outline,
        ),
    };
  }
}

// Widgets de ejemplo
class _ErrorWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  
  const _ErrorWidget({required this.message, required this.icon});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class _ValidationErrorWidget extends StatelessWidget {
  final Map<String, String> errors;
  
  const _ValidationErrorWidget({required this.errors});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: errors.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
    );
  }
}

// ==========================================
// EJEMPLO 3: USE CASE CON NUEVO SISTEMA
// ==========================================

@lazySingleton
class GetProductsUseCase {
  final IProductRepository _repository;

  GetProductsUseCase(this._repository);

  /// Obtiene productos con validación de negocio
  Future<Either<Failure, List<Product>>> call(String accountId) async {
    // Validación de dominio
    if (accountId.isEmpty) {
      return const Left(ValidationFailure('ID de cuenta requerido'));
    }

    // Delegar al repositorio
    final result = await _repository.getProducts(accountId);

    // Lógica de negocio adicional
    return result.map((products) {
      // Filtrar productos activos
      return products.where((p) => p.isActive).toList();
    });
  }
}

// ==========================================
// EJEMPLO 4: PROVIDER MEMORY-SAFE
// ==========================================

@injectable
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;
  
  List<Product> _products = [];
  Failure? _failure;
  bool _isLoading = false;
  
  ProductProvider(this._getProductsUseCase);

  List<Product> get products => _products;
  Failure? get failure => _failure;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    // ✅ CRÍTICO: Remover listeners y cancelar streams
    // Ejemplo: _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadProducts(String accountId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    
    final result = await _getProductsUseCase(accountId);
    
    // ✅ Manejo exhaustivo con fold
    result.fold(
      (failure) => _handleFailure(failure),
      (products) => _handleSuccess(products),
    );
    
    _isLoading = false;
    notifyListeners();
  }

  void _handleFailure(Failure failure) {
    // Log con stack trace preservado
    if (failure.stackTrace != null) {
      debugPrint('Error: ${failure.message}\n${failure.stackTrace}');
    }
    
    _failure = failure;
    _products = [];
  }

  void _handleSuccess(List<Product> products) {
    _products = products;
    _failure = null;
  }
}

// ==========================================
// MODELOS DE EJEMPLO
// ==========================================

class Product {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
  });
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
  });

  factory ProductModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'isActive': isActive,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      price: price,
      isActive: isActive,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      isActive: product.isActive,
    );
  }
}

// ==========================================
// RESUMEN DE MEJORES PRÁCTICAS
// ==========================================

/*
✅ DOs (Hacer):

1. Usar FirestoreDataSource inyectado (no statics)
2. Usar FirestorePaths para rutas
3. Usar ErrorMapper.handleException() para mapear errores
4. Pattern matching con sealed classes
5. Dispose de listeners en Providers
6. Validación en UseCases (dominio)
7. Mapeo explícito Model → Entity

❌ DON'Ts (No hacer):

1. No usar DatabaseCloudService estático directamente
2. No exponer FirebaseException a UI
3. No olvidar dispose en Providers
4. No hardcodear rutas de Firestore
5. No mezclar lógica de Firebase en dominio
6. No ignorar stack traces de errores
7. No usar clases no-sealed para errores

📊 Complejidad:

- Mapeo de errores: O(1) - switch directo
- Paths: O(1) - string interpolation
- Pattern matching: O(1) - compile-time optimizado

🎯 Beneficios:

- Type-safety en compile-time
- Testeable al 100%
- Memory-safe
- Clean Architecture completa
- Mensajes user-friendly automáticos
*/
