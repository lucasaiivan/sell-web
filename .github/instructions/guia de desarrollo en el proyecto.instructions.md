---
applyTo: '**'
---

# Guía de Desarrollo - Flutter Web

## 🎯 Tecnologías Base
- **Framework**: Flutter Web
- **Arquitectura**: Clean Architecture (estrictamente)
- **Gestión de Estado**: Provider
- **Diseño**: Material 3

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
- Implementar guías de diseño de Material 3
- Soporte completo para tema claro/oscuro dinámico
- Aplicar buenas prácticas de UX
- Componentes consistentes y accesibles

### Componentes Reutilizables
- **[core]**: Widgets básicos reutilizables
- **[ComponentApp]**: Componentes específicos (buttons, textButtons, inputs, etc.)
- Evitar duplicación de código
- Mejorar mantenibilidad

## 📝 Convenciones de Código

### Nomenclatura
- **Idioma**: Inglés para nombres de archivos, carpetas, clases,metodos, variables etc...
- **Convención**: snake_case para archivos, PascalCase para clases, camelCase para variables
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
- **Contexto claro**: Proporcionar suficiente contexto en archivos para que la IA genere código apropiado

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
- Mencionar Material 3 y Clean Architecture en las solicitudes
- Incluir contexto de la capa (presentation, domain, data)
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
- **flutter test --coverage**: Mantener cobertura >80%
- **very_good_analysis**: Lint rules estrictas

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

### Error Handling Robusto
```dart
// Implementar Result pattern para manejo de errores
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Error de conexión');
}

// Uso en repositorios
Future<Either<Failure, List<Product>>> getProducts() async {
  try {
    final response = await apiClient.get('/products');
    return Right(ProductMapper.fromJson(response.data));
  } on SocketException {
    return const Left(NetworkFailure());
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}
```

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

### Extensiones VS Code Recomendadas
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "github.copilot",
    "github.copilot-chat",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "usernamehw.errorlens",
    "aaron-bond.better-comments"
  ]
}
```

### Configuración launch.json
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Web Debug",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "deviceId": "chrome",
      "args": ["--web-port", "3000"]
    },
    {
      "name": "Flutter Web Profile",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "deviceId": "chrome",
      "flutterMode": "profile"
    }
  ]
}
```

### Scripts de Automatización
```json
// package.json scripts recomendados
{
  "scripts": {
    "analyze": "flutter analyze",
    "format": "dart format .",
    "test": "flutter test --coverage",
    "build": "flutter build web --release",
    "serve": "flutter run -d chrome --web-port 3000"
  }
}
```

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

## 📋 Checklist de Desarrollo

### Antes de Empezar una Feature
- [ ] Definir interfaces en domain layer
- [ ] Crear entidades y DTOs necesarios
- [ ] Implementar casos de uso
- [ ] Configurar providers necesarios
- [ ] Diseñar UI siguiendo Material 3

### Antes de Commit
- [ ] Ejecutar `flutter analyze` sin errores
- [ ] Ejecutar `dart format .`
- [ ] Correr tests unitarios y de widgets
- [ ] Verificar que no hay console.log o print() innecesarios
- [ ] Comprobar que los nombres están en inglés
- [ ] Documentar funciones complejas en español

### Antes de Deploy
- [ ] Testing en múltiples tamaños de pantalla
- [ ] Verificar tema claro/oscuro
- [ ] Optimizar assets e imágenes
- [ ] Revisar bundle size 
- [ ] Validar accesibilidad básica

--- 