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

El proyecto sigue los principios de **Clean Architecture** con una separación clara de responsabilidades:

```
lib/
├── 🏗️ core/                    # Infraestructura transversal
│   ├── config/                 # Configuraciones de la app
│   ├── constants/              # Constantes y configuraciones
│   ├── mixins/                 # Mixins reutilizables
│   ├── services/              # Servicios de infraestructura
│   └── utils/                 # Utilidades y validadores
├── 💾 data/                    # Capa de datos (repositorios impl.)
│   ├── account_repository_impl.dart
│   ├── auth_repository_impl.dart
│   ├── cash_register_repository_impl.dart
│   └── catalogue_repository_impl.dart
├── 🎯 domain/                  # Lógica de negocio pura
│   ├── entities/              # Entidades del dominio
│   │   ├── user.dart         # Usuarios y permisos
│   │   ├── catalogue.dart    # Productos y catálogo
│   │   └── ticket_model.dart # Tickets de venta
│   ├── repositories/         # Contratos de repositorios
│   └── usecases/            # Casos de uso del negocio
└── 🎨 presentation/           # Capa de presentación
    ├── pages/               # Páginas principales
    ├── providers/           # Gestión de estado
    └── widgets/            # Widgets reutilizables
```

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
