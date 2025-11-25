# Light Instructions - Flutter Web Sell App

## 🎯 Guía Rápida para Componentes

### 🏛️ Filosofía Arquitectónica: Feature-First + Clean Architecture

**Principios fundamentales:**
1. ✅ **Feature-First**: Cada funcionalidad de negocio es un módulo autónomo en `lib/features/`
2. ✅ **Clean Architecture**: Separación clara entre dominio, datos y presentación
3. ✅ **Dependency Injection**: Uso de `@injectable` y `@lazySingleton` con GetIt
4. ✅ **Imports relativos**: Dentro de un feature usar rutas relativas (`../`, `../../`)
5. ✅ **Imports absolutos**: Para `core/`, shared widgets, y routing
6. ✅ **Widgets compartidos**: En `lib/presentation/widgets/` (cross-feature)
7. ✅ **Widgets específicos**: En `lib/features/[feature]/presentation/widgets/` (feature-only)
8. ❌ **No circular dependencies**: Features NO deben importar otros features

### Estructura del Proyecto

#### 🏗️ Arquitectura Modular (Clean Architecture + Feature-First)

El proyecto implementa una **arquitectura modular por features** siguiendo Clean Architecture:

```
lib/
├── core/                           # Servicios y utilidades compartidas (cross-cutting concerns)
│   ├── config/                     # Configuraciones globales
│   │   ├── app_config.dart
│   │   ├── firebase_options.dart
│   │   └── oauth_config.dart
│   ├── constants/                  # Constantes globales
│   ├── di/                         # ⭐ Dependency Injection
│   │   ├── injection_container.dart      # Configuración GetIt + Injectable
│   │   └── injection_container.config.dart  # Generado por build_runner
│   ├── services/                   # Servicios compartidos entre features
│   │   ├── database/
│   │   ├── external/
│   │   ├── storage/
│   │   ├── search_catalogue_service.dart
│   │   └── theme_service.dart
│   ├── utils/                      # Utilidades compartidas
│   └── core.dart                   # Exportaciones centralizadas
│
├── features/                       # ⭐ FEATURES MODULARES (nuevo enfoque)
│   └── catalogue/                  # Feature: Catálogo de productos
│       ├── data/                   # Capa de datos del feature
│       │   ├── datasources/
│       │   │   └── catalogue_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── product_model.dart
│       │   │   ├── product_catalogue_model.dart
│       │   │   ├── category_model.dart
│       │   │   └── product_price_model.dart
│       │   └── repositories/
│       │       └── catalogue_repository_impl.dart
│       ├── domain/                 # Capa de dominio del feature
│       │   ├── entities/
│       │   │   ├── product.dart
│       │   │   ├── product_catalogue.dart
│       │   │   ├── category.dart
│       │   │   └── product_price.dart
│       │   ├── repositories/
│       │   │   └── catalogue_repository.dart
│       │   └── usecases/
│       │       ├── get_products_usecase.dart
│       │       └── update_stock_usecase.dart
│       ├── presentation/           # Capa de presentación del feature
│       │   ├── pages/
│       │   │   └── catalogue_page.dart
│       │   ├── providers/
│       │   │   └── catalogue_provider.dart (@injectable)
│       │   └── widgets/
│       │       ├── product_catalogue_view.dart
│       │       └── product_edit_catalogue_view.dart
│       ├── README.md               # Documentación del feature
│
├── data/                           # ⚠️ Legacy - Repositorios globales (en migración)
│   ├── account_repository_impl.dart
│   ├── auth_repository_impl.dart
│   └── cash_register_repository_impl.dart
│
├── domain/                         # ⚠️ Legacy - Dominio global (en migración)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/                   # ⚠️ Legacy - UI global (en migración)
    ├── pages/
    ├── providers/
    └── widgets/                    # Componentes UI compartidos (se mantienen)
        ├── buttons/                # Botones especializados
        │   ├── app_bar_button.dart
        │   ├── app_button.dart
        │   ├── app_floating_action_button.dart
        │   ├── app_text_button.dart
        │   ├── search_button.dart
        │   ├── theme_control_buttons.dart
        │   └── buttons.dart        # Exportaciones centralizadas
        ├── component/              # Componentes básicos reutilizables
        │   ├── avatar_product.dart
        │   ├── dividers.dart
        │   ├── image.dart
        │   ├── progress_indicators.dart
        │   ├── responsive_helper.dart
        │   ├── user_avatar.dart
        │   └── ui.dart             # Exportaciones centralizadas
        ├── dialogs/                # Diálogos modales especializados
        │   ├── base/               # Componentes base para diálogos
        │   ├── catalogue/          # Diálogos del catálogo
        │   ├── components/         # Componentes de diálogos
        │   ├── configuration/      # Diálogos de configuración
        │   ├── examples/           # Ejemplos y plantillas
        │   ├── feedback/           # Diálogos de feedback
        │   ├── sales/              # Diálogos de ventas
        │   ├── tickets/            # Diálogos de tickets
        │   └── dialogs.dart        # Exportaciones centralizadas
        ├── feedback/               # Estados de carga y errores
        │   ├── auth_feedback_widget.dart
        │   └── feedback.dart       # Exportaciones centralizadas
        ├── inputs/                 # Campos de entrada especializados
        │   ├── input_text_field.dart
        │   ├── money_input_text_field.dart
        │   ├── product_search_field.dart
        │   └── inputs.dart         # Exportaciones centralizadas
        ├── navigation/             # Componentes de navegación
        │   ├── drawer_ticket/      # Drawer específico de tickets
        │   └── navigation.dart     # Exportaciones centralizadas
        ├── responsive/             # Componentes responsive
        │   ├── responsive_helper.dart
        │   └── README.md
        ├── views/                  # Vistas complejas reutilizables
        │   ├── search_catalogue_full_screen_view.dart
        │   ├── welcome_selected_account_page.dart
        │   └── views.dart          # Exportaciones centralizadas
        └── core_widgets.dart       # Exportaciones centralizadas de widgets
```

## 🏛️ Principios de Arquitectura Modular

### ⭐ Nueva Filosofía: Feature-First + Clean Architecture

#### 🎯 Cuando Crear un Nuevo Feature Modular

Un **feature** es un módulo completo y autónomo. Crear uno nuevo cuando:
- ✅ Es una funcionalidad de negocio completa (ej:Auth, Catálogo, Ventas)
- ✅ Tiene su propio dominio y lógica de negocio
- ✅ Puede evolucionar independientemente
- ✅ Tiene múltiples pantallas/componentes relacionados

#### 📐 Estructura de un Feature Modular

```
lib/features/[feature_name]/
├── data/                    # Implementaciones, datasources, modelos
│   ├── datasources/         # Firebase, API, local storage
│   ├── models/              # DTOs con serialización (@freezed, @JsonSerializable)
│   └── repositories/        # Implementaciones de contratos
├── domain/                  # Lógica de negocio pura (sin dependencias)
│   ├── entities/            # Entidades de dominio (inmutables)
│   ├── repositories/        # Contratos (interfaces)
│   └── usecases/            # Casos de uso (@lazySingleton)
├── presentation/            # UI del feature
│   ├── pages/               # Páginas principales
│   ├── providers/           # Providers (@injectable)
│   └── widgets/             # Widgets específicos del feature
├── README.md                # Documentación del feature
```

#### 🔧 Dependency Injection con Injectable

**Todos los providers y use cases** deben usar anotaciones de `injectable`:

```dart
// Provider
@injectable
class CatalogueProvider extends ChangeNotifier {
  final CatalogueUseCases catalogueUseCases;
  
  CatalogueProvider({required this.catalogueUseCases});
  // ...
}

// Use Case
@lazySingleton
class GetProductsUseCase {
  final CatalogueRepository repository;
  
  GetProductsUseCase(this.repository);
  // ...
}

// DataSource
@LazySingleton(as: CatalogueRemoteDataSource)
class CatalogueRemoteDataSourceImpl implements CatalogueRemoteDataSource {
  // ...
}
```

**Configuración en `main.dart`:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  configureDependencies(); // ⭐ Inicializar DI antes de runApp
  
  runApp(MyApp());
}
```

**Después de añadir anotaciones, ejecutar:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 📦 Imports en Features Modulares

**REGLAS de imports:**
1. ✅ Features pueden importar desde `core/`
2. ✅ Features pueden importar widgets compartidos de `presentation/widgets/`
3. ❌ Features NO deben importar otros features directamente
4. ❌ `core/` NO debe importar features
5. ✅ Usar rutas relativas dentro del feature: `../`, `../../`
6. ✅ Usar absolute imports para `core/` y shared: `package:sellweb/core/...`

**Ejemplos correctos:**
```dart
// Dentro del feature catalogue
import '../providers/catalogue_provider.dart';              // ✅ Relativo dentro del feature
import '../../../../core/core.dart';                        // ✅ Core compartido
import '../../../../presentation/widgets/buttons/app_button.dart'; // ✅ Widget compartido

// En main.dart
import 'features/catalogue/presentation/providers/catalogue_provider.dart'; // ✅
import 'features/catalogue/presentation/pages/catalogue_page.dart';        // ✅
```

## 📏 Buenas Prácticas  ⚡ Reglas Rápidas

### 🚨 REGLA DE ORO: REUTILIZAR ANTES DE CREAR
**ANTES** de crear cualquier componente nuevo:
1. ✅ **Revisa** `presentation/widgets/` y sus subcarpetas (widgets compartidos)
2. ✅ **Verifica** si existe en el feature actual: `features/[feature]/presentation/widgets/`
3. ✅ **Consulta** `core_widgets.dart` para todos los widgets disponibles
4. ✅ **Busca** en `core/services/` para servicios, métodos, etc. existentes

### 📋 Checklist Obligatorio

#### Para Componentes UI:
- [ ] ¿Existe un botón similar en `presentation/widgets/buttons/`? → Usar `AppButton`, `AppTextButton`, etc.
- [ ] ¿Necesitas un input? → Usar `InputTextField`, `MoneyInputTextField`, etc.
- [ ] ¿Requieres un diálogo? → Revisar `presentation/widgets/dialogs/base/` y subcarpetas
- [ ] ¿Es un componente básico? → Verificar `presentation/widgets/component/` (avatars, imágenes, etc.)
- [ ] ¿Necesitas feedback? → Usar widgets de `presentation/widgets/feedback/`
- [ ] ¿Es responsive? → Usar `core/utils/helpers/responsive_helper.dart`
- [ ] ¿Es específico del feature? → Crear en `features/[feature]/presentation/widgets/`

#### Para Lógica de Negocio:
- [ ] ¿Es lógica específica de un feature? → Crear en `features/[feature]/domain/usecases/`
- [ ] ¿Es un servicio compartido? → Crear/usar en `core/services/`
- [ ] ¿Necesitas acceso a datos? → Crear datasource en `features/[feature]/data/datasources/`
- [ ] ¿Es una entidad de dominio? → Crear en `features/[feature]/domain/entities/`
- [ ] ¿Usas Provider para estado? → Anotar con `@injectable` y registrar en DI

### 🎯 Flujo de Trabajo

#### Para Crear un Nuevo Feature Completo:
```
1. PLANIFICAR → Definir alcance, entidades, casos de uso
2. CREAR ESTRUCTURA → Carpetas data/, domain/, presentation/
3. DOMAIN FIRST → Entidades → Repositorios (contratos) → UseCases
4. DATA LAYER → Models → DataSources → Repository Implementations
5. PRESENTATION → Provider (@injectable) → Pages → Widgets
6. DEPENDENCY INJECTION → Anotar con @injectable/@lazySingleton
7. BUILD RUNNER → Ejecutar build_runner para generar código DI
8. TESTING → Crear tests unitarios en test/features/[feature]/
9. INTEGRAR → Actualizar main.dart con imports del nuevo feature
10. DOCUMENTAR → README.md, INTEGRATION_GUIDE.md, MIGRATION_SUMMARY.md
```

#### Para Crear Componentes Individuales:
```
1. ANALIZAR → ¿Qué necesito crear? ¿Es específico o compartido?
2. BUSCAR → ¿Ya existe algo similar en widgets compartidos o en el feature?
3. REUTILIZAR → Usar componente existente (compartido o del feature)
4. EXTENDER → Solo si es necesario, extender el existente
5. CREAR → Como último recurso:
   - Compartido → presentation/widgets/[categoria]/
   - Feature → features/[feature]/presentation/widgets/
6. EXPORTAR → Agregar a archivo .dart correspondiente si es compartido
7. DOCUMENTAR → Actualizar README.md si es significativo
```

### 💡 Reglas Adicionales

#### Arquitectura:
1. **Feature-First**: Features autónomos en `features/[feature]/`
2. **Clean Architecture**: Separación clara domain → data → presentation
3. **Dependency Injection**: Usar `@injectable` y `@lazySingleton`
4. **Build Runner**: Ejecutar después de añadir anotaciones DI
5. **Testing**: Test por cada use case y provider en `test/features/[feature]/`

#### UI/UX:
6. **Responsive first**: Considerar mobile, tablet, desktop SIEMPRE
7. **Material Design 3**: Usar componentes y colores del tema
8. **Provider pattern**: Consumer para UI, Provider.of para acciones
9. **Widgets compartidos**: Reutilizar desde `presentation/widgets/`
10. **Widgets específicos**: Crear en `features/[feature]/presentation/widgets/`

#### Código:
11. **Clean imports**: Agrupar (dart, flutter, packages, local)
12. **Imports relativos**: Dentro del feature usar `../`, `../../`
13. **Imports absolutos**: Para core y shared usar `package:sellweb/`
14. **No circular imports**: Features no importan otros features
15. **Documentar**: Actualizar README.md en cada carpeta modificada

## 📁 Dónde Crear Qué

### 🆕 Features Modulares (Nuevo Enfoque - PRIORIDAD)

| Qué Crear | Ubicación | Ejemplo | Anotación DI |
|-----------|-----------|---------|--------------|
| **Feature completo** | `features/[feature_name]/` | `features/catalogue/`, `features/inventory/` | - |
| **Entidad de dominio** | `features/[feature]/domain/entities/` | `product.dart`, `category.dart` | - |
| **Repositorio (contrato)** | `features/[feature]/domain/repositories/` | `catalogue_repository.dart` | - |
| **Caso de uso** | `features/[feature]/domain/usecases/` | `get_products_usecase.dart` | `@lazySingleton` |
| **Modelo DTO** | `features/[feature]/data/models/` | `product_model.dart` | - |
| **DataSource** | `features/[feature]/data/datasources/` | `catalogue_remote_datasource.dart` | `@LazySingleton` |
| **Repositorio (impl)** | `features/[feature]/data/repositories/` | `catalogue_repository_impl.dart` | `@LazySingleton` |
| **Provider del feature** | `features/[feature]/presentation/providers/` | `catalogue_provider.dart` | `@injectable` |
| **Página del feature** | `features/[feature]/presentation/pages/` | `catalogue_page.dart` | - |
| **Widget específico** | `features/[feature]/presentation/widgets/` | `product_card.dart`, `product_form.dart` | - |
| **Test del feature** | `test/features/[feature]/` | Misma estructura que lib | - |

### 📝 README (obligatorio): archivo de documentación para cada carpeta
Actualizar o crear en cada carpeta debe contener un archivo README.md con formato estándar:
- **Descripción**: Propósito de la carpeta
- **Contenido**: Lista en árbol con descripción de cada archivo
- **Documentación extensa**: Solo si es necesario explicar implementaciones complejas

Para features modulares, incluir además:
- `INTEGRATION_GUIDE.md`: Cómo integrar el feature en la app
- `MIGRATION_SUMMARY.md`: Estado de migración (si aplica)

### 🔍 PRIMERO: Componentes Globales Existentes (en `lib/presentation/widgets/`)

| Tipo | Componentes Disponibles | Ubicación | Importación |
|------|------------------------|-----------|-------------|
| **Botones** | `AppButton`, `AppTextButton`, `AppFloatingActionButton`, `AppBarButton`, `SearchButton`, `ThemeControlButtons` | `buttons/` | `'package:sell_web/core/core.dart'` o directa |
| **Inputs** | `InputTextField`, `MoneyInputTextField`, `ProductSearchField` | `inputs/` | `'package:sell_web/core/core.dart'` o directa |
| **Componentes básicos** | `UserAvatar`, `AvatarProduct`, `ImageWidget`, `ProgressIndicators`, `Dividers` | `component/` | `'package:sell_web/core/core.dart'` o directa |
| **Feedback** | `AuthFeedbackWidget` + widgets de feedback general | `feedback/` | Importación directa |
| **Responsive** | `responsive_helper` | `helpers/` | `'package:sell_web/core/utils/utils.dart'` |
| **Navegación** | `AppDrawer`, navigation helpers | `navigation/` | `'package:sell_web/core/core.dart'` |
| **Vistas** | `SearchCatalogueFullScreenView`, `WelcomeSelectedAccountPage` | `views/` | Importación directa |
| **Diálogos** | Sistema completo con base, catalogue, sales, tickets, etc. | `dialogs/` | Importación directa |

### 🎯 Widgets Específicos de Features (en `lib/features/[feature]/presentation/widgets/`)

| Feature | Widgets Disponibles | Ubicación | Cuándo Usar | Importación |
|---------|---------------------|-----------|-------------|-------------|
| **Catalogue** | `ProductCard`, `ProductForm`, `CatalogueView`, `ProductEditCatalogueView` | `features/catalogue/presentation/widgets/` | Solo dentro del feature Catalogue | **Relativa** dentro del feature: `'../widgets/...'` |

**⚠️ Regla de oro para widgets de features:**
- ✅ Usar importación **relativa** dentro del mismo feature (`../widgets/`, `../../`)
- ❌ NO importar widgets de otros features
- ✅ Si necesitas un widget en múltiples features → moverlo a `lib/presentation/widgets/` y cambiar a import absoluto

### 🆕 Solo Si NO Existe: Crear Nuevo

#### Componentes Globales/Compartidos (reutilizables entre features)

| Tipo de Componente | Ubicación | Ejemplo | Exportar en | Importación |
|-------------------|-----------|---------|-------------|-------------|
| Botón especializado compartido | `presentation/widgets/buttons/` | `AddToCartButton` | `buttons.dart` | Absoluta |
| Campo de entrada genérico | `presentation/widgets/inputs/` | `CategoryInput` | `inputs.dart` | Absoluta |
| Diálogo nuevo dominio | `presentation/widgets/dialogs/[dominio]/` | `InventoryDialog` | `dialogs.dart` | Absoluta |
| Card/Lista genérica | `presentation/widgets/component/` | `GenericCard` | `ui.dart` | Absoluta |
| Feedback especializado | `presentation/widgets/feedback/` | `SalesFeedback` | `feedback.dart` | Absoluta |
| Vista compleja compartida | `presentation/widgets/views/` | `DashboardView` | `views.dart` | Absoluta |
| Servicio global | `core/services/[categoria]/` | `NotificationService` | `core.dart` | Absoluta |
| Utilidad específica | `core/utils/[categoria]/` | `CurrencyFormatter` | Crear exportador | Absoluta |

#### Componentes Específicos de Feature (solo para un feature)

| Tipo de Componente | Ubicación | Ejemplo | Exportar en | Importación |
|-------------------|-----------|---------|-------------|-------------|
| Widget específico del feature | `features/[feature]/presentation/widgets/` | `ProductCard` (sólo Catalogue) | No exportar globalmente | **Relativa** dentro del feature |
| Provider del feature | `features/[feature]/presentation/providers/` | `CatalogueProvider` | No exportar globalmente | Absoluta para main.dart, relativa internamente |
| Página del feature | `features/[feature]/presentation/pages/` | `CataloguePage` | No exportar globalmente | Absoluta para routing |

### ⚠️ IMPORTANTE: Proceso de Creación
1. **Verificar** que NO existe componente similar
2. **Crear** en la ubicación apropiada
3. **Exportar** en el archivo `.dart` correspondiente de la carpeta
4. **Documentar** en README.md si es significativo
5. **Actualizar** `core_widgets.dart` si es widget reutilizable

---

## 🎯 Ejemplos de Uso de Componentes Existentes

### Usar Botones Globales Compartidos
```dart
// ✅ CORRECTO - Usar botones existentes en cualquier parte de la app
import 'package:sell_web/core/core.dart';

AppButton(
  onPressed: () => _handleAction(),
  text: 'Agregar al Carrito',
  icon: Icons.add_shopping_cart,
)

// ❌ INCORRECTO - Crear botón desde cero
ElevatedButton(...)
```

### Usar Inputs Globales Compartidos
```dart
// ✅ CORRECTO - Usar input especializado compartido
import 'package:sell_web/core/core.dart';

MoneyInputTextField(
  controller: _priceController,
  label: 'Precio',
  onChanged: (value) => _updatePrice(value),
)

// ❌ INCORRECTO - Crear input genérico
TextFormField(...)
```

### Usar Diálogos Existentes
```dart
// ✅ CORRECTO - Reutilizar sistema de diálogos
import 'package:sell_web/presentation/widgets/dialogs/dialogs.dart';

showDialog(
  context: context,
  builder: (context) => BaseDialog(
    title: 'Confirmar Acción',
    content: Text('¿Estás seguro?'),
    actions: [/* usar botones existentes */],
  ),
)
```

### Usar Widgets Específicos de un Feature
```dart
// ✅ CORRECTO - Importación relativa dentro del mismo feature
// Archivo: lib/features/catalogue/presentation/pages/catalogue_page.dart
import '../widgets/product_card.dart';           // Widget específico del feature
import '../providers/catalogue_provider.dart';   // Provider del feature

class CataloguePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, provider, _) {
        return GridView.builder(
          itemBuilder: (context, index) => ProductCard(
            product: provider.products[index],
          ),
        );
      },
    );
  }
}

// ❌ INCORRECTO - NO importar widgets de otros features
import 'package:sell_web/features/inventory/presentation/widgets/inventory_card.dart'; // ❌
```

### Integrar Feature en Main.dart
```dart
// ✅ CORRECTO - Importación absoluta para providers y páginas de features
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'features/catalogue/presentation/pages/catalogue_page.dart';

// En el MultiProvider:
providers: [
  ChangeNotifierProvider(create: (_) => CatalogueProvider(...)),
],
```

---

## 📚 Resumen de Mejores Prácticas

### 🏛️ Arquitectura
1. ✅ **Feature-First**: Crear módulos completos en `lib/features/[feature]/`
2. ✅ **Clean Architecture**: Respetar capas domain/data/presentation
3. ✅ **DI con @injectable**: Usar anotaciones para casos de uso y repositorios
4. ✅ **Imports relativos**: Dentro de features usar `../`, `../../`
5. ✅ **Imports absolutos**: Para core, shared widgets, y routing

### 🎨 UI/UX
6. ✅ **Reutilizar componentes**: Revisar `lib/presentation/widgets/` antes de crear
7. ✅ **Material Design 3**: Seguir guías de diseño consistentes
8. ✅ **Responsive Design**: Usar `responsive_helper.dart` para adaptabilidad
9. ✅ **Widgets compartidos**: En `lib/presentation/widgets/` si se usan en múltiples features
10. ✅ **Widgets específicos**: En `lib/features/[feature]/presentation/widgets/` si son exclusivos

### 💻 Código
11. ✅ **Provider para estado**: Usar ChangeNotifierProvider con @injectable
12. ✅ **Tests unitarios**: Crear tests para providers y casos de uso
13. ✅ **Build runner**: Ejecutar después de añadir @injectable/@lazySingleton
14. ✅ **README.md**: Documentar cada carpeta con formato estándar
15. ✅ **No circular deps**: Features NO deben importar otros features

---
**🔥 Recuerda**: 
- **Feature-First + Clean Architecture** es la base del proyecto
- **Provider** para gestión de estado global
- **Reutilizar SIEMPRE** antes de crear
- **Material Design 3** para consistencia visual
- **Responsive Design** en todos los componentes
- **DI con @injectable** para desacoplar dependencias
- **Imports relativos** dentro de features, **absolutos** para shared
