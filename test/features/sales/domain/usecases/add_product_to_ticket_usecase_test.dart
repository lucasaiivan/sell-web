import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/features/sales/domain/usecases/add_product_to_ticket_usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../test_config.dart';

void main() {
  late AddProductToTicketUseCase useCase;

  setUp(() {
    TestConfig.setUp();
    useCase = AddProductToTicketUseCase();
  });

  tearDown(() {
    TestConfig.tearDown();
  });

  group('AddProductToTicketUseCase', () {
    test('debe agregar un producto nuevo a un ticket vacío', () async {
      // Arrange
      final emptyTicket = TestHelpers.emptyTicket;
      final product = TestHelpers.testProduct1;
      final params = AddProductToTicketParams(
        currentTicket: emptyTicket,
        product: product,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          expect(ticket.products.length, 1);
          expect(ticket.products.first.id, product.id);
          expect(ticket.products.first.quantity, 1);
        },
      );
    });

    test('debe incrementar cantidad si el producto ya existe en el ticket',
        () async {
      // Arrange
      final ticketWithProduct = TestHelpers.ticketWithProducts;
      final existingProduct = TestHelpers.testProduct1;
      final params = AddProductToTicketParams(
        currentTicket: ticketWithProduct,
        product: existingProduct,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          final updatedProduct = ticket.products.firstWhere(
            (p) => p.id == existingProduct.id,
          );
          expect(updatedProduct.quantity, 2); // 1 original + 1 nuevo
        },
      );
    });

    test('debe agregar producto con cantidad específica', () async {
      // Arrange
      final emptyTicket = TestHelpers.emptyTicket;
      final product = TestHelpers.testProduct1.copyWith(quantity: 5);
      final params = AddProductToTicketParams(
        currentTicket: emptyTicket,
        product: product,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          expect(ticket.products.first.quantity, 5);
        },
      );
    });

    test('debe reemplazar cantidad cuando replaceQuantity es true', () async {
      // Arrange
      final ticketWithProduct = TestHelpers.ticketWithProducts;
      final existingProduct = TestHelpers.testProduct1.copyWith(quantity: 10);
      final params = AddProductToTicketParams(
        currentTicket: ticketWithProduct,
        product: existingProduct,
        replaceQuantity: true,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          final updatedProduct = ticket.products.firstWhere(
            (p) => p.id == existingProduct.id,
          );
          expect(updatedProduct.quantity, 10); // Reemplazado, no sumado
        },
      );
    });

    test('debe retornar ValidationFailure si el producto no tiene ID',
        () async {
      // Arrange
      final emptyTicket = TestHelpers.emptyTicket;
      final invalidProduct = TestHelpers.testProduct1.copyWith(id: '');
      final params = AddProductToTicketParams(
        currentTicket: emptyTicket,
        product: invalidProduct,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('ID válido'));
        },
        (ticket) => fail('Debería retornar un Failure'),
      );
    });

    test('debe retornar ValidationFailure si el precio es negativo', () async {
      // Arrange
      final emptyTicket = TestHelpers.emptyTicket;
      final invalidProduct =
          TestHelpers.testProduct1.copyWith(salePrice: -10.0);
      final params = AddProductToTicketParams(
        currentTicket: emptyTicket,
        product: invalidProduct,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message,
              contains('precio de venta no puede ser negativo'));
        },
        (ticket) => fail('Debería retornar un Failure'),
      );
    });

    test('debe agregar múltiples productos diferentes al ticket', () async {
      // Arrange
      final emptyTicket = TestHelpers.emptyTicket;
      final product1 = TestHelpers.testProduct1;
      final product2 = TestHelpers.testProduct2;

      // Act - Agregar primer producto
      final result1 = await useCase(AddProductToTicketParams(
        currentTicket: emptyTicket,
        product: product1,
      ));

      late TicketModel ticketWithOneProduct;
      result1.fold(
        (failure) => fail('No debería fallar al agregar el primer producto'),
        (ticket) => ticketWithOneProduct = ticket,
      );

      // Act - Agregar segundo producto
      final result2 = await useCase(AddProductToTicketParams(
        currentTicket: ticketWithOneProduct,
        product: product2,
      ));

      // Assert
      expect(result2.isRight(), true);
      result2.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          expect(ticket.products.length, 2);
          expect(ticket.products.any((p) => p.id == product1.id), true);
          expect(ticket.products.any((p) => p.id == product2.id), true);
        },
      );
    });

    test('debe mantener otros productos al agregar uno nuevo', () async {
      // Arrange
      final ticketWithProducts = TestHelpers.ticketWithProducts;
      final initialProductCount = ticketWithProducts.products.length;
      final newProduct = TestHelpers.buildProduct(
        id: 'new-product',
        code: 'NEW001',
        description: 'Nuevo Producto',
      );
      final params = AddProductToTicketParams(
        currentTicket: ticketWithProducts,
        product: newProduct,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (ticket) {
          expect(ticket.products.length, initialProductCount + 1);
          expect(ticket.products.any((p) => p.id == newProduct.id), true);
        },
      );
    });
  });
}
