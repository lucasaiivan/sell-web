---
applyTo: '**'
---

# Guía de Desarrollo - Flutter Web

## 🎯 Tecnologías Base
- **Framework**: Flutter Web
- **Arquitectura**: Clean Architecture (estrictamente)
- **Gestión de Estado**: Provider
- **Diseño**: Material Desing 3

## 🏗️ Arquitectura y Estructura

### Clean Architecture
- Mantener separación clara entre capas (presentation, domain, data)
- Aplicar principios SOLID
- Utilizar interfaces para abstraer dependencias
- Provider para inyección de dependencias y manejo de estados

### Organización de Carpetas
```
lib/
├── core/           # Widgets y utilidades reutilizables
├── data/           # Implementaciones de repositorios
├── domain/         # Entidades, repositorios y casos de uso
└── presentation/   # UI, páginas y providers
```

## 🎨 Diseño y UX 

### Material 3
- Implementar guías de diseño de Material Desing 3 como base
- Soporte completo para servicio de tema dinámico claro/oscuro
- Aplicar buenas prácticas de UI y UX
- Componentes consistentes y accesibles
- Aplicar todos los componentes de Material Desing 3 

### Responsivo y Adaptativo
- Usar `LayoutBuilder` y `MediaQuery` para diseños responsivos 
- Asegurar que la UI se adapte a móviles, tablets y desktops 

### Componentes Reutilizables
- **[core]**: Widgets reutilizables
- **[ComponentApp]**: Componentes específicos (buttons, textButtons, inputs, etc.)
- Evitar duplicación de código
- Mejorar mantenibilidad

## 📝 Convenciones de Código
### Estilo de Código 
- **Imports**: Agrupar imports por tipo (flutter, third-party, local)

### Nomenclatura
- **Idioma**: Inglés para nombres de archivos, carpetas, clases,metodos, variables etc...
- **Convención**: snake_case para archivos, PascalCase para clases, camelCase para variables y usar nombres descriptivos 
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
- **Contexto claro**: Crear o actualizar cada ves se agrege una novedad si es necesirio un README.md (para facilitar contexto a al agent IA) que va a contener un explicacion breve de cada archivo (contexto, propósito y uso) de cada archivo de dicha carpeta que pertenece 

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
- Incluir contexto clave (contexto, propósito, uso, etc...) en (README.md) en cada capa (presentation, domain, data,etc...) de todo los archico que contengan para mejorar la comprensión de la IA
- Solicitar implementaciones con Provider cuando sea necesario

## 🔧 Debugging y Herramientas

### Flutter DevTools
- **Inspector**: Usar para analizar el árbol de widgets y detectar problemas de UI
- **Performance**: Monitorear rendimiento y detectar rebuilds innecesarios
- **Memory**: Identificar memory leaks en widgets y providers
- **Network**: Supervisar llamadas HTTP y APIs

### Estrategias de Debug
```dart
// Logging estructurado para debugging
import 'package:flutter/foundation.dart';

void debugLog(String message, {String? tag}) {
  if (kDebugMode) {
    print('[${tag ?? 'DEBUG'}] ${DateTime.now()}: $message');
  }
}

// Debug específico por capas
class RepositoryLogger {
  static void logApiCall(String endpoint, Map<String, dynamic>? data) {
    debugLog('API Call: $endpoint with data: $data', tag: 'REPOSITORY');
  }
}
```


### Herramientas de Calidad
- **flutter analyze**: Ejecutar antes de cada commit
- **dart format**: Formateo automático del código

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

### Manejo de Estado Eficiente
- **Consumer granular**: Usar Consumer específicos en lugar de Consumer generales
- **Selector widgets**: Implementar Selector para rebuilds optimizados
- **Provider.of(listen: false)**: Para acciones que no requieren rebuild
- **MultiProvider**: Organizar providers de manera jerárquica 

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

## 🔒 Seguridad y Manejo de Errores

### Validación de Datos
- Implementar validadores en el domain layer
- Usar freezed para objetos inmutables
- Validar inputs en tiempo real en la UI
- Sanitizar datos antes de enviar a APIs

## 📱 Responsive y Adaptativo

### Diseño Responsivo
```dart
// Breakpoints para diferentes tamaños
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

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

## ✅ Buenas Prácticas Generales
- **Inmutabilidad**: Usar objetos inmutables con freezed cuando sea posible
- **Separation of Concerns**: Cada clase/función tiene una única responsabilidad
- **DRY Principle**: Evitar duplicación de código mediante componentes reutilizables
- **KISS Principle**: Mantener soluciones simples y directas
- **Progressive Enhancement**: Construir funcionalidad base primero, luego mejorar
- **Code Review**: Revisar código antes de merge, enfocándose en arquitectura y performance
- **Documentation**: Documentar decisiones arquitectónicas importantes
- **Version Control**: Commits atómicos con mensajes descriptivos en Español

## 🛠️ Herramientas y Configuración


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
