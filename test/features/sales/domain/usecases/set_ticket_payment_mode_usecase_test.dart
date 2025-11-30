import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/domain/usecases/set_ticket_payment_mode_usecase.dart';

void main() {
  late SetTicketPaymentModeUseCase useCase;
  late TicketModel testTicket;

  setUp(() {
    useCase = SetTicketPaymentModeUseCase();
    testTicket = TicketModel(
      id: 'test-ticket-1',
      sellerName: 'Test Seller',
      sellerId: 'seller-1',
      priceTotal: 1000.0,
      valueReceived: 1500.0,
      payMode: '',
      listPoduct: [],
      creation: Timestamp.now(),
    );
  });

  group('SetTicketPaymentModeUseCase', () {
    group('Validación de métodos de pago', () {
      test('debe aceptar método de pago "cash"', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.cash.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.cash.code);
            expect(ticket.valueReceived,
                1500.0); // Mantiene el valor para efectivo
          },
        );
      });

      test('debe aceptar método de pago "transfer"', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.transfer.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) => expect(ticket.payMode, PaymentMethod.transfer.code),
        );
      });

      test('debe aceptar método de pago "card"', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.card.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) => expect(ticket.payMode, PaymentMethod.card.code),
        );
      });

      test('debe aceptar método de pago "qr"', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.qr.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) => expect(ticket.payMode, PaymentMethod.qr.code),
        );
      });

      test('debe aceptar método de pago vacío (sin especificar)', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: '',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) => expect(ticket.payMode, ''),
        );
      });

      test('debe rechazar método de pago inválido', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: 'invalid_payment_method',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Forma de pago no válida'));
          },
          (ticket) => fail('Debería haber fallado'),
        );
      });

      test(
          'debe aceptar y normalizar método de pago legacy "effective" a "cash"',
          () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: 'effective', // Código antiguo
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar con código legacy'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.cash.code);
            expect(
                ticket.valueReceived, 1500.0); // Mantiene valor para efectivo
          },
        );
      });

      test(
          'debe aceptar y normalizar método de pago legacy "mercadopago" a "transfer"',
          () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket.copyWith(valueReceived: 2000.0),
          payMode: 'mercadopago', // Código antiguo
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('No debería fallar con código legacy'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.transfer.code);
            expect(
                ticket.valueReceived, 0.0); // Se resetea porque no es efectivo
          },
        );
      });
    });

    group('Lógica de valueReceived', () {
      test('debe mantener valueReceived cuando el método es "cash"', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket.copyWith(valueReceived: 2000.0),
          payMode: PaymentMethod.cash.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.cash.code);
            expect(ticket.valueReceived, 2000.0);
          },
        );
      });

      test('debe resetear valueReceived a 0.0 cuando el método es "transfer"',
          () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket.copyWith(valueReceived: 2000.0),
          payMode: PaymentMethod.transfer.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.transfer.code);
            expect(ticket.valueReceived, 0.0);
          },
        );
      });

      test('debe resetear valueReceived a 0.0 cuando el método es "card"',
          () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket.copyWith(valueReceived: 2000.0),
          payMode: PaymentMethod.card.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.card.code);
            expect(ticket.valueReceived, 0.0);
          },
        );
      });

      test('debe resetear valueReceived a 0.0 cuando el método es "qr"',
          () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket.copyWith(valueReceived: 2000.0),
          payMode: PaymentMethod.qr.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.qr.code);
            expect(ticket.valueReceived, 0.0);
          },
        );
      });

      test('debe resetear valueReceived cuando cambia de "cash" a otro método',
          () async {
        // Arrange - Primero establecer en cash
        final ticketWithCash = testTicket.copyWith(
          payMode: PaymentMethod.cash.code,
          valueReceived: 2000.0,
        );

        // Act - Cambiar a tarjeta
        final params = SetTicketPaymentModeParams(
          currentTicket: ticketWithCash,
          payMode: PaymentMethod.card.code,
        );
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(ticket.payMode, PaymentMethod.card.code);
            expect(ticket.valueReceived, 0.0);
          },
        );
      });
    });

    group('Inmutabilidad del ticket', () {
      test('no debe modificar el ticket original', () async {
        // Arrange
        final originalValueReceived = testTicket.valueReceived;
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.transfer.code,
        );

        // Act
        await useCase(params);

        // Assert
        expect(testTicket.valueReceived, originalValueReceived);
        expect(testTicket.payMode, '');
      });

      test('debe retornar una copia nueva del ticket', () async {
        // Arrange
        final params = SetTicketPaymentModeParams(
          currentTicket: testTicket,
          payMode: PaymentMethod.cash.code,
        );

        // Act
        final result = await useCase(params);

        // Assert
        result.fold(
          (failure) => fail('No debería fallar'),
          (ticket) {
            expect(identical(ticket, testTicket), false);
            expect(ticket.id, testTicket.id);
          },
        );
      });
    });

    group('Integración con PaymentMethod enum', () {
      test('debe usar códigos del enum PaymentMethod', () {
        // Assert
        expect(PaymentMethod.cash.code, 'cash');
        expect(PaymentMethod.transfer.code, 'transfer');
        expect(PaymentMethod.card.code, 'card');
        expect(PaymentMethod.qr.code, 'qr');
      });

      test(
          'PaymentMethod.getValidCodes() debe contener todos los métodos válidos',
          () {
        // Act
        final validCodes = PaymentMethod.getValidCodes();

        // Assert
        expect(validCodes, contains('cash'));
        expect(validCodes, contains('transfer'));
        expect(validCodes, contains('card'));
        expect(validCodes, contains('qr'));
        expect(validCodes, contains(''));
        expect(validCodes.length, 5);
      });

      test('todos los códigos válidos del enum deben ser aceptados', () async {
        // Arrange & Act & Assert
        for (final method in PaymentMethod.getValidMethods()) {
          final params = SetTicketPaymentModeParams(
            currentTicket: testTicket,
            payMode: method.code,
          );
          final result = await useCase(params);

          expect(
            result.isRight(),
            true,
            reason: 'El método ${method.code} debería ser válido',
          );
        }
      });
    });
  });
}
