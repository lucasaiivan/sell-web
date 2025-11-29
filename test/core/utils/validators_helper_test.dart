import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/core/utils/helpers/validators_helper.dart';

void main() {
  group('ValidatorsHelper - Email Validation', () {
    test('isValidEmail retorna true para emails válidos', () {
      expect(ValidatorsHelper.isValidEmail('user@example.com'), isTrue);
      expect(ValidatorsHelper.isValidEmail('test.user@domain.co'), isTrue);
      expect(ValidatorsHelper.isValidEmail('user+tag@example.com'), isTrue);
      expect(ValidatorsHelper.isValidEmail('user_123@test-domain.com'), isTrue);
      expect(ValidatorsHelper.isValidEmail('a@b.co'), isTrue);
    });

    test('isValidEmail retorna false para emails inválidos', () {
      expect(ValidatorsHelper.isValidEmail('invalid.email'), isFalse);
      expect(ValidatorsHelper.isValidEmail('user@'), isFalse);
      expect(ValidatorsHelper.isValidEmail('@example.com'), isFalse);
      expect(ValidatorsHelper.isValidEmail('user@domain'), isFalse);
      expect(ValidatorsHelper.isValidEmail('user @example.com'), isFalse);
      expect(ValidatorsHelper.isValidEmail(''), isFalse);
      expect(ValidatorsHelper.isValidEmail(null), isFalse);
    });

    test('isValidEmail maneja espacios correctamente', () {
      expect(ValidatorsHelper.isValidEmail('  user@example.com  '), isTrue);
      expect(ValidatorsHelper.isValidEmail('   '), isFalse);
    });
  });

  group('ValidatorsHelper - Phone Validation', () {
    test('isValidPhone retorna true para teléfonos válidos', () {
      expect(ValidatorsHelper.isValidPhone('1112345678'), isTrue);
      expect(ValidatorsHelper.isValidPhone('+541112345678'), isTrue);
      expect(ValidatorsHelper.isValidPhone('+54 9 11 1234-5678'), isTrue);
      expect(ValidatorsHelper.isValidPhone('(11) 1234-5678'), isTrue);
    });

    test('isValidPhone retorna false para teléfonos inválidos', () {
      expect(ValidatorsHelper.isValidPhone('123'), isFalse);
      expect(ValidatorsHelper.isValidPhone('abcd'), isFalse);
      expect(ValidatorsHelper.isValidPhone(''), isFalse);
      expect(ValidatorsHelper.isValidPhone(null), isFalse);
    });
  });

  group('ValidatorsHelper - String Validation', () {
    test('isNotEmpty valida cadenas no vacías', () {
      expect(ValidatorsHelper.isNotEmpty('texto'), isTrue);
      expect(ValidatorsHelper.isNotEmpty('  texto  '), isTrue);
      expect(ValidatorsHelper.isNotEmpty(''), isFalse);
      expect(ValidatorsHelper.isNotEmpty('   '), isFalse);
      expect(ValidatorsHelper.isNotEmpty(null), isFalse);
    });

    test('hasMinLength valida longitud mínima', () {
      expect(ValidatorsHelper.hasMinLength('texto', 3), isTrue);
      expect(ValidatorsHelper.hasMinLength('texto', 5), isTrue);
      expect(ValidatorsHelper.hasMinLength('texto', 6), isFalse);
      expect(ValidatorsHelper.hasMinLength('', 1), isFalse);
      expect(ValidatorsHelper.hasMinLength(null, 1), isFalse);
    });

    test('hasMaxLength valida longitud máxima', () {
      expect(ValidatorsHelper.hasMaxLength('texto', 10), isTrue);
      expect(ValidatorsHelper.hasMaxLength('texto', 5), isTrue);
      expect(ValidatorsHelper.hasMaxLength('texto', 4), isFalse);
      expect(ValidatorsHelper.hasMaxLength('', 5), isTrue);
      expect(ValidatorsHelper.hasMaxLength(null, 5), isTrue);
    });
  });
}
