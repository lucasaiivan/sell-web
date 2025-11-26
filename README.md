# 🛒 SellWeb - Portal de Ventas Web

> **Sistema POS moderno desarrollado con Flutter Web para gestión integral de ventas, inventario y análisis de negocio.**

[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-00D9FF)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

---

## 📋 Tabla de Contenidos

- [Características](#-características-principales)
- [Arquitectura](#️-arquitectura)
- [Tech Stack](#-tech-stack)
- [Setup](#-quick-start)
- [Features](#-features-implementadas)
- [Desarrollo](#-guía-de-desarrollo)
- [Testing](#-testing)
- [Deployment](#-deployment)

---

## 🚀 Características Principales

### 💼 Gestión de Negocio
- ✅ **Autenticación Segura**: Login con Google + Firebase Auth
- ✅ **Catálogo de Productos**: CRUD completo con categorías, proveedores y control de stock
- ✅ **Sistema POS**: Proceso de ventas con múltiples métodos de pago (Efectivo, Transferencia, Tarjeta)
- ✅ **Control de Inventario**: Alertas de stock bajo y seguimiento en tiempo real
- ✅ **Caja Registradora**: Arqueo de caja y control de turnos
- ✅ **Analytics**: Dashboard con métricas clave (transacciones, ganancias, historial)
- ✅ **Impresión de Tickets**: Soporte para impresoras térmicas con formato personalizado

### 🎨 Experiencia de Usuario
- 🌓 **Modo Claro/Oscuro**: Temas adaptativos con Material Design 3
- 📱 **Responsive Design**: Optimizado para escritorio, tablet y móvil
- ⚡ **Animaciones Fluidas**: Transiciones suaves con Flutter Animate
- 🔍 **Búsqueda Inteligente**: Filtrado en tiempo real de productos y transacciones
- 🎯 **UI Minimalista**: Diseño limpio y enfocado en productividad

### 🔒 Seguridad y Roles
- 👤 **Sistema de Roles**: Admin, Super Admin con permisos granulares
- 🛡️ **Firestore Rules**: Reglas de seguridad a nivel de base de datos
- 🔐 **Autenticación Persistente**: Sesión mantenida con tokens seguros

---

## 🏗️ Arquitectura

### Feature-First + Clean Architecture

Este proyecto implementa **arquitectura por features** donde cada módulo de negocio es **autónomo** y sigue **Clean Architecture** internamente:

```
lib/
├── 📱 app/                      # Configuración de la aplicación
│   ├── router/                  # AppRouter (GoRouter/Navigator)
│   └── app.dart                 # MaterialApp + Providers globales
│
├── 🏗️ core/                     # Infraestructura transversal
│   ├── config/                  # Firebase, OAuth, Environment
│   ├── constants/               # Constantes compartidas
│   ├── di/                      # Dependency Injection (get_it + injectable)
│   ├── errors/                  # Failures, Exceptions
│   ├── presentation/            # UI Components reutilizables
│   │   ├── theme/               # AppTheme, Material 3
│   │   ├── widgets/             # Botones, Inputs, Cards
│   │   └── helpers/             # DialogHelper, Formatters
│   ├── services/                # Servicios externos
│   │   ├── database/            # FirestoreService
│   │   ├── storage/             # SharedPreferences
│   │   └── printing/            # PrintingService
│   ├── usecases/                # UseCase<Type, Params> base
│   └── utils/                   # Date, String, Number helpers
│
└── ✨ features/                 # Módulos de negocio (Feature-First)
    │
    ├── 🔐 auth/                 # Autenticación
    │   ├── domain/              # User, AuthRepository, UseCases
    │   ├── data/                # UserModel, AuthDataSource, RepoImpl
    │   └── presentation/        # AuthProvider, LoginPage, Widgets
    │
    ├── 📦 catalogue/            # Gestión de Productos
    │   ├── domain/              # Product, Category, Supplier
    │   ├── data/                # ProductModel, FirestoreDataSource
    │   └── presentation/        # CatalogueProvider, CataloguePage
    │
    ├── 💰 sales/                # Proceso de Ventas (POS)
    │   ├── domain/              # Sale, SaleItem, PaymentMethod
    │   ├── data/                # SaleModel, SalesDataSource
    │   └── presentation/        # SalesProvider, POSPage, Widgets
    │
    ├── 💵 cash_register/        # Control de Caja
    │   ├── domain/              # CashRegister, CashMovement
    │   ├── data/                # CashRegisterModel
    │   └── presentation/        # CashRegisterProvider, CashPage
    │
    ├── 📊 analytics/            # Métricas y Reportes
    │   ├── domain/              # Transaction, AnalyticsMetrics
    │   ├── data/                # TransactionModel, AnalyticsDataSource
    │   └── presentation/        # AnalyticsProvider, AnalyticsPage
    │
    ├── 🏠 home/                 # Dashboard Principal
    │   └── presentation/        # HomePage, Navigation
    │
    └── 🚪 landing/              # Página de Bienvenida
        └── presentation/        # LandingPage
```

### Principios SOLID

**Dirección de Dependencias**: `Presentation → Domain ← Data`

- **Domain** (Capa Pura): Sin dependencias de Flutter/Firebase
- **Data** (Implementación): Implementa contratos del Domain
- **Presentation** (UI)**: Usa UseCases del Domain vía Providers

**Ejemplo de Flujo**:
```
UI → Provider → UseCase → Repository → DataSource → Firebase
     ↓           ↓          ↑           ↑
   (State)   (Logic)    (Contract)  (Impl)
```

---

## 🛠 Tech Stack

### Framework & Lenguaje
| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| **Dart** | 3.0+ | Lenguaje de programación |
| **Flutter** | 3.3.0+ | Framework UI multiplataforma |
| **Flutter Web** | Latest | Target de deployment |

### State Management & DI
| Paquete | Propósito |
|---------|-----------|
| `provider` | Gestión de estado con ChangeNotifier |
| `get_it` | Service Locator para DI |
| `injectable` | Generación automática de código DI (`@injectable`, `@lazySingleton`) |

### Backend as a Service (Firebase)
| Servicio | Uso |
|----------|-----|
| **Firebase Auth** | Autenticación con Google |
| **Cloud Firestore** | Base de datos NoSQL en tiempo real |
| **Firebase Storage** | Almacenamiento de imágenes de productos |
| **Firebase Hosting** | Deployment de la aplicación web |

### UI & Utilities
| Paquete | Propósito |
|---------|-----------|
| `flutter_animate` | Animaciones declarativas |
| `intl` | Formateo de fechas y moneda |
| `google_fonts` | Tipografías (Montserrat, etc.) |
| `shared_preferences` | Persistencia local |
| `pdf` | Generación de tickets PDF para impresión |

### Testing (Configurado)
- `flutter_test` - Unit & Widget Tests
- `mockito` - Mocking de dependencias
- `build_runner` - Code generation

---

## 🚀 Quick Start

### Pre-requisitos

```bash
# Verificar versiones
flutter --version  # >= 3.3.0
dart --version     # >= 3.0.0
```

### Instalación

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd sell-web

# 2. Instalar dependencias
flutter pub get

# 3. Generar código de DI (get_it + injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Configurar Firebase (si no existe)
# Colocar google-services.json / GoogleService-Info.plist
# Actualizar lib/core/config/firebase_config.dart
```

### Ejecutar en desarrollo

```bash
# Web (Chrome)
flutter run -d chrome

# Web (Edge)
flutter run -d edge

# Con hot-reload
# Presiona 'r' para hot reload, 'R' para hot restart
```

### Comandos Útiles

```bash
# Análisis de código
flutter analyze

# Formatear código
dart format lib/ test/

# Limpiar build cache
flutter clean

# Re-generar código DI (cuando agregues @injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# Build para producción
flutter build web --release
```

---

## ✨ Features Implementadas

### 🔐 Auth (Autenticación)
**Responsabilidad**: Gestión de autenticación y sesión de usuarios.

**Capas**:
- **Domain**: `User` entity, `AuthRepository`, `LoginUseCase`, `LogoutUseCase`
- **Data**: `FirebaseAuthDataSource`, `UserModel` con serialización
- **Presentation**: `AuthProvider`, `LoginPage`

**Stack**: Firebase Auth + Google Sign-In

---

### 📦 Catalogue (Catálogo de Productos)
**Responsabilidad**: CRUD de productos, categorías y proveedores.

**Capas**:
- **Domain**: `Product`, `Category`, `Supplier` entities
- **Data**: Firestore collections: `products`, `categories`, `suppliers`
- **Presentation**: `CatalogueProvider`, `CataloguePage`, `ProductDialog`

**Features**:
- ✅ Búsqueda en tiempo real
- ✅ Filtrado por categoría/proveedor
- ✅ Control de stock (alertas de stock bajo)
- ✅ Carga de imágenes a Firebase Storage
- ✅ Productos favoritos

---

### 💰 Sales (Punto de Venta)
**Responsabilidad**: Proceso completo de ventas (POS).

**Capas**:
- **Domain**: `Sale`, `SaleItem`, `PaymentMethod`, `Ticket`
- **Data**: Firestore collection: `sales`
- **Presentation**: `SalesProvider`, `POSPage`, Ticket widgets

**Features**:
- ✅ Carrito de compras dinámico
- ✅ Métodos de pago múltiples (Efectivo, Transferencia, Tarjeta)
- ✅ Cálculo automático de cambio
- ✅ Generación de tickets imprimibles
- ✅ Descuento de stock automático
- ✅ Historial de últimas ventas

---

### 💵 Cash Register (Caja)
**Responsabilidad**: Control de arqueo de caja y turnos.

**Capas**:
- **Domain**: `CashRegister`, `CashMovement`
- **Data**: Firestore collection: `cash_registers`
- **Presentation**: `CashRegisterProvider`, Apertura/Cierre de caja

**Features**:
- ✅ Apertura/cierre de turno
- ✅ Movimientos de ingreso/egreso
- ✅ Conciliación de efectivo
- ✅ Historial de arqueos

---

### 📊 Analytics (Métricas y Reportes)
**Responsabilidad**: Dashboard de métricas de negocio.

**Capas**:
- **Domain**: `Transaction`, `AnalyticsMetrics`
- **Data**: Agregación desde `sales` collection
- **Presentation**: `AnalyticsProvider`, `AnalyticsPage`

**Features**:
- ✅ Total de transacciones
- ✅ Ganancias totales
- ✅ Historial de transacciones con detalle
- ✅ Filtros por fecha
- ✅ Visualización de tickets desde el historial

---

### 🏠 Home (Dashboard)
**Responsabilidad**: Navegación principal y overview.

**Capas**:
- **Presentation**: `HomePage` con NavigationRail/Drawer

**Features**:
- ✅ Acceso rápido a todos los módulos
- ✅ Resumen de métricas principales
- ✅ Diseño adaptive (responsive)

---

## 👨‍💻 Guía de Desarrollo

### Crear un nuevo Feature

```bash
# Usar workflow automatizado
# Ver: .agent/workflows/create-feature.md
```

**Estructura requerida**:
```
lib/features/mi_feature/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── pages/
    └── widgets/
```

### Reglas de Imports

✅ **Permitido**:
```dart
// Imports relativos DENTRO del mismo feature
import '../domain/entities/product.dart';

// Imports absolutos para CORE o cruce de features
import 'package:sellweb/core/presentation/widgets/custom_button.dart';
```

❌ **Prohibido**:
```dart
// Nunca importar directamente otro feature
import 'package:sellweb/features/sales/domain/entities/sale.dart'; // ❌
```

### Inyección de Dependencias

**Anotar clases**:
```dart
// Provider
@injectable
class MyProvider extends ChangeNotifier { ... }

// UseCase / DataSource
@lazySingleton
class GetProductsUseCase { ... }

// Repository Impl
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository { ... }
```

**Registrar** (después de agregar `@injectable`):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Usar en UI**:
```dart
final provider = getIt<MyProvider>();
```

### Convenciones de Código

- **Entidades**: Inmutables, sin lógica de negocio
- **Models**: Mutables, con `fromJson`/`toJson`, `copyWith`
- **UseCases**: Un método `call()` por UseCase
- **Providers**: Extender `ChangeNotifier`, usar `notifyListeners()`
- **Widgets**: Stateless cuando sea posible
- **Naming**: `snake_case` para archivos, `PascalCase` para clases

---

## 🧪 Testing

### Estructura de Tests

```
test/
├── features/
│   └── [feature_name]/
│       ├── domain/
│       │   └── usecases/
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       └── presentation/
│           └── providers/
└── helpers/
    └── test_helper.dart
```

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/features/sales/domain/usecases/create_sale_usecase_test.dart

# Con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🚀 Deployment

### Firebase Hosting

```bash
# Build
flutter build web --release

# Deploy
firebase deploy --only hosting

# Preview
firebase hosting:channel:deploy preview
```

**Configuración**: Ver `firebase.json` y `.firebaserc`

---

## 📚 Recursos Adicionales

### Documentación Interna
- [Arquitectura Core](/lib/core/README.md)
- [Dependency Injection](/lib/core/di/README.md)
- [Error Handling](/lib/core/errors/README.md)
- [UseCase Pattern](/lib/core/usecases/README.md)

### READMEs de Features
- [Auth](/lib/features/auth/README.md)
- [Catalogue](/lib/features/catalogue/README.md)
- [Sales](/lib/features/sales/README.md)
- [Analytics](/lib/features/analytics/README.md)

### Workflows de Agente
- [Crear Feature](/.agent/workflows/create-feature.md)
- [Deploy](/.agent/workflows/deploy.md)

---

## 📄 Licencia

Proyecto Privado - Todos los derechos reservados

---

## 👥 Contribución

Este proyecto sigue estándares estrictos de calidad de código:
1. ✅ Código debe pasar `flutter analyze` sin errores
2. ✅ Seguir Feature-First + Clean Architecture
3. ✅ Documentar todo UseCase, Repository, Provider
4. ✅ Tests unitarios para lógica de negocio crítica

---

**Desarrollado con ❤️ usando Flutter & Firebase**
