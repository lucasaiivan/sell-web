# Validators Helper 🔍

**Helper para validación de campos de formulario**

## 🎯 Descripción

`ValidatorsHelper` es una clase de utilidad que provee validadores reutilizables para campos de formulario. Incluye validación de formato de email, teléfono y otras validaciones comunes de strings.

## 📦 Funciones Principales

### Validación de Email

```dart
ValidatorsHelper.isValidEmail(String? email)
```

Valida si una cadena tiene formato de email válido según RFC 5322 simplificado.

**Ejemplos:**
```dart
ValidatorsHelper.isValidEmail('user@example.com'); // true
ValidatorsHelper.isValidEmail('invalid.email');    // false
ValidatorsHelper.isValidEmail('user@');            // false
ValidatorsHelper.isValidEmail(null);               // false
```

### Validación de Teléfono

```dart
ValidatorsHelper.isValidPhone(String? phone)
```

Valida formato de número telefónico. Acepta formatos:
- `1112345678`
- `+541112345678`
- `+54 9 11 1234-5678`
- `(11) 1234-5678`

**Ejemplos:**
```dart
ValidatorsHelper.isValidPhone('1112345678');       // true
ValidatorsHelper.isValidPhone('+541112345678');    // true
ValidatorsHelper.isValidPhone('123');              // false
```

### Validaciones de String

```dart
ValidatorsHelper.isNotEmpty(String? value)
ValidatorsHelper.hasMinLength(String? value, int minLength)
ValidatorsHelper.hasMaxLength(String? value, int maxLength)
```

## 🔌 Uso en Formularios

### Con FormInputTextField

```dart
FormInputTextField(
  controller: _emailController,
  labelText: 'Email',
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un email';
    }
    if (!ValidatorsHelper.isValidEmail(value)) {
      return 'Ingrese un email válido';
    }
    return null;
  },
)
```

### Validación Múltiple

```dart
validator: (value) {
  if (!ValidatorsHelper.isNotEmpty(value)) {
    return 'Campo requerido';
  }
  if (!ValidatorsHelper.hasMinLength(value, 5)) {
    return 'Mínimo 5 caracteres';
  }
  if (!ValidatorsHelper.hasMaxLength(value, 50)) {
    return 'Máximo 50 caracteres';
  }
  return null;
}
```

## ✅ Testing

El helper incluye tests completos en `test/core/utils/validators_helper_test.dart`:

```bash
# Ejecutar tests
flutter test test/core/utils/validators_helper_test.dart
```

**Cobertura:**
- ✅ Validación de emails válidos e inválidos
- ✅ Validación de teléfonos en diversos formatos
- ✅ Validaciones de strings (vacío, longitud)
- ✅ Manejo de valores null y espacios

## 🏗️ Arquitectura

**Ubicación:** `lib/core/utils/helpers/validators_helper.dart`

**Tipo:** Helper puro sin dependencias de Flutter

**Patrón:** Clase con constructor privado y métodos estáticos

## 📋 Extensión Futura

Para agregar nuevos validadores:

1. Agregar método estático en `ValidatorsHelper`
2. Usar RegExp precompilado para performance
3. Documentar con ejemplos
4. Agregar tests correspondientes

**Ejemplo:**

```dart
/// Expresión regular para validar formato de URL
static final RegExp _urlRegex = RegExp(
  r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b',
);

/// Valida si una cadena tiene formato de URL válido
static bool isValidUrl(String? url) {
  if (url == null || url.isEmpty) {
    return false;
  }
  return _urlRegex.hasMatch(url.trim());
}
```

---

**Última actualización:** 28 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Completo
