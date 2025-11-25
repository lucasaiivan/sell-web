# 🛒 SellWeb - Portal de Ventas en la Web

Portal de ventas web desarrollado con Flutter que permite gestionar catálogos de productos, procesar ventas, administrar inventario y generar reportes de transacciones. La aplicación está diseñada con arquitectura Clean Architecture y sigue las mejores prácticas de desarrollo.

## 🚀 Características Principales

### 💼 Gestión de Negocio
- **Sistema de Autenticación**: Login con Google y gestión de cuentas múltiples
- **Gestión de Productos**: Catálogo completo con categorías, proveedores y control de stock
- **Proceso de Ventas**: Sistema POS con múltiples métodos de pago
- **Control de Inventario**: Alertas de stock y seguimiento de inventario
- **Sistema de Cajas**: Arqueo de caja y control de transacciones
- **Reportes**: Historial de ventas y análisis de performance

### 🎨 Interfaz de Usuario
- **Material Design 3**: Implementación completa de las últimas especificaciones
- **Diseño Responsive**: Adaptable a diferentes tamaños de pantalla
- **PWA Ready**: Aplicación web progresiva instalable
- **Modo Oscuro**: Soporte completo para temas claro y oscuro

### 🔒 Seguridad y Permisos
- **Sistema de Roles**: Administrador, super administrador y permisos personalizados
- **Control de Acceso**: Permisos granulares por funcionalidad

## 🏗️ Arquitectura del Proyecto

El proyecto sigue los principios de **Feature-First + Clean Architecture** con separación clara de responsabilidades:

```
lib/
├── 🏗️ core/                    # Infraestructura transversal
│   ├── config/                 # Configuraciones de Firebase y OAuth
│   ├── constants/              # Constantes y claves compartidas
│   ├── di/                     # Inyección de dependencias
│   ├── errors/                 # Manejo de errores y excepciones
│   ├── mixins/                 # Mixins reutilizables
│   ├── presentation/           # UI compartida
│   │   ├── theme/              # Sistema de temas Material 3
│   │   ├── widgets/            # Widgets reutilizables
│   │   ├── helpers/            # Helpers de UI
│   │   └── providers/          # Providers globales
│   ├── services/               # Servicios de infraestructura
│   │   ├── database/           # Firestore
│   │   ├── storage/            # Persistencia local
│   │   ├── printing/           # Servicio de impresión
│   │   └── external/           # APIs externas
│   ├── usecases/               # Contrato base UseCase
│   └── utils/                  # Utilidades y formatters
│
└── ✨ features/                # Módulos de negocio (Feature-First)
    │
    ├── 🔐 auth/                # Autenticación
    │   ├── domain/             # Entities, UseCases, Repositories
    │   ├── data/               # Models, DataSources, Repositories Impl
    │   └── presentation/       # Pages, Widgets, Providers
    │
    ├── 📦 catalogue/           # Gestión de productos
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    ├── 💰 sales/               # Proceso de ventas
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    ├── 💵 cash_register/       # Control de caja
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │
    ├── 🏠 home/                # Dashboard principal
    │   └── presentation/
    │
    └── 🚪 landing/             # Página de bienvenida
        └── presentation/
```

### Principios Arquitectónicos

**Feature-First**: Cada módulo de negocio es autónomo y sigue Clean Architecture internamente.

**Clean Architecture**: 
- **Domain**: Lógica de negocio pura (sin dependencias externas)
- **Data**: Implementación de repositorios y acceso a datos
- **Presentation**: UI y gestión de estado con Provider

**Dirección de Dependencias**: `Presentation → Domain ← Data`

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter 3.3.0+**: Framework principal
- **Material Design 3**: Sistema de diseño
- **Provider**: Gestión de estado
- **Flutter Animate**: Animaciones fluidas

### Backend y Servicios
- **Firebase Core**: Plataforma backend
- **Firebase Auth**: Autenticación de usuarios
- **Cloud Firestore**: Base de datos NoSQL
- **Firebase Storage**: Almacenamiento de archivos
- **Google Sign-In**: Autenticación social

```
