````instructions
# Light Instructions - Flutter Web Sell App

## 🎯 Principios Fundamentales

### 🏛️ Arquitectura: Feature-First + Clean Architecture

**8 Reglas de Oro:**
1. ✅ **Feature-First**: Módulos autónomos en `lib/features/[feature]/`
2. ✅ **Clean Architecture**: Separación domain → data → presentation
3. ✅ **Dependency Injection**: `@injectable` + `@lazySingleton` con GetIt
4. ✅ **Imports relativos**: Dentro de features (`../`, `../../`)
5. ✅ **Imports absolutos**: Para `core/`, shared widgets, routing
6. ✅ **Reutilización**: Buscar en `lib/presentation/widgets/` antes de crear
7. ✅ **Documentación minimalista**: Solo lo necesario para entender el contexto
8. ❌ **No circular deps**: Features NO importan otros features

---

## 📐 Estructura de un Feature Modular

```
lib/features/[feature_name]/
├── data/                           # Capa de Datos
│   ├── datasources/                # Firebase, APIs, local storage
│   │   └── *_datasource.dart       # @lazySingleton
│   ├── models/                     # DTOs con serialización
│   │   └── *_model.dart            # fromJson/toJson, fromFirestore
│   └── repositories/               # Implementaciones
│       └── *_repository_impl.dart  # @LazySingleton(as: Contract)
│
├── domain/                         # Capa de Dominio (lógica pura)
│   ├── entities/                   # Entidades inmutables
│   │   └── *.dart                  # Clases puras sin dependencias
│   ├── repositories/               # Contratos (interfaces)
│   │   └── *_repository.dart       # abstract class
│   └── usecases/                   # Casos de uso
│       └── *_usecase.dart          # @lazySingleton
│
├── presentation/                   # Capa de Presentación
│   ├── providers/                  # State management
│   │   └── *_provider.dart         # @injectable + ChangeNotifier
│   ├── pages/                      # Pantallas principales
│   │   └── *_page.dart
│   └── widgets/                    # Widgets específicos del feature
│       └── *.dart
│
└── README.md                       # 📄 Documentación del feature
```

---

## 📋 Checklist Obligatorio

### 🔍 ANTES de Crear Algo Nuevo

**Componentes UI:**
- [ ] ¿Botón? → Revisar `presentation/widgets/buttons/`
- [ ] ¿Input? → Revisar `presentation/widgets/inputs/`
- [ ] ¿Diálogo? → Revisar `presentation/widgets/dialogs/`
- [ ] ¿Card/Avatar? → Revisar `presentation/widgets/component/`
- [ ] ¿Feedback/Loading? → Revisar `presentation/widgets/feedback/`
- [ ] ¿Específico del feature? → Crear en `features/[feature]/presentation/widgets/`

**Lógica de Negocio:**
- [ ] ¿Feature completo? → `features/[feature]/` con estructura Clean
- [ ] ¿Servicio compartido? → `core/services/`
- [ ] ¿Utilidad? → `core/utils/`
- [ ] ¿Caso de uso? → `features/[feature]/domain/usecases/` con `@lazySingleton`
- [ ] ¿Provider? → Anotar con `@injectable`, registrar DI

---

## 🔧 Dependency Injection

### Anotaciones

```dart
// Provider (state management)
@injectable
class MyProvider extends ChangeNotifier {
  final MyUseCase useCase;
  MyProvider(this.useCase);
}

// Use Case (lógica de negocio)
@lazySingleton
class MyUseCase {
  final MyRepository repository;
  MyUseCase(this.repository);
}

// Repository Implementation
@LazySingleton(as: MyRepository)
class MyRepositoryImpl implements MyRepository {
  final MyDataSource dataSource;
  MyRepositoryImpl(this.dataSource);
}

// DataSource
@lazySingleton
class MyDataSource {
  final FirebaseFirestore firestore;
  MyDataSource(this.firestore);
}
```

### Regenerar DI

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Configuración en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  configureDependencies(); // ⭐ Inicializar DI
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<MyProvider>()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 📦 Imports: Cuándo Usar Qué

### Imports Relativos (Dentro del Feature)

```dart
// ✅ Dentro de features/catalogue/presentation/pages/
import '../providers/catalogue_provider.dart';      // Provider del mismo feature
import '../widgets/product_card.dart';              // Widget del mismo feature
import '../../domain/entities/product.dart';        // Entity del mismo feature
import '../../domain/usecases/get_products.dart';   // UseCase del mismo feature
```

### Imports Absolutos (Cross-Cutting)

```dart
// ✅ Core services, shared widgets, otros features para routing
import 'package:sellweb/core/services/database/firestore_service.dart';
import 'package:sellweb/core/utils/helpers/date_formatter.dart';
import 'package:sellweb/presentation/widgets/buttons/app_button.dart';
import 'package:sellweb/features/catalogue/presentation/pages/catalogue_page.dart';
```

### Reglas de Imports

| Desde | Hacia | Tipo de Import | Permitido |
|-------|-------|----------------|-----------|
| Feature interno | Mismo feature | Relativo `../` | ✅ |
| Feature | `core/` | Absoluto | ✅ |
| Feature | `presentation/widgets/` | Absoluto | ✅ |
| Feature | Otro feature | Absoluto (solo routing) | ⚠️ Solo páginas |
| `core/` | Feature | - | ❌ Prohibido |
| `main.dart` | Feature | Absoluto | ✅ |

---

## 📝 Documentación Minimalista

### 🎯 Patrón de Documentación Estándar

**Principio:** Documentar **solo lo necesario** para entender el contexto y responsabilidades.

### 1. Clases

```dart
/// [Tipo]: [Nombre Descriptivo]
///
/// **Responsabilidad:**
/// - [Responsabilidad principal 1]
/// - [Responsabilidad principal 2]
///
/// **Dependencias:** [Lista de dependencias inyectadas]
/// **Inyección DI:** [@injectable | @lazySingleton]
@injectable
class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;
  
  ProductProvider(this._getProductsUseCase);
  
  // ...
}
```

**Ejemplos:**

```dart
/// Provider: Gestión de estado del catálogo de productos
///
/// **Responsabilidad:**
/// - Coordinar UI con casos de uso de productos
/// - Gestionar estado de productos y categorías
/// - Manejar estados de carga y errores
///
/// **Dependencias:** GetProductsUseCase, UpdateProductUseCase
/// **Inyección DI:** @injectable
@injectable
class CatalogueProvider extends ChangeNotifier { }

/// UseCase: Obtener lista de productos del catálogo
///
/// **Responsabilidad:**
/// - Obtener productos desde el repositorio
/// - Aplicar filtros y ordenamiento
///
/// **Dependencias:** CatalogueRepository
/// **Inyección DI:** @lazySingleton
@lazySingleton
class GetProductsUseCase { }

/// Entity: Producto del catálogo
///
/// **Propiedades:** id, name, price, stock, category
/// **Inmutable:** Usar copyWith() para modificaciones
class Product {
  final String id;
  final String name;
  final double price;
  // ...
}
```

### 2. Métodos/Funciones

**Documentar solo si:**
- Lógica compleja o no obvia
- Múltiples pasos o transformaciones
- Side effects importantes
- Parámetros no autoexplicativos

```dart
/// Obtiene productos filtrados por categoría y ordenados por precio
///
/// **Parámetros:**
/// - `categoryId`: ID de la categoría (null = todas)
/// - `ascending`: true para orden ascendente
///
/// **Retorna:** Lista de productos ordenados
///
/// **Lanza:** FirestoreException si falla la consulta
Future<List<Product>> getProducts({
  String? categoryId,
  bool ascending = true,
}) async {
  // ...
}
```

**No documentar métodos obvios:**

```dart
// ❌ NO hacer esto
/// Obtiene el ID del producto
String get id => _id;

// ❌ NO hacer esto
/// Retorna el nombre
String getName() => _name;

// ✅ Estos son autoexplicativos
String get id => _id;
String getName() => _name;
```

### 3. Variables/Propiedades

**Documentar solo si:**
- Representa estado complejo
- Tiene propósito no obvio
- Tiene restricciones o validaciones

```dart
/// Lista de productos filtrados actualmente visibles en UI
/// Se actualiza cuando cambia el filtro o se recargan datos
List<Product> _filteredProducts = [];

/// Timestamp de última sincronización con Firestore
/// Usado para sincronización incremental
DateTime? _lastSync;

/// Flag que indica si hay operación en progreso
/// Previene múltiples peticiones simultáneas
bool _isLoading = false;
```

**No documentar variables obvias:**

```dart
// ❌ NO hacer esto
/// Email del usuario
String email;

/// Cantidad de productos
int productCount;

// ✅ Son autoexplicativas
String email;
int productCount;
```

### 4. Entidades de Dominio

```dart
/// Entity: [Nombre]
///
/// [Descripción breve de qué representa]
///
/// **Propiedades:**
/// - `prop1`: Descripción si no es obvia
/// - `prop2`: Descripción si no es obvia
///
/// **Inmutable:** Usar copyWith() para modificaciones
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String categoryId;
  
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
  });
  
  Product copyWith({String? name, double? price, int? stock}) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId,
    );
  }
}
```

### 5. Modelos (DTOs)

```dart
/// Model: DTO para [Entity]
///
/// **Conversión:**
/// - fromJson() / toJson() para API REST
/// - fromFirestore() / toFirestore() para Firestore
/// - toEntity() para conversión a entidad de dominio
class ProductModel {
  final String id;
  final String name;
  // ...
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      // ...
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ...
    };
  }
  
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'],
      // ...
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      // ...
    };
  }
  
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      // ...
    );
  }
}
```

### 6. Repositorios

```dart
/// Repository Contract: [Nombre]
///
/// **Operaciones:**
/// - Método1: Descripción breve
/// - Método2: Descripción breve
abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<void> updateProduct(Product product);
}

/// Repository Implementation: [Nombre]
///
/// **Fuente de datos:** Firestore colección 'products'
/// **Dependencias:** ProductDataSource
/// **Inyección DI:** @LazySingleton(as: ProductRepository)
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  
  ProductRepositoryImpl(this._dataSource);
  
  @override
  Future<List<Product>> getProducts() async {
    final models = await _dataSource.getProducts();
    return models.map((m) => m.toEntity()).toList();
  }
  // ...
}
```

### 7. README.md de Features

**Estructura estándar:**

```markdown
# Feature: [Nombre] [Emoji]

**[Descripción breve en una línea]**

## 🎯 Descripción

[2-3 párrafos explicando qué hace el feature]

## 📦 Componentes Principales

### Entities
- `Entity1`: Descripción
- `Entity2`: Descripción

### Use Cases
- `UseCase1`: Responsabilidad
- `UseCase2`: Responsabilidad

### Providers
- `Provider1`: Responsabilidad

## 🔄 Flujos Principales

### Flujo 1: [Nombre]
```
Usuario → Acción → Provider → UseCase → Repository → Firestore
```

## 🔌 Integración

```dart
// Ejemplo de uso básico
Consumer<MyProvider>(
  builder: (context, provider, _) {
    return MyWidget(data: provider.data);
  },
)
```

## ⚙️ Configuración

[Configuraciones específicas necesarias]

## ✅ Estado

- ✅ Feature completo
- ✅ Tests implementados
- ✅ Documentación completa
```

---

## 🚀 Flujo de Trabajo

### Crear Nuevo Feature Completo

```
1. PLANIFICAR
   ├── Definir alcance y límites
   ├── Identificar entidades principales
   └── Listar casos de uso necesarios

2. DOMAIN FIRST (lógica pura)
   ├── Crear entities/ (clases inmutables)
   ├── Crear repositories/ (contratos abstract)
   └── Crear usecases/ (@lazySingleton)

3. DATA LAYER (implementación)
   ├── Crear models/ (DTOs con serialización)
   ├── Crear datasources/ (@lazySingleton)
   └── Crear repositories/ implementaciones (@LazySingleton)

4. PRESENTATION (UI)
   ├── Crear providers/ (@injectable)
   ├── Crear pages/ (pantallas)
   └── Crear widgets/ (componentes específicos)

5. DEPENDENCY INJECTION
   ├── Verificar anotaciones @injectable/@lazySingleton
   └── Ejecutar: dart run build_runner build --delete-conflicting-outputs

6. INTEGRACIÓN
   ├── Registrar provider en main.dart
   ├── Agregar rutas si necesario
   └── Actualizar navigation

7. TESTING
   ├── Tests unitarios para usecases
   ├── Tests para providers
   └── Widget tests para UI crítica

8. DOCUMENTACIÓN
   ├── Crear README.md del feature
   ├── Documentar clases con patrón minimalista
   └── Actualizar INTEGRATION_GUIDE.md si aplica
```

### Crear Componente Individual

```
1. ANALIZAR: ¿Qué necesito?
2. BUSCAR: ¿Ya existe en presentation/widgets/ o en el feature?
3. REUTILIZAR: Usar existente (compartido o del feature)
4. EXTENDER: Solo si necesario, extender componente base
5. CREAR: Como último recurso
   ├── Compartido → presentation/widgets/[categoria]/
   └── Feature → features/[feature]/presentation/widgets/
6. DOCUMENTAR: Agregar doc minimalista si es necesario
7. EXPORTAR: Actualizar archivo .dart de exportaciones
```

---

## 📁 Ubicación de Componentes

### Features Modulares

| Componente | Ubicación | Anotación DI |
|-----------|-----------|--------------|
| Entity | `features/[f]/domain/entities/` | - |
| Repository (contract) | `features/[f]/domain/repositories/` | - |
| UseCase | `features/[f]/domain/usecases/` | `@lazySingleton` |
| Model (DTO) | `features/[f]/data/models/` | - |
| DataSource | `features/[f]/data/datasources/` | `@lazySingleton` |
| Repository (impl) | `features/[f]/data/repositories/` | `@LazySingleton(as: Contract)` |
| Provider | `features/[f]/presentation/providers/` | `@injectable` |
| Page | `features/[f]/presentation/pages/` | - |
| Widget específico | `features/[f]/presentation/widgets/` | - |

### Componentes Compartidos

| Componente | Ubicación | Cuándo Usar |
|-----------|-----------|-------------|
| Botón | `presentation/widgets/buttons/` | Reutilizable en múltiples features |
| Input | `presentation/widgets/inputs/` | Campo de entrada genérico |
| Diálogo | `presentation/widgets/dialogs/[tipo]/` | Modal compartido |
| Card/Avatar | `presentation/widgets/component/` | Componente básico UI |
| Feedback | `presentation/widgets/feedback/` | Loading/Error states |
| Servicio | `core/services/[categoria]/` | Lógica compartida cross-cutting |
| Utilidad | `core/utils/[categoria]/` | Helpers y formatters |

---

## 🎨 Widgets Disponibles

### Botones (`presentation/widgets/buttons/`)
- `AppButton`: Botón principal con estilos Material 3
- `AppTextButton`: Botón de texto sin fondo
- `AppFloatingActionButton`: FAB customizado
- `AppBarButton`: Botón para AppBar/ToolBar
- `SearchButton`: Botón especializado de búsqueda
- `ThemeControlButtons`: Toggle tema claro/oscuro

### Inputs (`presentation/widgets/inputs/`)
- `InputTextField`: Campo de texto base con validación
- `MoneyInputTextField`: Input especializado para moneda
- `ProductSearchField`: Búsqueda de productos con autocompletado

### Componentes (`presentation/widgets/component/`)
- `UserAvatar`: Avatar de usuario con imagen/iniciales
- `AvatarProduct`: Avatar de producto con placeholder
- `ImageWidget`: Imagen con loading y error handling
- `ProgressIndicators`: Indicadores de progreso customizados
- `Dividers`: Separadores visuales

### Diálogos (`presentation/widgets/dialogs/`)
- Sistema completo modular con `BaseDialog`
- Subcategorías: catalogue, sales, tickets, configuration, feedback

---

## 💡 Mejores Prácticas

### Arquitectura
1. ✅ **Feature-First**: Crear features autónomos completos
2. ✅ **Clean Layers**: Respetar domain → data → presentation
3. ✅ **DI Annotations**: Usar `@injectable` y `@lazySingleton`
4. ✅ **Build Runner**: Regenerar después de añadir anotaciones
5. ✅ **Testing**: Test por cada usecase crítico

### UI/UX
6. ✅ **Reutilizar**: Buscar en `presentation/widgets/` primero
7. ✅ **Material 3**: Usar tema y componentes del sistema
8. ✅ **Responsive**: Considerar mobile/tablet/desktop
9. ✅ **Provider**: Consumer para UI, read() para acciones
10. ✅ **Feature Widgets**: Componentes específicos en el feature

### Código
11. ✅ **Clean Imports**: Dart → Flutter → Packages → Local
12. ✅ **Relative/Absolute**: Relativo en feature, absoluto cross-cutting
13. ✅ **No Circular**: Features no importan otros features
14. ✅ **Doc Minimalista**: Solo lo necesario para contexto
15. ✅ **README.md**: Documentar cada feature con estructura estándar

---

## 📚 Resumen Rápido

### ⚡ Checklist de Creación

**¿Qué voy a crear?**
- [ ] Feature completo → `lib/features/[name]/` con Clean Architecture
- [ ] Widget compartido → `lib/presentation/widgets/[categoria]/`
- [ ] Widget específico → `lib/features/[f]/presentation/widgets/`
- [ ] Servicio → `lib/core/services/[categoria]/`
- [ ] Utilidad → `lib/core/utils/[categoria]/`

**Antes de crear:**
- [ ] ¿Existe componente similar en `presentation/widgets/`?
- [ ] ¿Existe en el feature actual?
- [ ] ¿Puedo extender uno existente?

**Al crear:**
- [ ] Usar anotaciones DI (`@injectable`, `@lazySingleton`)
- [ ] Documentar con patrón minimalista
- [ ] Imports relativos dentro del feature
- [ ] Imports absolutos para cross-cutting

**Después de crear:**
- [ ] Ejecutar `build_runner` si añadiste DI
- [ ] Exportar en archivo `.dart` si es compartido
- [ ] Actualizar README.md del feature
- [ ] Agregar tests si es lógica crítica

---

## 🔥 Comandos Útiles

```bash
# Regenerar código de Dependency Injection
dart run build_runner build --delete-conflicting-outputs

# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Build para web
flutter build web --release

# Analizar código
flutter analyze

# Format código
dart format .
```

---

**Última actualización:** 25 de noviembre de 2025  
**Versión:** 2.0.0  
**Estado:** ✅ Producción
````
