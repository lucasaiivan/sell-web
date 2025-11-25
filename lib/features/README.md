# Features Directory

## Propósito
Directorio raíz que contiene todos los **módulos de negocio** organizados bajo el patrón **Feature-First + Clean Architecture**.

## Principios de Organización

### Feature-First Architecture
Cada feature es un **módulo autónomo** que agrupa toda su funcionalidad (domain, data, presentation) en un solo directorio. Esto permite:
- ✅ **Alta cohesión** - Código relacionado está junto
- ✅ **Bajo acoplamiento** - Features son independientes
- ✅ **Escalabilidad** - Fácil agregar nuevos features
- ✅ **Mantenibilidad** - Cambios aislados por feature
- ✅ **Testing** - Test por feature independiente

### Clean Architecture
Cada feature sigue la estructura de capas:
```
feature_name/
├── domain/          # Lógica de negocio pura (sin dependencias)
│   ├── entities/    # Objetos de dominio inmutables
│   ├── repositories/# Contratos (interfaces)
│   └── usecases/    # Casos de uso de negocio
├── data/            # Implementación de acceso a datos
│   ├── models/      # DTOs con fromJson/toJson
│   ├── datasources/ # APIs, Firebase, etc.
│   └── repositories/# Implementación de contratos
└── presentation/    # Capa de UI
    ├── providers/   # State Management (ChangeNotifier)
    ├── pages/       # Pantallas completas
    ├── widgets/     # Widgets específicos del feature
    └── dialogs/     # Diálogos del feature
```

## Features Actuales

| Feature | Bounded Context | Dominio Principal |
|---------|----------------|-------------------|
| **[auth](auth/)** | Autenticación y autorización | Seguridad, sesiones, permisos |
| **[landing](landing/)** | Marketing público | Presentación, showcase, CTA |
| **[home](home/)** | Navegación principal | Dashboard, coordinación |
| **[catalogue](catalogue/)** | Gestión de productos | Inventario, categorías, CRUD |
| **[sales](sales/)** | Proceso de venta | Tickets, cobros, transacciones |
| **[cash_register](cash_register/)** | Gestión financiera | Cajas, arqueos, flujos de caja |

## Reglas de Oro

### 1. Dirección de Dependencias
```
Presentation → Domain ← Data
```
- **Presentation** depende de Domain (use cases)
- **Data** depende de Domain (implementa contratos)
- **Domain** NO depende de nadie (puro)

### 2. Aislamiento de Features
Un feature **NUNCA** importa archivos internos de otro feature:
```dart
// ❌ INCORRECTO
import '../../sales/presentation/providers/sales_provider.dart';

// ✅ CORRECTO - Solo a través de contratos públicos
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
```

### 3. Tipos de Imports

**Dentro del mismo feature:**
```dart
// Uso relativo está permitido
import '../domain/entities/product.dart';
import '../../data/models/product_model.dart';
```

**Entre features diferentes:**
```dart
// Siempre usar import absoluto
import 'package:sellweb/features/catalogue/domain/entities/product.dart';
```

**Desde core:**
```dart
// Código compartido siempre absoluto
import 'package:sellweb/core/presentation/widgets/buttons/buttons.dart';
import 'package:sellweb/core/services/theme/theme_service.dart';
```

### 4. Shared vs Feature-Specific

**Shared (en `/core`):**
- Widgets reutilizables (botones, inputs, dialogs base)
- Services transversales (theme, storage, printing)
- Utilidades puras (formatters, helpers)

**Feature-Specific:**
- Lógica de negocio única del feature
- Widgets específicos del dominio
- Providers con estado del feature

## Dependency Injection

Cada feature registra sus dependencias en `core/di/`:

```dart
// En injection_container.dart
@module
abstract class CatalogueModule {
  @lazySingleton
  CatalogueRepository catalogueRepository(CatalogueRepositoryImpl impl) => impl;
  
  @lazySingleton
  GetProductsUseCase getProductsUseCase(CatalogueRepository repo);
  
  @injectable
  CatalogueProvider catalogueProvider(GetProductsUseCase useCase);
}
```

## Mapa de Dependencias entre Features

```
┌──────────┐
│ Landing  │ (público, standalone)
└────┬─────┘
     │ links to
     ▼
┌──────────┐
│   Auth   │ (autenticación)
└────┬─────┘
     │ autentica a
     ▼
┌──────────┐      ┌────────────┐
│   Home   │─────▶│ Catalogue  │
└────┬─────┘      └─────┬──────┘
     │                  │
     │ coordina         │ consume
     ▼                  ▼
┌──────────┐      ┌────────────────┐
│  Sales   │─────▶│ Cash Register  │
└──────────┘ usa  └────────────────┘
```

**Relaciones:**
- **Home** coordina Sales y Catalogue
- **Sales** consume productos de Catalogue
- **Sales** actualiza Cash Register en cada venta
- **Auth** es usado por todos (usuario activo)

## Agregar un Nuevo Feature

### 1. Crear estructura base
```bash
mkdir -p lib/features/new_feature/{domain/{entities,repositories,usecases},data/{models,datasources,repositories},presentation/{providers,pages,widgets,dialogs}}
```

### 2. Crear README.md
Documenta propósito, responsabilidades, y estructura

### 3. Implementar capas
1. **Domain:** Entities → Repository contracts → Use Cases
2. **Data:** Models → Datasources → Repository impl
3. **Presentation:** Provider → Pages → Widgets

### 4. Registrar DI
Agregar módulo en `core/di/injection_container.dart`

### 5. Conectar navegación
Agregar rutas en `app/router/` si aplica

## Convenciones de Nombres

### Archivos
- `entity_name.dart` - Entities (domain)
- `entity_name_model.dart` - Models (data)
- `repository_name.dart` - Repository contract (domain)
- `repository_name_impl.dart` - Implementation (data)
- `action_usecase.dart` - Use cases
- `feature_provider.dart` - Providers
- `screen_name_page.dart` - Pages
- `component_name_widget.dart` - Widgets
- `purpose_dialog.dart` - Dialogs

### Clases
- PascalCase para clases
- Entities inmutables con `@immutable`
- Repositories con sufijo `Repository`
- Use cases descriptivos: `GetProductsUseCase`
- Providers con sufijo `Provider`

## Testing

Cada feature debe tener su directorio de tests:
```
test/
└── features/
    └── feature_name/
        ├── domain/
        ├── data/
        └── presentation/
```

## Documentación

Cada feature **DEBE** tener:
- ✅ `README.md` - Documentación del feature
- ✅ Docstrings en clases principales
- ✅ Comentarios en lógica compleja

## Referencias

- Ver [README de cada feature](.) para detalles específicos
- Arquitectura base en `/core/README.md`
- Configuración DI en `/core/di/README.md`
