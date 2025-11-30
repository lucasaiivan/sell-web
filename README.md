# 🛒 SellWeb - Portal de Ventas Web

> **Sistema POS moderno desarrollado con Flutter Web para gestión integral de ventas, inventario y análisis de negocio.**

📘 **[Ver Informe Técnico Detallado](INFORME_PROYECTO.md)**

[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.0+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Feature--First-00D9FF)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Provider](https://img.shields.io/badge/State-Provider-blueviolet)](https://pub.dev/packages/provider)
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
### 🔐 Autenticación Persistente: Sesión mantenida con tokens seguros

---

## 🧠 Filosofía del Proyecto

SellWeb no es solo un CRUD; es una plataforma diseñada con principios sólidos:

1.  **Feature-First Architecture**: Modularidad extrema para permitir escalabilidad sin deuda técnica.
2.  **UX Obsession**: Micro-interacciones, animaciones fluidas y diseño adaptativo (Material 3) para una experiencia de usuario superior.
3.  **Robustez Financiera**: Lógica de negocio estricta para manejo de dinero, caja y stock.
4.  **Developer Experience**: Uso de herramientas modernas (`injectable`, `build_runner`) para un desarrollo ágil y seguro.

---

## 🏗️ Arquitectura

### Feature-First + Clean Architecture

Este proyecto implementa **arquitectura por features** donde cada módulo de negocio es **autónomo** y sigue **Clean Architecture** internamente. La arquitectura está optimizada para:

- ✅ **Escalabilidad**: Agregar features sin afectar el código existente
- ✅ **Mantenibilidad**: Cambios localizados en sus respectivos features
- ✅ **Testabilidad**: Cada capa es independiente y testeable
- ✅ **Reutilización**: Código compartido en `core/` con DI

**Estructura del Proyecto:**

```
lib/
├── 📱 main.dart                 # Punto de entrada + Configuración de DI
│
├── 🏗️ core/                     # Infraestructura transversal
│   ├── config/                  # Firebase, OAuth, App config
│   ├── constants/               # Constantes compartidas
│   ├── di/                      # Dependency Injection (get_it + injectable)
│   ├── errors/                  # Failures, Exceptions
│   ├── mixins/                  # Mixins reutilizables
│   ├── presentation/            # UI Components compartidos
│   │   ├── theme/               # AppTheme, Material 3
│   │   ├── widgets/             # Botones, Inputs, Cards, Dialogs
│   │   ├── dialogs/             # Sistema modular de diálogos
│   │   ├── modals/              # Bottom sheets y overlays
│   │   └── helpers/             # Helpers de UI
│   ├── services/                # Servicios de infraestructura
│   │   ├── database/            # FirestoreService
│   │   ├── storage/             # SharedPreferences
│   │   ├── printing/            # PrintingService
│   │   └── external/            # APIs externas
│   ├── usecases/                # UseCase<Type, Params> base
│   └── utils/                   # Formatters, Helpers, Validators
│
├── 💾 data/                     # Implementaciones de repositorios (Legacy)
│   ├── auth_repository_impl.dart
│   ├── catalogue_repository_impl.dart
│   ├── cash_register_repository_impl.dart
│   └── account_repository_impl.dart
│
├── 🎯 domain/                   # Entidades y contratos compartidos (Legacy)
│   ├── entities/                # CashRegister, Ticket, Product, User
│   ├── repositories/            # Contratos de repositorios
│   └── usecases/                # UseCases compartidos
│
├── 🎨 presentation/             # Providers y páginas globales (Legacy)
│   ├── providers/               # AuthProvider, CashRegisterProvider, etc.
│   ├── pages/                   # SellPage, CataloguePage (en transición)
│   └── widgets/                 # Widgets compartidos (migrados a core/)
│
└── ✨ features/                 # Módulos de negocio (Feature-First)
    ├── 🔐 auth/                 # Autenticación [EN DESARROLLO]
    ├── 🏠 home/                 # Dashboard Principal [COMPLETO]
    ├── 🚪 landing/              # Landing Page [COMPLETO]
    ├── 📦 catalogue/            # Catálogo de Productos [EN DESARROLLO]
    ├── 💰 sales/                # Proceso de Ventas (POS) [EN DESARROLLO]
    ├── 💵 cash_register/        # Control de Caja [EN DESARROLLO]
    ├── 📊 analytics/            # Métricas y Reportes [COMPLETO]
    └── 👥 multiuser/            # Gestión Multiusuario [PLANEADO]
```

**Nota sobre la estructura Legacy**: Este proyecto está en proceso de migración de arquitectura tradicional (domain/data/presentation en raíz) hacia **Feature-First**. Los features nuevos (`analytics/`, `multiuser/`) siguen la estructura completa de Clean Architecture, mientras que los existentes comparten `domain/` y `data/` en la raíz.

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

### Core Framework
| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| **Dart** | 3.3.0+ | Lenguaje de programación |
| **Flutter** | 3.3.0+ | Framework UI multiplataforma |
| **Flutter Web** | Latest | Target principal de deployment |

### State Management & Architecture
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `provider` | 6.1.5 | State management con ChangeNotifier |
| `get_it` | 7.7.0 | Service Locator para DI |
| `injectable` | 2.4.4 | Code generation para DI |
| `fpdart` | 1.1.0 | Programación funcional (Either, Option) |
| `equatable` | 2.0.5 | Value equality para entities |

### Backend as a Service (Firebase)
| Servicio | Versión | Uso |
|----------|---------|-----|
| `firebase_core` | 3.13.1 | Inicialización de Firebase |
| `firebase_auth` | 5.5.4 | Autenticación (Google, Anónima) |
| `cloud_firestore` | 5.6.8 | Base de datos NoSQL en tiempo real |
| `firebase_storage` | 12.4.7 | Almacenamiento de imágenes |
| `google_sign_in` | 6.3.0 | OAuth con Google |

### UI/UX Libraries
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter_animate` | 4.5.2 | Animaciones declarativas |
| `lottie` | 3.3.1 | Animaciones JSON (Lottie) |
| `shimmer` | 3.0.0 | Efectos de carga tipo skeleton |
| `cached_network_image` | 3.4.1 | Caché de imágenes de red |
| `flutter_staggered_grid_view` | 0.7.0 | Grids con staggered layout |

### Utilities & Tools
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `intl` | 0.20.2 | Formateo i18n (fechas, moneda) |
| `shared_preferences` | 2.5.3 | Persistencia local key-value |
| `pdf` | 3.11.3 | Generación de PDFs (tickets) |
| `screenshot` | 3.0.0 | Captura de widgets como imagen |
| `share_plus` | 11.0.0 | Compartir contenido |
| `url_launcher` | 6.3.1 | Abrir URLs externas |
| `image_picker` | 1.2.1 | Selector de imágenes |
| `path_provider` | 2.1.4 | Acceso a directorios del sistema |
| `cross_file` | 0.3.4+2 | Abstracción de archivos |
| `http` | 1.2.0 | Cliente HTTP |

### Server-Side (Opcional)
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `shelf` | 1.4.0 | HTTP server |
| `shelf_router` | 1.1.4 | Routing para servidor |
| `shelf_cors_headers` | 0.1.5 | CORS para APIs |

### Development & Testing
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter_test` | SDK | Testing framework |
| `mockito` | 5.4.4 | Mocking de dependencias |
| `mocktail` | 1.0.4 | Mocking alternativo |
| `fake_async` | 1.3.1 | Control de async en tests |
| `build_runner` | 2.4.0 | Code generation |
| `injectable_generator` | 2.4.4 | Generación de DI |
| `freezed` | 2.4.0 | Generación de data classes |
| `json_serializable` | 6.7.0 | Serialización JSON |
| `flutter_launcher_icons` | 0.14.4 | Generación de iconos |
| `flutter_lints` | 6.0.0 | Linting rules

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
**Estado**: ✅ Completo | **Última actualización**: Nov 2025

Gestión completa de autenticación y autorización de usuarios.

**Funcionalidades principales**:
- ✅ Autenticación con Google (OAuth 2.0)
- ✅ Inicio de sesión anónimo (modo invitado)
- ✅ Inicio de sesión silencioso (persistencia de sesión)
- ✅ Gestión de cuentas asociadas al usuario
- ✅ Sistema de roles (Admin, Super Admin)
- ✅ Cierre de sesión seguro

**Stack técnico**:
- Firebase Auth
- Google Sign-In
- SharedPreferences (persistencia de sesión)

**Arquitectura**:
- `domain/entities/user.dart` - Entidad `UserAuth`
- `domain/repositories/auth_repository.dart` - Contrato
- `domain/usecases/auth_usecases.dart` - Casos de uso
- `data/auth_repository_impl.dart` - Implementación con Firebase
- `presentation/providers/auth_provider.dart` - State management

---

### 🏠 Home (Dashboard Principal)
**Estado**: ✅ Completo | **Última actualización**: Nov 2025

Dashboard principal con navegación adaptativa y acceso a todos los módulos.

**Funcionalidades principales**:
- ✅ Navegación principal (NavigationRail/Drawer responsive)
- ✅ Acceso rápido a Ventas, Catálogo y Analytics
- ✅ Barra superior con avatar de usuario y controles
- ✅ Adaptativo a mobile/tablet/desktop
- ✅ Integración con tema claro/oscuro

**Arquitectura**:
- `features/home/presentation/` - Páginas y widgets de navegación
- Integración con providers globales (Auth, Theme)

---

### 🚪 Landing (Página de Bienvenida)
**Estado**: ✅ Completo | **Última actualización**: Nov 2025

Landing page pública con información del producto y call-to-action.

**Funcionalidades principales**:
- ✅ Diseño atractivo y responsive
- ✅ Showcase de características principales
- ✅ Call-to-action para registro/login
- ✅ Galería de screenshots
- ✅ Secciones de beneficios y planes

**Arquitectura**:
- `features/landing/presentation/` - Landing page y widgets

---

### 📦 Catalogue (Catálogo de Productos)
**Estado**: ⚠️ En desarrollo activo | **Última actualización**: Nov 2025

Gestión completa del catálogo de productos, categorías y proveedores.

**Funcionalidades principales**:
- ✅ CRUD completo de productos
- ✅ Gestión de categorías y proveedores
- ✅ Búsqueda en tiempo real con filtros
- ✅ Control de stock con alertas
- ✅ Carga de imágenes a Firebase Storage
- ✅ Productos favoritos
- ✅ Códigos de barras y SKUs
- ✅ Precios de compra/venta
- ⚠️ Integración con escáner (en desarrollo)

**Stack técnico**:
- Firestore (colecciones: `products`, `categories`, `suppliers`)
- Firebase Storage (imágenes de productos)
- Stream real-time updates

**Arquitectura (Legacy + en migración)**:
- `domain/entities/catalogue.dart` - Entidades compartidas
- `domain/usecases/catalogue_usecases.dart` - Casos de uso
- `data/catalogue_repository_impl.dart` - Implementación Firestore
- `presentation/providers/catalogue_provider.dart` - State management
- `presentation/pages/catalogue_page.dart` - UI principal

---

### 💰 Sales (Punto de Venta / POS)
**Estado**: ✅ Funcional | **Última actualización**: Nov 2025

Sistema completo de punto de venta con gestión de tickets y cobros.

**Funcionalidades principales**:
- ✅ Carrito de compras dinámico
- ✅ Búsqueda rápida de productos
- ✅ Múltiples métodos de pago (Efectivo, Transferencia, Tarjeta)
- ✅ Cálculo automático de cambio
- ✅ Sistema de descuentos
- ✅ Generación de tickets con formato personalizado
- ✅ Impresión de tickets (térmicas y PDF)
- ✅ Historial de ventas recientes
- ✅ Anulación de tickets
- ✅ Descuento automático de stock
- ✅ Integración con caja registradora

**Stack técnico**:
- Firestore colección `ACCOUNTS/{accountId}/TRANSACTIONS`
- PDF generation para tickets
- Printing service para impresoras térmicas

**Arquitectura**:
- `domain/entities/ticket_model.dart` - Entity principal
- `domain/usecases/sell_usecases.dart` - Lógica de negocio de tickets
- `presentation/providers/sell_provider.dart` - State management
- `presentation/pages/sell_page.dart` - UI del POS

**Mejoras recientes**:
- 🎯 Separación de responsabilidades (SellUsecases vs CashRegisterUsecases)
- 🎯 Sincronización automática de contadores
- 🎯 Validación de consistencia de datos

---

### 💵 Cash Register (Caja Registradora)
**Estado**: ✅ Funcional | **Última actualización**: Nov 2025

Sistema completo de gestión de caja registradora con arqueos y control de flujos.

**Funcionalidades principales**:
- ✅ Apertura/Cierre de caja con validaciones
- ✅ Registro automático de ventas
- ✅ Movimientos de caja (ingresos/egresos)
- ✅ Arqueo de caja (conciliación)
- ✅ Historial de cajas con filtros
- ✅ Múltiples cajas activas por cuenta
- ✅ Descriptores fijos para aperturas
- ✅ Sincronización en tiempo real
- ✅ Visualización de transacciones del día
- ✅ Validación de consistencia de contadores

**Stack técnico**:
- Firestore colección `ACCOUNTS/{accountId}/CASH_REGISTERS`
- Stream subscriptions para actualizaciones en tiempo real
- AppDataPersistenceService para estado local

**Arquitectura**:
- `domain/entities/cash_register_model.dart` - Entity principal
- `domain/usecases/cash_register_usecases.dart` - Operaciones de caja
- `domain/usecases/sell_usecases.dart` - Operaciones de tickets (separado)
- `data/cash_register_repository_impl.dart` - Implementación Firestore
- `presentation/providers/cash_register_provider.dart` - State management

**Mejoras recientes**:
- 🎯 Refactorización completa con estado inmutable
- 🎯 Separación de responsabilidades (caja vs tickets)
- 🎯 Sincronización automática de contadores
- 🎯 Corrección automática de desincronizaciones
- 🎯 Dialog de gestión optimizado con callbacks

---

### 📊 Analytics (Métricas y Reportes)
**Estado**: ✅ Completo | **Última actualización**: Nov 2025

Dashboard de análisis y métricas de negocio en tiempo real.

**Funcionalidades principales**:
- ✅ Total de transacciones por período
- ✅ Ganancias totales acumuladas
- ✅ Promedio por transacción
- ✅ Filtros por período (Hoy, Ayer, Este mes, Mes pasado, Este año, Año pasado)
- ✅ Historial detallado de transacciones
- ✅ Visualización de tickets desde historial
- ✅ Estados de carga/error

**Stack técnico**:
- Firestore queries con filtros temporales
- Agregación de datos en el cliente
- Formateo de moneda con `intl`

**Arquitectura (Feature-First completo)**:
- `features/analytics/domain/` - Entities, Repository contracts, UseCases
- `features/analytics/data/` - Models, DataSources, Repository impl
- `features/analytics/presentation/` - Provider, Page, Widgets

**Futuras mejoras planeadas**:
- 📊 Gráficas de tendencias
- 📊 Productos más vendidos
- 📊 Análisis por categoría
- 📊 Comparativas entre períodos
- 📊 Exportación de reportes

---

### 👥 Multiuser (Gestión Multiusuario)
**Estado**: 📋 Planeado | **Última actualización**: Nov 2025

Sistema de gestión de múltiples usuarios y permisos granulares.

**Funcionalidades planeadas**:
- 📋 Invitación de usuarios a cuentas
- 📋 Sistema de roles y permisos
- 📋 Control de acceso por módulo
- 📋 Auditoría de acciones por usuario
- 📋 Gestión de equipos y sucursales

**Nota**: Feature en fase de diseño, no implementado aún.

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
