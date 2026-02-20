import 'package:flutter_test/flutter_test.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';

void main() {
  group('CurrencyHelper', () {
    group('formatCurrency', () {
      test('debe formatear números enteros sin decimales', () {
        expect(CurrencyHelper.formatCurrency(700), '700 \$');
        expect(CurrencyHelper.formatCurrency(1000), '1.000 \$');
        expect(CurrencyHelper.formatCurrency(50000), '50.000 \$');
      });

      test('debe formatear números con decimales', () {
        expect(CurrencyHelper.formatCurrency(200.99), '200,99 \$');
        expect(CurrencyHelper.formatCurrency(1500.50), '1.500,50 \$');
        expect(CurrencyHelper.formatCurrency(999.01), '999,01 \$');
      });

      test('debe manejar ceros decimales', () {
        expect(CurrencyHelper.formatCurrency(100.00), '100 \$');
        expect(CurrencyHelper.formatCurrency(0.0), '0 \$');
      });

      test('debe respetar el símbolo de moneda personalizado', () {
        expect(CurrencyHelper.formatCurrency(700, symbol: '€'), '700 €');
        expect(
            CurrencyHelper.formatCurrency(200.99, symbol: 'USD'), '200,99 USD');
      });

      test('debe manejar números negativos', () {
        expect(CurrencyHelper.formatCurrency(-500), '-500 \$');
        expect(CurrencyHelper.formatCurrency(-150.75), '-150,75 \$');
      });

      test('debe formatear números grandes con separadores de miles', () {
        expect(CurrencyHelper.formatCurrency(1234567), '1.234.567 \$');
        expect(CurrencyHelper.formatCurrency(1234567.89), '1.234.567,89 \$');
      });
    });
  });
}
