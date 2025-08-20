# 🔧 Utils - Utilidades y Helpers

El directorio `utils` contiene **utilidades reutilizables** que proporcionan funcionalidades comunes y transformaciones de datos utilizadas en toda la aplicación.

## 🎯 Propósito

Ofrecer funciones puras, helpers y utilidades que:
- **No dependan del contexto de Flutter** (excepto helpers específicos de UI)
- **Sean altamente reutilizables** entre diferentes features
- **Faciliten transformaciones** de datos comunes
- **Mantengan lógica compleja** en un lugar centralizado

## 📁 Estructura y Responsabilidades

```
utils/
├── formatters/         # Formateo de datos (moneda, fecha, texto)
├── validators/         # Validaciones de formularios y datos
├── helpers/           # Helpers específicos (PDF, imágenes, etc.)
├── catalogue_filter.dart  # Filtrado específico de catálogo
└── responsive_helper.dart # Helper para lógica responsive
```

## 📖 Subdirectorios

### 🎨 `/formatters` - Formateo de Datos
Funciones para formatear datos para presentación al usuario:

```dart
// currency_formatter.dart
String formatCurrency(double value, {String symbol = '\$'});

// date_formatter.dart  
String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'});

// text_formatter.dart
String capitalizeFirst(String text);
String formatPhoneNumber(String phone);
```

### ✅ `/validators` - Validaciones
Funciones para validar datos de entrada:

```dart
// form_validators.dart
String? validateEmail(String? email);
String? validatePassword(String? password);

// business_validators.dart
bool isValidPrice(double price);
bool isValidStock(int stock);
```

### 🛠️ `/helpers` - Helpers Específicos
Funciones complejas para tareas específicas:

```dart
// pdf_helper.dart
Future<File> generateTicketPdf(TicketModel ticket);

// image_helper.dart
Future<String> compressAndUploadImage(File image);

// share_helper.dart
Future<void> shareTicket(TicketModel ticket);
```

## 🔧 Convenciones de Uso

### Funciones Puras
```dart
// ✅ Correcto - Función pura sin efectos secundarios
String formatCurrency(double value) {
  return NumberFormat.currency(locale: 'es_AR').format(value);
}

// ❌ Evitar - Función con efectos secundarios
String formatCurrency(double value) {
  print('Formatting: $value'); // Efecto secundario
  _lastFormattedValue = value; // Estado mutable
  return NumberFormat.currency(locale: 'es_AR').format(value);
}
```

### Manejo de Errores
```dart
// ✅ Manejo explícito de errores
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'El email es requerido';
  }
  
  if (!AppConstants.emailRegex.hasMatch(email)) {
    return 'Formato de email inválido';
  }
  
  return null; // Válido
}
```

### Documentación Clara
```dart
/// Formatea un valor monetario según la configuración regional.
///
/// [value] El valor numérico a formatear
/// [symbol] El símbolo de moneda (por defecto '\$')
/// [simplified] Si debe usar notación abreviada (K, M)
/// 
/// Retorna el valor formateado como String.
/// 
/// Ejemplo:
/// ```dart
/// formatCurrency(1234.56) // "\$1,234.56"
/// formatCurrency(15000, simplified: true) // "\$15K"
/// ```
String formatCurrency(double value, {String symbol = '\$', bool simplified = false}) {
  // Implementation...
}
```

## ⚡ Performance y Optimización

### Lazy Loading para Recursos Costosos
```dart
class ExpensiveFormatter {
  static NumberFormat? _currencyFormatter;
  
  static NumberFormat get currencyFormatter {
    return _currencyFormatter ??= NumberFormat.currency(
      locale: AppConstants.defaultLocale,
      symbol: AppConstants.defaultCurrency,
    );
  }
}
```

### Caché para Resultados Repetitivos
```dart
class CacheableValidator {
  static final Map<String, bool> _emailCache = {};
  
  static bool isValidEmail(String email) {
    return _emailCache.putIfAbsent(
      email,
      () => AppConstants.emailRegex.hasMatch(email),
    );
  }
}
```

## 📚 Archivos Específicos

### `catalogue_filter.dart`
Utilidades específicas para filtrado de productos del catálogo:
- Filtros por categoría, precio, stock
- Búsqueda textual optimizada
- Ordenamiento por diferentes criterios

### `responsive_helper.dart`
Helper consolidado para lógica responsive:
- Cálculos de tamaños adaptativos
- Detección de características del dispositivo
- Helpers para layout responsive

## ✅ Buenas Prácticas

1. **Funciones Puras**: Preferir funciones sin efectos secundarios
2. **Una Responsabilidad**: Cada función debe hacer una cosa bien
3. **Naming Descriptivo**: Los nombres deben explicar claramente qué hace la función
4. **Testing Friendly**: Todas las funciones deben ser fáciles de testear
5. **Documentación**: Documentar parámetros, retornos y ejemplos de uso
6. **Manejo de Errores**: Manejar casos edge explícitamente

## 🚫 Anti-patterns a Evitar

```dart
// ❌ Funciones que hacen demasiado
String formatAndValidateAndSaveEmail(String email) {
  // Múltiples responsabilidades
}

// ❌ Dependencias de contexto Flutter innecesarias
String formatCurrency(BuildContext context, double value) {
  // No necesita context para formatear
}

// ❌ Estado mutable global
class GlobalFormatter {
  static String lastFormatted = ''; // Estado global mutable
}
```

## 🎯 Guidelines para Contribuir

Antes de agregar una nueva utilidad:

1. **Verificar existencia**: ¿Ya existe algo similar?
2. **Evaluar ubicación**: ¿Realmente pertenece a utils?
3. **Considerar reutilización**: ¿Se usará en múltiples places?
4. **Escribir tests**: Crear pruebas unitarias
5. **Documentar**: Agregar documentación clara

---

💡 **Tip**: Si una utilidad es específica de un feature, considerar ponerla en el feature específico en lugar de utils.
