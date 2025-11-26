---
trigger: always_on
---

# 🛒 SellWeb - Portal de Ventas Web

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
- 🔍 **Búsqueda Inteligente**: productos
- 🎯 **UI Minimalista**: Diseño limpio y enfocado en productividad

### 🔒 Seguridad y Roles
- 👤 **Sistema de Roles**: Admin, Super Admin con permisos granulares
- 🛡️ **Firestore Rules**: Reglas de seguridad a nivel de base de datos
- 🔐 **Autenticación Persistente**: Sesión mantenida con tokens seguros

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

### Testing (Configurado)
- `flutter_test` - Unit & Widget Tests
- `mockito` - Mocking de dependencias
- `build_runner` - Code generation

---

### Testing (Configurado)
- `flutter_test` - Unit & Widget Tests
- `mockito` - Mocking de dependencias
- `build_runner` - Code generation

---

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
