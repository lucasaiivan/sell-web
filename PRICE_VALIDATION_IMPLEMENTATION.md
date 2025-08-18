# Validaciones de Precios en ProductPriceEditDialog

## Validaciones Implementadas

### ✅ **Validaciones en Tiempo Real (Campos de Entrada)**

#### Precio de Compra (Opcional)
- ✅ **Campo opcional**: No se requiere valor
- ✅ **No negativo**: No puede ser menor a 0
- ✅ **Relación con precio de venta**: No puede ser mayor al precio de venta cuando ambos están definidos

#### Precio de Venta (Obligatorio)
- ✅ **Campo obligatorio**: Se requiere valor
- ✅ **Mayor a cero**: Debe ser mayor a 0
- ✅ **Relación con precio de compra**: No puede ser menor al precio de compra cuando ambos están definidos

### 🔒 **Validaciones Finales (Antes de Guardar)**

En el método `_saveChanges()` se ejecutan validaciones adicionales como capa de seguridad:

1. **Precio de venta obligatorio**:
   ```dart
   if (salePrice <= 0) {
     throw Exception('El precio de venta debe ser mayor a 0');
   }
   ```

2. **Precio de compra no negativo**:
   ```dart
   if (purchasePrice < 0) {
     throw Exception('El precio de compra no puede ser negativo');
   }
   ```

3. **Relación lógica entre precios**:
   ```dart
   if (purchasePrice > 0 && purchasePrice > salePrice) {
     throw Exception('El precio de compra (...) no puede ser mayor al precio de venta (...)');
   }
   ```

### 💡 **Información Visual para el Usuario**

Se agregó una sección informativa con las reglas de validación:

```dart
Widget _buildValidationInfo() {
  // Muestra un contenedor con las reglas:
  // • Precio de venta es obligatorio y debe ser mayor a 0
  // • Precio de compra es opcional
  // • Precio de compra no puede ser mayor al de venta
  // • Los precios no pueden ser negativos
}
```

### 🎯 **Comportamiento de Validación**

#### Validación en Tiempo Real:
- Se ejecuta cuando el usuario escribe en los campos
- Proporciona feedback inmediato
- Previene errores antes de intentar guardar

#### Validación al Guardar:
- Validación adicional como capa de seguridad
- Manejo de errores con mensajes descriptivos
- Muestra SnackBar con el error específico

#### Mensajes de Error Descriptivos:
- **Precio de venta requerido**: "El precio de venta es requerido"
- **Precio mayor a cero**: "El precio debe ser mayor a 0"
- **Precio negativo**: "El precio no puede ser negativo"
- **Relación de precios**: "El precio de compra no puede ser mayor al de venta"
- **Error con valores**: "El precio de compra ($XX.XX) no puede ser mayor al precio de venta ($YY.YY)"

### 🔄 **Flujo de Validación Completo**

1. **Usuario ingresa datos** → Validación en tiempo real
2. **Usuario hace clic en "Guardar"** → Validación del formulario (`_formKey.currentState!.validate()`)
3. **Si pasa validación del formulario** → Validaciones adicionales de seguridad
4. **Si todas las validaciones pasan** → Proceder con el guardado
5. **Si alguna validación falla** → Mostrar error específico y mantener el diálogo abierto

### 📋 **Reglas de Negocio Implementadas**

| Campo | Obligatorio | Validaciones |
|-------|------------|-------------|
| **Precio de Venta** | ✅ Sí | > 0, ≥ precio de compra |
| **Precio de Compra** | ❌ No | ≥ 0, ≤ precio de venta |

### 🛡️ **Beneficios de la Implementación**

- **Prevención de errores**: Validaciones en múltiples capas
- **Experiencia de usuario**: Feedback inmediato y mensajes claros
- **Integridad de datos**: Asegura datos válidos en la base de datos
- **Lógica de negocio**: Mantiene relaciones lógicas entre precios
- **Robustez**: Validaciones tanto en frontend como antes del guardado

La implementación garantiza que solo se guarden precios válidos y lógicamente consistentes, mejorando la calidad de los datos y la experiencia del usuario.
