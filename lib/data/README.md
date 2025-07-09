# Data Layer - Documentación de la Base de Datos

## 📚 Contexto

La capa de **Data** implementa los repositorios definidos en el dominio y maneja todas las interacciones con Firebase Firestore. Esta documentación detalla la estructura completa de la base de datos, sus direcciones y el propósito de cada colección.

## 🗂️ Estructura de Archivos en Data

```
lib/data/
├── account_repository_impl.dart     # Gestión de cuentas de negocio
├── auth_repository_impl.dart        # Autenticación de usuarios
├── catalogue_repository_impl.dart   # Catálogo de productos
├── cash_register_repository_impl.dart # Sistema de caja registradora
└── README.md                        # Esta documentación
```

## 🔥 Estructura de Firebase Firestore

### 📊 Esquema General

```
Firebase Project: commer-ef151
├── /APP/                           # Datos públicos y globales
│   └── /{COUNTRY}/                 # Datos por país (ARG, etc.)
│       ├── /PRODUCTOS/             # Productos públicos
│       ├── /MARCAS/                # Marcas registradas
│       ├── /REPORTS/               # Reportes de productos
│       └── /PRODUCTOS_BACKUP/      # Backup de productos
├── /ACCOUNTS/                      # Cuentas de negocios
│   └── /{ACCOUNT_ID}/              # Datos específicos por cuenta
│       ├── /CATALOGUE/             # Catálogo de productos
│       ├── /CATEGORY/              # Categorías
│       ├── /PROVIDER/              # Proveedores
│       ├── /TRANSACTIONS/          # Historial de ventas
│       ├── /USERS/                 # Usuarios administradores
│       ├── /CASHREGISTERS/         # Cajas registradoras activas
│       ├── /RECORDS/               # Historial de arqueos
│       └── /FIXERDESCRIPTIONS/     # Descripciones fijas
└── /USERS/                         # Perfiles de usuarios
    └── /{EMAIL}/                   # Datos por usuario
        └── /ACCOUNTS/              # Cuentas administradas
```

---

## 📍 Direcciones Detalladas de la Base de Datos

### 🌐 Colecciones Públicas (/APP)

#### **Información de la Aplicación**
```dart
/APP/
├── INFO                            # Información general de la app
```
**Propósito**: Configuración global, versión de la app, URLs de descarga.
**Uso**: Verificar actualizaciones, obtener configuraciones generales.

#### **Productos Públicos**
```dart
/APP/{COUNTRY}/PRODUCTOS/
├── {PRODUCT_ID}/                   # Producto específico
│   └── PRICES/                     # Historial de precios
│       └── {PRICE_ID}              # Registro de precio específico
```
**Propósito**: Base de datos pública de productos con precios de diferentes comercios.
**Uso**: Búsqueda de productos, comparación de precios, verificación de códigos.

#### **Marcas y Categorización**
```dart
/APP/{COUNTRY}/MARCAS/              # Marcas registradas
/APP/{COUNTRY}/REPORTS/             # Reportes de productos
/APP/{COUNTRY}/PRODUCTOS_BACKUP/    # Backup de productos
/APP/{COUNTRY}/BRANDS_BACKUP/       # Backup de marcas
```
**Propósito**: Gestión de marcas, reportes de moderación y backups de seguridad.

---

### 🏢 Colecciones de Cuentas de Negocio (/ACCOUNTS)

#### **Cuenta Principal**
```dart
/ACCOUNTS/{ACCOUNT_ID}              # Datos del negocio
```
**Propósito**: Información del negocio (nombre, dirección, configuración, suscripción).
**Uso**: Perfil del negocio, configuraciones, estado de suscripción.

#### **Catálogo de Productos**
```dart
/ACCOUNTS/{ACCOUNT_ID}/CATALOGUE/
├── {PRODUCT_ID}                    # Producto en el catálogo
```
**Propósito**: Productos específicos del negocio con precios, stock y configuraciones.
**Uso**: Gestión de inventario, precios de venta, control de stock.

#### **Organización del Catálogo**
```dart
/ACCOUNTS/{ACCOUNT_ID}/CATEGORY/
├── {CATEGORY_ID}                   # Categoría específica
│   └── subcategories: {}           # Subcategorías anidadas

/ACCOUNTS/{ACCOUNT_ID}/PROVIDER/
├── {PROVIDER_ID}                   # Proveedor específico
```
**Propósito**: Organización del catálogo en categorías y gestión de proveedores.
**Uso**: Filtrado de productos, organización del inventario.

#### **Historial de Ventas**
```dart
/ACCOUNTS/{ACCOUNT_ID}/TRANSACTIONS/
├── {TRANSACTION_ID}                # Venta específica
```
**Propósito**: Registro completo de todas las ventas realizadas.
**Uso**: Historial de ventas, reportes, análisis de datos.

#### **Gestión de Usuarios**
```dart
/ACCOUNTS/{ACCOUNT_ID}/USERS/
├── {EMAIL}                         # Usuario administrador
```
**Propósito**: Usuarios con permisos administrativos en la cuenta.
**Uso**: Control de acceso, permisos, multiusuario.

---

### 💰 Sistema de Caja Registradora

#### **Cajas Registradoras Activas**
```dart
/ACCOUNTS/{ACCOUNT_ID}/CASHREGISTERS/
├── {CASHREGISTER_ID}               # Caja abierta actualmente
```
**Propósito**: Cajas registradoras que están actualmente abiertas y operando.
**Uso**: Control de caja diario, registro de ventas en tiempo real.

**Estructura de datos**:
```typescript
{
  id: string,                       // ID único de la caja
  description: string,              // Descripción (ej: "Caja Principal")
  opening: DateTime,                // Fecha y hora de apertura
  closure: DateTime,                // Fecha y hora de cierre
  initialCash: number,              // Monto inicial en efectivo
  sales: number,                    // Cantidad de ventas realizadas
  billing: number,                  // Monto total facturado
  discount: number,                 // Descuentos aplicados
  cashInFlow: number,               // Ingresos adicionales
  cashOutFlow: number,              // Egresos de caja
  expectedBalance: number,          // Balance esperado
  balance: number,                  // Balance real al cierre
  cashInFlowList: [],               // Lista de ingresos
  cashOutFlowList: []               // Lista de egresos
}
```

#### **Historial de Arqueos**
```dart
/ACCOUNTS/{ACCOUNT_ID}/RECORDS/
├── {RECORD_ID}                     # Arqueo de caja cerrado
```
**Propósito**: Registro histórico de todas las cajas cerradas y arqueos realizados.
**Uso**: Análisis histórico, reportes de períodos, auditorías.

#### **Descripciones Fijas**
```dart
/ACCOUNTS/{ACCOUNT_ID}/FIXERDESCRIPTIONS/
├── {DESCRIPTION}                   # Descripción predefinida
```
**Propósito**: Descripciones frecuentes para movimientos de caja (ej: "Pago de servicios").
**Uso**: Agilizar el registro de movimientos de caja.

---

### 👥 Gestión de Usuarios (/USERS)

#### **Perfiles de Usuario**
```dart
/USERS/{EMAIL}/
├── ACCOUNTS/                       # Cuentas que administra
│   └── {ACCOUNT_ID}                # Referencia a cuenta específica
```
**Propósito**: Gestión de usuarios multi-cuenta, permisos y accesos.
**Uso**: Login, cambio de cuenta, gestión de permisos.

---

## 🔄 Flujos de Datos del Sistema de Caja

### **Apertura de Caja**
1. **Validación**: Verificar que no hay otra caja abierta
2. **Creación**: Crear documento en `/CASHREGISTERS/`
3. **Inicialización**: Establecer monto inicial y fecha de apertura

### **Registro de Venta**
1. **Actualización**: Incrementar `sales`, `billing` en la caja activa
2. **Transacción**: Crear documento en `/TRANSACTIONS/`
3. **Stock**: Decrementar stock en `/CATALOGUE/`

### **Movimientos de Caja**
1. **Ingreso**: Agregar a `cashInFlowList` y sumar a `cashInFlow`
2. **Egreso**: Agregar a `cashOutFlowList` y restar de `cashOutFlow`
3. **Actualización**: Recalcular `expectedBalance`

### **Cierre de Caja**
1. **Balance**: Registrar balance final real
2. **Cálculo**: Calcular diferencia vs. balance esperado
3. **Archivo**: Mover de `/CASHREGISTERS/` a `/RECORDS/`
4. **Limpieza**: Eliminar de cajas activas

---

## 📊 Consultas Optimizadas

### **Queries de Rendimiento**
```dart
// Productos más vendidos
/ACCOUNTS/{id}/CATALOGUE
  .where("sales", isNotEqualTo: 0)
  .orderBy("sales", descending: true)
  .limit(50)

// Transacciones por fecha
/ACCOUNTS/{id}/TRANSACTIONS
  .where('creation', isGreaterThan: startDate)
  .where('creation', isLessThan: endDate)
  .orderBy('creation', descending: true)

// Arqueos del último mes
/ACCOUNTS/{id}/RECORDS
  .where('opening', isGreaterThan: lastMonth)
  .orderBy('opening', descending: true)
```

### **Indexes Requeridos**
- `TRANSACTIONS`: `creation` (descending)
- `RECORDS`: `opening` (descending)
- `CATALOGUE`: `sales` (descending), `upgrade` (descending)

---

## 🛡️ Seguridad y Reglas

### **Firestore Security Rules**
```javascript
// Acceso a cuentas solo para administradores
match /ACCOUNTS/{accountId} {
  allow read, write: if isAccountAdmin(accountId);
}

// Productos públicos solo lectura para usuarios
match /APP/{country}/PRODUCTOS/{productId} {
  allow read: if request.auth != null;
  allow write: if isGlobalModerator();
}
```

---

## 🔧 Herramientas de Desarrollo

### **Servicios Implementados**
- `DatabaseCloudService`: Centraliza todas las referencias de Firestore
- `CashRegisterRepository`: Interfaz para operaciones de caja
- `CashRegisterRepositoryImpl`: Implementación con Firebase
- `CashRegisterUsecases`: Lógica de negocio del sistema de caja

### **Utilidades**
- Generación de IDs únicos basados en timestamp
- Validaciones de datos antes de escritura
- Manejo de errores con mensajes descriptivos
- Streams para sincronización en tiempo real

---

## 📈 Métricas y Monitoreo

### **KPIs del Sistema de Caja**
- Ventas diarias/mensuales
- Diferencias de arqueo
- Movimientos de caja promedio
- Tiempo de operación de cajas

### **Alertas Recomendadas**
- Diferencias significativas en arqueos
- Cajas abiertas por más de 24 horas
- Movimientos de caja inusuales
- Fallos en sincronización

---

## 🚀 Próximas Mejoras

1. **Implementar cache local** para operaciones offline
2. **Añadir backup automático** de datos críticos
3. **Desarrollar dashboard** de métricas en tiempo real
4. **Integrar notificaciones** para eventos importantes
5. **Optimizar queries** con paginación automática

---

*Documentación actualizada: Julio 2025*  
*Versión del proyecto: Flutter Web con Clean Architecture*
