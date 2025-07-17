---
applyTo: '**'
---
# Instructions - Flutter Web Sell App

## 🏗️ Arquitectura del Proyecto

Este es un **portal de ventas web** construido con **Flutter Web** que implementa **Clean Architecture** estricta con **Provider** para gestión de estado.

### Stack Tecnológico
- **Framework**: Flutter Web
- **Arquitectura**: Clean Architecture + Provider
- **Base de datos**: Firebase Firestore
- **Autenticación**: Firebase Auth + Google Sign-In
- **Tema**: Material Design 3 con soporte claro/oscuro

#### UI y UX  (Diseño de Sistema)
- **Material Design 3**: Implementación completa con ColorScheme.fromSeed()
- **Paleta de colores**: Basada en el color semilla
- **Tema adaptativo**: Soporte dinamico para modo claro/oscuro
- **Persistencia**: Estado del tema guardado en SharedPreferences

#### Responsive Design
```dart
// Breakpoints siguiendo Material Design 3
class ResponsiveBreakpoints {
  static const double mobile = 600;      // < 600px
  static const double tablet = 840;      // 600px - 840px  
  static const double desktop = 1200;    // 840px - 1200px
  static const double largeDesktop = 1600; // > 1200px
}

// Detección inteligente de dispositivos móviles
bool isMobile(BuildContext context) {
  // Considera ancho, relación de aspecto, orientación y densidad
}
```
### Responsive Design
- **Responsive Layout**: Adaptación automática mobile/tablet/desktop siempre y cuando sea necerio
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

## 🏗️ **Entidades del Dominio**

### Modelos de Negocio
- **User**: Modelo de usuario con soporte para autenticación Firebase y Google Sign-In
- **AccountModel**: Modelo de cuenta de negocio con configuraciones y metadatos
- **ProductCatalogue**: Modelo de producto del catálogo con precios, categorías, imágenes, etc.
- **CashRegisterModel**: Modelo de caja registradora con configuraciones y estado
- **TicketModel**: Modelo de ticket de venta con productos, totales, métodos de pago, etc.
- **CategoryCatalogue**: Modelo de categoría para organización del catálogo
- **TransactionModel**: Modelo de transacción financiera para registro de ventas

### Providers (Gestión de Estado)
- **AuthProvider**: Provider de autenticación con Firebase Auth y Google Sign-In
- **ThemeDataAppProvider**: Provider de tema con soporte claro/oscuro y persistencia
- **CatalogueProvider**: Provider de catálogo con gestión de productos y categorías
- **CashRegisterProvider**: Provider de cajas registradoras con selección,historial y configuración
- **SellProvider**: Provider de ventas con gestión de tickets y transacciones
- **PrinterProvider**: Provider de impresión térmica con configuración HTTP

### Repositorios (Contratos)
- **AuthRepository**: Contrato para operaciones de autenticación y gestión de usuarios
- **AccountRepository**: Contrato para gestión de cuentas de negocio
- **CatalogueRepository**: Contrato para operaciones CRUD del catálogo de productos
- **CashRegisterRepository**: Contrato para gestión de cajas registradoras

### Casos de Uso (Use Cases)
- **AuthUseCases**: Casos de uso para login, logout y gestión de sesiones
- **AccountUseCase**: Casos de uso para operaciones de cuentas de negocio
- **CatalogueUseCases**: Casos de uso para gestión del catálogo y productos
- **CashRegisterUseCases**: Casos de uso para operaciones de cajas registradoras
- **SellUseCases**: Casos de uso para procesamiento de ventas y tickets

### Componentes UI Principales
- **AppButton**: Botón primario unificado con soporte para iconos, loading y estados
- **AppOutlinedButton**: Botón secundario outlined con soporte para iconos y estados
- **AppFilledButton**: Botón secundario filled con soporte para iconos, loading y estados
- **AppFloatingActionButton**: FAB personalizado con animaciones y estados
- **AppBarButton**: Botón especializado para barras de aplicación con estilos consistentes
- **SearchButton**: Botón de búsqueda especializado para filtros
- **MoneyInputTextField**: Campo especializado para entrada de moneda y montos
- **InputTextField**: Campo de texto base con validaciones y estilos unificados
- **ImageWidget**: Componente optimizado para imágenes con fallbacks y loading
- **UserAvatar**: Avatar de usuario con soporte para Google Sign-In y placeholders
- **AppFeedback**: Sistema de feedback con loading, errores y confirmaciones
- **/component**: Indicadores,divisore,imagen,avatar entre otros componentes de progreso personalizados para la aplicación 

### Diálogos Especializados
- **BaseDialog**: Componentes base reutilizables para construcción de diálogos para mantener el patron de diseño establecido
- **CashRegisterManagementDialog**: Diálogo para gestión y configuración de cajas
- **ProductDialogs**: Suite de diálogos para gestión de productos del catálogo
- **SalesDialogs**: Diálogos especializados para procesamiento de ventas
- **TicketDialogs**: Diálogos para visualización y gestión de tickets
- **ConfigurationDialogs**: Diálogos para configuraciones de la aplicación

### Servicios (Core Services)
- **DatabaseCloud**: Servicio de base de datos Firebase Firestore
- **ThemeService**: Servicio de gestión de temas con persistencia
- **ThermalPrinterHttpService**: Servicio HTTP para impresión térmica
- **CashRegisterPersistenceService**: Servicio de persistencia para cajas registradoras

### Páginas de la Aplicación
- **LoginPage**: Página de inicio de sesión con Firebase Auth y Google Sign-In
- **SellPage**: Página principal de ventas con catálogo y caja registradora
- **WelcomePage**: Página de bienvenida y selección de cuenta

### Utilidades y Helpers
- **ResponsiveBreakpoints**: Clase utilitaria para breakpoints responsivos
- **SharedPrefsKeys**: Constantes para claves de SharedPreferences
- **Functions**: Utilidades y funciones helper generales para la aplicación
- **CoreWidgets**: Exportaciones centralizadas de widgets reutilizables


#### Arquitectura de Widgets
```dart
lib/core/widgets/
├── buttons/           # Botones especializados (AppButton, FAB, etc.)
├── dialogs/           # Sistema modular de diálogos por dominio
├── inputs/            # Campos de entrada optimizados
├── ui/                # Componentes básicos reutilizables
├── feedback/          # Estados de carga, errores y confirmaciones
├── responsive/        # Helpers para diseño adaptativo
└── media/             # Manejo de imágenes y media
```

#### UX Considerations
- **Progressive Enhancement**: Funcionalidad base primero, mejoras después
- **Touch-First**: Diseño optimizado para interacción táctil
- **Keyboard Navigation**: Soporte completo para navegación por teclado
- **Loading States**: Feedback visual para todas las operaciones asíncronas
- **Error Handling**: Mensajes de error claros y acciones de recuperación
- **Offline Support**: Modo demo para usuarios anónimos

#### Animaciones y Transiciones
- **flutter_animate**: Animaciones fluidas y performantes
- **Material Transitions**: Transiciones nativas de Material 3
- **Micro-interactions**: Feedback visual para acciones del usuario
- **Staggered Animations**: Para listas y grids de productos

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
