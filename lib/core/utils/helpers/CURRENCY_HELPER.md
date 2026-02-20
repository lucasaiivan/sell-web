# CurrencyHelper - Formateo Inteligente de Moneda

## 📝 Descripción

Helper para formatear valores monetarios de manera inteligente, mostrando:
- **Números enteros** cuando no hay centavos: `700 $`, `1.500 $`
- **Decimales** solo cuando hay residuos: `200,99 $`, `1.500,50 $`

## 🎯 Características

- ✅ Formato inteligente (entero vs decimal)
- ✅ Separadores de miles con punto (`.`)
- ✅ Separador decimal con coma (`,`)
- ✅ Soporte para símbolos de moneda personalizados
- ✅ Manejo correcto de números negativos
- ✅ Números grandes con separadores de miles

## 💡 Uso

```dart
import 'package:sellweb/core/utils/helpers/currency_helper.dart';

// Números enteros (sin centavos)
CurrencyHelper.formatCurrency(700);        // '700 $'
CurrencyHelper.formatCurrency(1500);       // '1.500 $'
CurrencyHelper.formatCurrency(50000);      // '50.000 $'

// Números con decimales
CurrencyHelper.formatCurrency(200.99);     // '200,99 $'
CurrencyHelper.formatCurrency(1500.50);    // '1.500,50 $'
CurrencyHelper.formatCurrency(999.01);     // '999,01 $'

// Símbolo personalizado
CurrencyHelper.formatCurrency(700, symbol: '€');     // '700 €'
CurrencyHelper.formatCurrency(200.99, symbol: 'USD'); // '200,99 USD'

// Números negativos
CurrencyHelper.formatCurrency(-500);       // '-500 $'
CurrencyHelper.formatCurrency(-150.75);    // '-150,75 $'

// Números grandes
CurrencyHelper.formatCurrency(1234567);    // '1.234.567 $'
CurrencyHelper.formatCurrency(1234567.89); // '1.234.567,89 $'
```

## 📊 Integración en Analytics

El `CurrencyHelper` está integrado en:

- **MetricCard**: Facturación, Ganancia, Ticket Promedio
- **TransactionListItem**: Total de venta, Ganancia
- **PaymentMethodsCard**: Montos por método de pago

## 🧪 Tests

Tests completos disponibles en:
```
test/core/utils/helpers/currency_helper_test.dart
```

Ejecutar tests:
```bash
flutter test test/core/utils/helpers/currency_helper_test.dart
```

## 🎨 Ejemplos Visuales

### Antes (con NumberFormat.currency)
```
Facturación: $1,500.00
Ganancia: $450.00
Ticket Promedio: $75.00
```

### Después (con CurrencyHelper)
```
Facturación: 1.500 $
Ganancia: 450 $
Ticket Promedio: 75,50 $
```

## 🔧 Implementación Interna

```dart
static String formatCurrency(double value, {String symbol = '\$'}) {
  final absValue = value.abs();
  final hasDecimals = absValue != absValue.truncateToDouble();
  final isNegative = value < 0;
  
  if (hasDecimals) {
    // Con decimales: formato completo
    return '${_formatInteger(integerPart)},${decimalPart} $symbol';
  } else {
    // Sin decimales: solo entero
    return '${_formatInteger(integerPart)} $symbol';
  }
}
```

## ✅ Beneficios

1. **Legibilidad mejorada**: Números más limpios y fáciles de leer
2. **Espacio ahorrado**: Elimina `.00` innecesarios
3. **Formato local**: Usa convenciones españolas (`,` y `.`)
4. **Consistencia**: Formato uniforme en toda la app
5. **Flexibilidad**: Soporte para múltiples monedas

---

**Última actualización:** 26 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Producción
