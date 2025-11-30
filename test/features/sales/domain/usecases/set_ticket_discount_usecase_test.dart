import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/features/sales/domain/usecases/set_ticket_discount_usecase.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../test_config.dart';

void main() {
  late SetTicketDiscountUseCase useCase;

  setUp(() {
    TestConfig.setUp();
    useCase = SetTicketDiscountUseCase();
  });

  tearDown(() {
    TestConfig.tearDown();
  });

  group('SetTicketDiscountUseCase', () {
    test('debe aplicar descuento fijo correctamente', () async {
      // Arrange
      final ticket = TestHelpers.ticketWithProducts;
      final params = SetTicketDiscountParams(
        currentTicket: ticket,
        discount: 10.0,
        isPercentage: false,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.discount, 10.0);
          expect(updatedTicket.discountIsPercentage, false);
        },
      );
    });

    test('debe aplicar descuento porcentual correctamente', () async {
      // Arrange
      final ticket = TestHelpers.ticketWithProducts;
      final params = SetTicketDiscountParams(
        currentTicket: ticket,
        discount: 15.0,
        isPercentage: true,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.discount, 15.0);
          expect(updatedTicket.discountIsPercentage, true);
        },
      );
    });

    test('debe permitir descuento de cero', () async {
      // Arrange
      final ticket = TestHelpers.ticketWithProducts;
      final params = SetTicketDiscountParams(
        currentTicket: ticket,
        discount: 0.0,
        isPercentage: false,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.discount, 0.0);
        },
      );
    });

    test('debe retornar ValidationFailure si el descuento es negativo',
        () async {
      // Arrange
      final ticket = TestHelpers.ticketWithProducts;
      final params = SetTicketDiscountParams(
        currentTicket: ticket,
        discount: -5.0,
        isPercentage: false,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('descuento no puede ser negativo'));
        },
        (ticket) => fail('Debería retornar un Failure'),
      );
    });

    test('debe mantener los productos del ticket al aplicar descuento',
        () async {
      // Arrange
      final ticket = TestHelpers.ticketWithProducts;
      final initialProductCount = ticket.products.length;
      final params = SetTicketDiscountParams(
        currentTicket: ticket,
        discount: 20.0,
        isPercentage: true,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.products.length, initialProductCount);
          expect(updatedTicket.discount, 20.0);
        },
      );
    });

    test('debe poder cambiar de descuento fijo a porcentual', () async {
      // Arrange
      final ticketWithFixedDiscount = TestHelpers.buildTicket(
        discount: 10.0,
        listPoduct: [TestHelpers.testProduct1.toMap()],
      );
      final params = SetTicketDiscountParams(
        currentTicket: ticketWithFixedDiscount,
        discount: 15.0,
        isPercentage: true,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.discount, 15.0);
          expect(updatedTicket.discountIsPercentage, true);
        },
      );
    });

    test('debe poder remover descuento estableciendo valor en cero', () async {
      // Arrange
      final ticketWithDiscount = TestHelpers.buildTicket(
        discount: 25.0,
        listPoduct: [TestHelpers.testProduct1.toMap()],
      );
      final params = SetTicketDiscountParams(
        currentTicket: ticketWithDiscount,
        discount: 0.0,
        isPercentage: false,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('No debería retornar un Failure'),
        (updatedTicket) {
          expect(updatedTicket.discount, 0.0);
        },
      );
    });
  });
}
