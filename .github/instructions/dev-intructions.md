# Instructions - Flutter Web Sell App

## 🏗️ Arquitectura del Proyecto

Este es un **portal de ventas web** construido con **Flutter Web** que implementa **Clean Architecture** estricta con **Provider** para gestión de estado.

### Stack Tecnológico
- **Framework**: Flutter Web
- **Arquitectura**: Clean Architecture + Provider
- **Base de datos**: Firebase Firestore
- **Autenticación**: Firebase Auth + Google Sign-In
- **Tema**: Material Design 3 con soporte claro/oscuro

## 📱 Patrones de Provider

### Provider Hierarchy en main.dart
```dart
MultiProvider(
  providers: [
    // Globales
    ChangeNotifierProvider(create: (_) => ThemeDataAppProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider(...)),
    
    // Por cuenta (se crean dinámicamente)
    ChangeNotifierProvider(create: (_) => CatalogueProvider(...)),
    ChangeNotifierProvider(create: (_) => CashRegisterProvider(...)),
    
  ],
)
```

### Manejo de Estado Eficiente
- **Consumer granular**: Usar Consumer específicos en lugar de Consumer generales
- **Selector widgets**: Implementar Selector para rebuilds optimizados
- **Provider.of(listen: false)**: Para acciones que no requieren rebuild
- **MultiProvider**: Organizar providers de manera jerárquica
- Implementar `copyWith()` en clases de estado
- Persistir estado crítico con `SharedPreferences`

### Estructura proyect
```
lib/
├── core/                           # Widgets reutilizables, servicios y utilidades
│   ├── services/                   # Servicios compartidos de la aplicación
│   │   ├── cash_register_persistence_service.dart
│   │   ├── database_cloud.dart
│   │   ├── theme_service.dart
│   │   └── thermal_printer_http_service.dart
│   ├── utils/                      # Utilidades y helpers generales
│   │   ├── fuctions.dart
│   │   ├── responsive.dart
│   │   └── shared_prefs_keys.dart
│   └── widgets/                    # Componentes UI reutilizables
│       ├── buttons/                # Botones especializados
│       │   ├── app_bar_button.dart
│       │   ├── app_button.dart
│       │   ├── app_floating_action_button.dart
│       │   ├── buttons.dart
│       │   └── search_button.dart
│       ├── dialogs/                # Diálogos modales especializados
│       │   ├── base/               # Componentes base para diálogos
│       │   ├── catalogue/          # Diálogos específicos del catálogo
│       │   ├── components/         # Componentes reutilizables de diálogos
│       │   ├── configuration/      # Diálogos de configuración
│       │   ├── examples/           # Ejemplos y plantillas
│       │   ├── legacy/             # Diálogos legacy (deprecados)
│       │   ├── sales/              # Diálogos relacionados con ventas
│       │   ├── tickets/            # Diálogos de tickets y recibos
│       │   └── dialogs.dart
│       ├── drawer/                 # Componentes de navegación lateral
│       ├── feedback/               # Widgets de feedback (loading, error, etc.)
│       ├── inputs/                 # Campos de entrada especializados
│       │   ├── input_text_field.dart
│       │   ├── inputs.dart
│       │   └── money_input_text_field.dart
│       ├── media/                  # Widgets para manejo de media
│       ├── responsive/             # Componentes responsive
│       ├── ui/                     # Componentes básicos de UI
│       │   ├── dividers.dart
│       │   ├── image_widget.dart
│       │   ├── progress_indicators.dart
│       │   ├── ui.dart
│       │   └── user_avatar.dart
│       └── core_widgets.dart
│
├── data/                           # Implementaciones de repositorios (Firebase)
│   ├── account_repository_impl.dart    # Implementación repositorio de cuentas
│   ├── auth_repository_impl.dart       # Implementación repositorio de autenticación
│   ├── cash_register_repository_impl.dart # Implementación repositorio de cajas
│   └── catalogue_repository_impl.dart  # Implementación repositorio de catálogo
│
├── domain/                         # Entidades, repositorios abstractos y casos de uso
│   ├── entities/                   # Modelos de dominio
│   │   ├── cash_register_model.dart    # Modelo de caja registradora
│   │   ├── catalogue.dart              # Modelo de catálogo y productos
│   │   ├── ticket_model.dart           # Modelo de ticket de venta
│   │   └── user.dart                   # Modelo de usuario
│   ├── repositories/               # Contratos de repositorios
│   │   ├── account_repository.dart     # Contrato repositorio de cuentas
│   │   ├── auth_repository.dart        # Contrato repositorio de autenticación
│   │   ├── cash_register_repository.dart # Contrato repositorio de cajas
│   │   └── catalogue_repository.dart   # Contrato repositorio de catálogo
│   └── usecases/                   # Casos de uso de negocio
│       ├── account_usecase.dart        # Casos de uso de cuentas
│       ├── auth_usecases.dart          # Casos de uso de autenticación
│       ├── cash_register_usecases.dart # Casos de uso de cajas registradoras
│       ├── catalogue_usecases.dart     # Casos de uso de catálogo
│       └── sell_usecases.dart          # Casos de uso de ventas
│
├── presentation/                   # UI, páginas y providers
│   ├── dialogs/                    # Diálogos específicos de páginas
│   │   └── cash_register_management_dialog.dart
│   ├── pages/                      # Páginas de la aplicación
│   │   ├── login_page.dart             # Página de inicio de sesión
│   │   ├── sell_page.dart              # Página principal de ventas
│   │   └── welcome_page.dart           # Página de bienvenida
│   └── providers/                  # Providers para gestión de estado
│       ├── auth_provider.dart          # Provider de autenticación
│       ├── cash_register_provider.dart # Provider de cajas registradoras
│       ├── catalogue_provider.dart     # Provider de catálogo
│       ├── printer_provider.dart       # Provider de impresión
│       ├── sell_provider.dart          # Provider de ventas
│       └── theme_data_app_provider.dart # Provider de tema
│
└── main.dart                       # Punto de entrada de la aplicación
```
**IMPORTANTE**: (Evitar duplicación de código) Usar siempre los componentes y funciones de `core/` en lugar de crear nuevos y si no existe crearlo y actualizar la [Estructura proyect] de [dev-instructions.md]

## � Business Logic Key

### Account Selection Flow
1. Usuario se autentica → `AuthProvider`
2. Se cargan cuentas asociadas → `GetUserAccountsUseCase`
3. Usuario selecciona cuenta → `SellProvider.initAccount()`
4. Se inicializa catálogo y caja → `CatalogueProvider` + `CashRegisterProvider`

### Ticket/Sale Flow
1. Productos se agregan al ticket → `SellProvider.addProductsticket()`
2. Se configura método de pago → `setPayMode()`
3. Se selecciona caja registradora → `CashRegisterProvider.selectCashRegister()`
4. Se confirma venta → genera transacción en Firestore

### Demo Mode
Para usuarios anónimos existe un modo demo con productos predefinidos:
```dart
if (account.id == 'demo' && authProvider.user?.isAnonymous == true) {
  catalogueProvider.loadDemoProducts(demoProducts);
}
```

## 🔧 Key Development Patterns

### Entity Constructors
Las entidades usan múltiples constructores para diferentes fuentes de datos:
```dart
ProductCatalogue.fromMap(Map data)        // Para datos locales
ProductCatalogue.fromDocument(DocumentSnapshot) // Para Firestore
ProductCatalogue.mapRefactoring(Map data) // Para migración de datos legacy
```

### Provider Initialization
Los providers que dependen de cuentas se inicializan después de la selección:
```dart
void initCatalogue(String accountId) {
  if (accountId.isEmpty) return;
  _getProductsStreamUseCase.call(accountId).listen(/*...*/);
}
```

### Responsive Design
Usar `ResponsiveBreakpoints.dart`. (lib/core/utils) 
```dart 
// Layout adaptativo
Widget buildResponsiveLayout(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < Breakpoints.mobile) {
        return const MobileLayout();
      } else if (constraints.maxWidth < Breakpoints.tablet) {
        return const TabletLayout();
      } else {
        return const DesktopLayout();
      }
    },
  );
}
```

## ⚡ Performance y Optimización

### Optimización de Widgets
```dart
// ✅ Usar const constructors cuando sea posible
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
  });
  
  final Product product;
  
  @override
  Widget build(BuildContext context) {
    return const Card(
      // Widget inmutable optimizado
    );
  }
}

// ✅ Implementar shouldRebuild en Providers
class CatalogueProvider extends ChangeNotifier {
  @override
  bool shouldRebuild(covariant CatalogueProvider oldWidget) {
    return products != oldWidget.products;
  }
}
```

### Lazy Loading y Paginación
```dart
// Implementar paginación en listas grandes
class PaginatedProductList extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          // Trigger para cargar más elementos
          _loadMoreProducts();
          return const CircularProgressIndicator();
        }
        return ProductTile(product: products[index]);
      },
    );
  }
}
```

## 🔧 Debugging y Herramientas

### Estrategias de Debug
```dart
// Logging estructurado para debugging
import 'package:flutter/foundation.dart';

void debugLog(String message, {String? tag}) {
  if (kDebugMode) {
    print('------------debug---------------- [${tag ?? 'DEBUG'}] ${DateTime.now()}: $message');
  }
}

// Debug específico por capas
class RepositoryLogger {
  static void logApiCall(String endpoint, Map<String, dynamic>? data) {
    debugLog('--------------log--------------- API Call: $endpoint with data: $data', tag: 'REPOSITORY');
  }
}
```

## 📋 Convenciones Específicas

### Nomenclatura
- **Idioma**: Inglés para nombres de archivos, carpetas, clases, métodos, variables etc y Espańol para comentarios y documentación.
- **Archivos**: `snake_case.dart`
- **Clases**: `PascalCase`
- **Variables**: `camelCase`
- **Constantes**: `UPPER_SNAKE_CASE`
- **Consistencia**: Mantener coherencia en todo el proyecto

### Documentación y Comentarios
- **Funciones**: Documentar solo funciones complejas o no autoexplicativas (1-2 líneas máximo)
- **Idioma**: Comentarios y documentación en español
- **Comentarios**: Explicar secciones complejas o no evidentes
- **Evitar**: Comentarios redundantes o innecesarios

## 🤖 Desarrollo Asistido por IA (Copilot)

### Mejores Prácticas con IA
- **Código descriptivo**: Escribir nombres de funciones y variables descriptivos para que la IA comprenda mejor el contexto
- **Comentarios estratégicos**: Usar comentarios antes de funciones complejas para guiar la IA
- **Patrones consistentes**: Mantener patrones de código consistentes para mejorar las sugerencias
- **Contexto claro**: Crear o actualizar cada vez se agregue una novedad si es necesario un README.md (para facilitar contexto a la agent IA) que va a contener una explicación breve de cada archivo (contexto, propósito y uso) de cada archivo de dicha carpeta que pertenece

### Optimización para Sugerencias IA
```dart
// ✅ Buena práctica - Nombres descriptivos
Future<List<Product>> fetchActiveProductsFromCatalogue() async {
  // Obtener productos activos del catálogo con filtros aplicados
  return await catalogueRepository.getActiveProducts();
}

// ❌ Evitar - Nombres genéricos
Future<List<dynamic>> getData() async {
  return await repo.get();
}
```

### Prompts Efectivos para IA
- Especificar el tipo de widget/componente Flutter deseado
- Mencionar Material 3, Clean Architecture y provider en las solicitudes
- Incluir contexto clave (contexto, propósito, uso, etc.) en (README.md) en cada capa (presentation, domain, data, etc.) de todos los archivos que contengan para mejorar la comprensión de la IA
- Solicitar implementaciones con Provider cuando sea necesario

## 🔒 Seguridad y Manejo de Errores

### Validación de Datos
- Implementar validadores en el domain layer
- Usar freezed para objetos inmutables
- Validar inputs en tiempo real en la UI
- Sanitizar datos antes de enviar a APIs

## �️ Herramientas y Configuración

### Configuración analysis_options.yaml
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    prefer_single_quotes: true
```

## ⚠️ Consideraciones Importantes

1. **Caja Registradora**: Es requerida (opcional) para completar ventas - manejar casos donde no existe
2. **Persistencia**: Cuenta seleccionada,ticket,caja y configuraciones de la app se persiste 
5. **Material 3**: Usar siempre `colorScheme` y `textTheme` del contexto actual

## ✅ Buenas Prácticas Generales
- **Inmutabilidad**: Usar objetos inmutables con freezed cuando sea posible
- **Separation of Concerns**: Cada clase/función tiene una única responsabilidad
- **DRY Principle**: Evitar duplicación de código mediante componentes reutilizables y controlando el exceso de componetes creados
- **KISS Principle**: Mantener soluciones simples y directas
- **Progressive Enhancement**: Construir funcionalidad base primero, luego mejorar
- **Code Review**: Revisar código antes de merge, enfocándose en arquitectura y performance
- **Documentation**: Documentar decisiones arquitectónicas importantes
- **Version Control**: Commits atómicos con mensajes descriptivos en Español

## 🎯 AI Prompt Templates

Al solicitar cambios, incluir contexto:
- "Para [ENTITY] en la capa [LAYER]..."
- "Siguiendo el patrón de [EXISTING_COMPONENT]..."  
- "Manteniendo consistencia con Material 3..."
- "Usando el provider pattern de [EXISTING_PROVIDER]..."
