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

| Feature | Estado | Bounded Context | Dominio Principal |
|---------|--------|----------------|-------------------|
| **[auth](auth/)** | ⚠️ En desarrollo | Autenticación y autorización | Seguridad, sesiones, permisos, roles |
| **[home](home/)** | ✅ Completo | Navegación principal | Dashboard, coordinación, menú principal |
| **[landing](landing/)** | ✅ Completo | Marketing público | Presentación, showcase, CTA |
| **[catalogue](catalogue/)** | ⚠️ En desarrollo | Gestión de productos | Inventario, categorías, CRUD, proveedores |
| **[sales](sales/)** | ✅ Funcional | Proceso de venta | POS, tickets, cobros, transacciones |
| **[cash_register](cash_register/)** | ✅ Funcional | Gestión financiera | Cajas, arqueos, flujos de caja |
| **[analytics](analytics/)** | ✅ Completo | Métricas y reportes | Transacciones, ganancias, análisis |
| **[multiuser](multiuser/)** | 📋 Planeado | Gestión multiusuario | Roles, permisos, equipos, sucursales |

### Leyenda de Estados

- ✅ **Completo**: Feature completamente funcional con todas las características planeadas
- ✅ **Funcional**: Operativo y estable, puede recibir mejoras
- ⚠️ **En desarrollo**: En proceso activo de implementación o mejora
- 📋 **Planeado**: Diseñado pero no implementado aún

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

El proyecto utiliza **`injectable`** y **`get_it`** para la inyección de dependencias.

### Regla de Oro: Constructor Injection
**NUNCA** usar `getIt<T>()` dentro de clases (Providers, Repositories, UseCases). Siempre inyectar las dependencias por constructor.

✅ **Correcto:**
```dart
@injectable
class SalesProvider extends ChangeNotifier {
  final ThermalPrinterHttpService _printerService;

  SalesProvider(this._printerService); // Inyectado
}
```

❌ **Incorrecto:**
```dart
class SalesProvider extends ChangeNotifier {
  void print() {
    final printer = getIt<ThermalPrinterHttpService>(); // Prohibido
    printer.print();
  }
}
```

### Registro de Módulos
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

## Backend & Data Layer

### Patrón de Comunicación
1. **Datasources**: Encargados de la comunicación directa con la fuente de datos (Firestore, API, Local Storage).
   - Deben inyectar las instancias de terceros (ej. `FirebaseFirestore`, `SharedPreferences`).
   - Manejan excepciones de la fuente (ej. `FirebaseException`).
   - Retornan `Models` (DTOs).

2. **Repositories**: Implementan el contrato del dominio.
   - Inyectan los Datasources.
   - Mapean `Models` a `Entities`.
   - Manejan errores y retornan `Either<Failure, T>`.

### Ejemplo Estándar
```dart
// Datasource
@lazySingleton
class ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  ProductRemoteDataSource(this._firestore);
  
  Future<List<ProductModel>> getProducts() async { ... }
}

// Repository
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;
  ProductRepositoryImpl(this._dataSource);
  
  @override
  Future<Either<Failure, List<Product>>> getProducts() async { ... }
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
│   Auth   │ (autenticación) ───────────┐
└────┬─────┘                            │
     │ autentica a                      │ usuario activo
     ▼                                  │
┌──────────┐      ┌────────────┐       │
│   Home   │─────▶│ Catalogue  │       │
└────┬─────┘      └─────┬──────┘       │
     │                  │               │
     │ coordina         │ consume       │
     ▼                  ▼               ▼
┌──────────┐      ┌────────────────┐   │
│  Sales   │─────▶│ Cash Register  │◀──┘
└────┬─────┘ usa  └────────┬───────┘
     │                     │
     │ registra            │ agrupa
     ▼                     ▼
┌──────────┐      ┌────────────────┐
│Analytics │◀─────│  Transactions  │
└──────────┘ lee  └────────────────┘
```

**Relaciones principales:**
- **Landing** → **Auth**: Landing page enlaza al login
- **Auth** → Todos: Proporciona usuario autenticado a todos los features
- **Home** → **Sales**, **Catalogue**, **Analytics**: Dashboard coordina navegación
- **Catalogue** → **Sales**: Sales consume productos del catálogo
- **Sales** → **Cash Register**: Cada venta se registra en caja activa
- **Cash Register** → **Transactions**: Genera transacciones en Firestore
- **Analytics** → **Transactions**: Lee y analiza transacciones

**Nota importante**: Features NO se importan directamente entre sí. La comunicación se realiza a través de:
- Providers compartidos (en `presentation/providers/`)
- Navegación por rutas
- Entidades compartidas (en `domain/entities/`)

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

## Documentación por Feature

Cada feature **DEBE** tener su propio README con:
- 🎯 Propósito y responsabilidades
- 📦 Componentes principales (Entities, UseCases, Providers)
- 🔄 Flujos principales de usuario
- 🔌 Integración con otros features
- ⚙️ Configuración específica
- ✅ Estado actual y roadmap

### READMEs Disponibles

| Feature | README | Estado Documentación |
|---------|--------|---------------------|
| Analytics | [analytics/README.md](analytics/README.md) | ✅ Completo |
| Auth | ⚠️ Pendiente | ⚠️ Por crear |
| Home | ⚠️ Pendiente | ⚠️ Por crear |
| Landing | ⚠️ Pendiente | ⚠️ Por crear |
| Catalogue | ⚠️ Pendiente | ⚠️ Por crear |
| Sales | ⚠️ Pendiente | ⚠️ Por crear |
| Cash Register | ⚠️ Pendiente | ⚠️ Por crear |
| Multiuser | 📋 No aplica | 📋 Feature no implementado |

## Referencias de Arquitectura

- [Arquitectura General](../README.md) - Visión completa del proyecto
- [Core Infrastructure](../core/README.md) - Servicios y utilities
- [Instrucciones Light](.github/instructions/ligh_intructions.instructions.md) - Guías de desarrollo
- [Testing Guide](../test/README.md) - Convenciones de testing

## Mejores Prácticas de Features

### Documentación Obligatoria
- ✅ `README.md` por feature con estructura estándar
- ✅ Docstrings en clases principales (Providers, UseCases, Repositories)
- ✅ Comentarios en lógica compleja o no obvia
- ✅ Ejemplos de uso cuando sea necesario

### Organización de Código
- ✅ Separar claramente capas (domain, data, presentation)
- ✅ Un archivo por clase (excepto clases muy pequeñas relacionadas)
- ✅ Nombres descriptivos para archivos y clases
- ✅ Exportar públicamente solo lo necesario

### Testing
- ✅ Tests unitarios para UseCases críticos
- ✅ Tests de integración para Providers
- ✅ Mocks generados con Mockito
- ✅ Cobertura mínima del 70% en lógica de negocio

---

**Última actualización**: Noviembre 2025
