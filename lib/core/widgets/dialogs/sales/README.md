# Sales Dialogs

## 📋 Propósito
Diálogos relacionados con el proceso de ventas y gestión de caja registradora.

## 📁 Archivos

### **Ventas Rápidas**
#### `quick_sale_dialog.dart`
- **Contexto**: Diálogo para ventas rápidas por monto fijo
- **Propósito**: Permite realizar ventas directas sin usar el catálogo
- **Uso**: Se abre desde el botón de venta rápida en la página principal

#### `quick_sale_dialog_new.dart`
- **Contexto**: Versión modernizada del diálogo de venta rápida
- **Propósito**: Implementación mejorada con Material Design 3
- **Uso**: Reemplazo moderno del diálogo original

### **Gestión de Caja Registradora**
#### `cash_register_dialog.dart`
- **Contexto**: Diálogo principal de gestión de caja
- **Propósito**: Permite operaciones básicas de caja registradora
- **Uso**: Se abre desde el menú de gestión de caja

#### `cash_register_management_dialog.dart` ⭐ **MEJORADO**
- **Contexto**: Diálogo avanzado de gestión de caja con diseño responsivo
- **Propósito**: Operaciones completas de administración de caja optimizadas para móvil y desktop
- **Uso**: Gestión completa de movimientos de caja con UX mejorada
- **Características**:
  - 📱 Diseño completamente responsivo (móvil/tablet/desktop)
  - 🎨 Animaciones fluidas y micro-interacciones
  - ✨ Efectos visuales con Material Design 3
  - 🎯 Estados de hover y feedback visual optimizado
  - 📐 Layouts adaptativos según tamaño de pantalla
  - 🔧 Helper de responsividad integrado
  - 🔄 **NUEVO**: Reorganización de botones con secciones diferenciadas
    - **Sección "Acciones de Caja"**: Deseleccionar y Cerrar Caja
    - **Sección "Flujo de Efectivo"**: Ingreso y Egreso de dinero
    - Mejor jerarquía visual y separación de funcionalidades

#### `cash_register_open_dialog.dart`
- **Contexto**: Diálogo para apertura de caja
- **Propósito**: Permite abrir la caja con monto inicial
- **Uso**: Al inicio del día laboral

#### `cash_register_close_dialog.dart`
- **Contexto**: Diálogo para cierre de caja
- **Propósito**: Permite cerrar la caja con arqueo
- **Uso**: Al finalizar el día laboral

#### `cash_flow_dialog.dart`
- **Contexto**: Diálogo de flujo de efectivo
- **Propósito**: Visualización y gestión de movimientos de efectivo
- **Uso**: Consulta de entradas y salidas de dinero

## 🎨 Mejoras Recientes - Cash Register Management Dialog

### ✨ Nuevas Características Responsivas
- **Diseño Adaptativo**: Diferentes layouts para móvil (vertical) y desktop (horizontal)
- **Animaciones Mejoradas**: Transiciones suaves de 300ms en elementos clave
- **Estados Visuales**: Feedback visual claro en botones y elementos interactivos
- **Micro-interacciones**: Efectos de hover, scale y rotación para mejor UX

### 📱 Optimizaciones Móviles
- Botones de ancho completo para mejor accesibilidad táctil
- Espaciado compacto sin sacrificar legibilidad
- Lista scrolleable con física de rebote (BouncingScrollPhysics)
- Iconos y textos apropiados para pantallas pequeñas

### 🖥️ Mejoras Desktop
- Efectos de hover en todos los elementos interactivos
- Disposición horizontal optimizada para pantallas anchas
- Espaciado generoso para mejor legibilidad
- Transiciones visuales sutiles que mejoran la percepción

## 🔧 Uso
```dart
// Venta rápida
showDialog(
  context: context,
  builder: (context) => QuickSaleDialog(provider: sellProvider),
);

// Apertura de caja
showDialog(
  context: context,
  builder: (context) => CashRegisterOpenDialog(),
);

// Cierre de caja
showDialog(
  context: context,
  builder: (context) => CashRegisterCloseDialog(),
);

// Gestión de caja
showDialog(
  context: context,
  builder: (context) => CashRegisterManagementDialog(),
);
```
