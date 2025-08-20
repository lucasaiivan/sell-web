# 🏗️ Core - Arquitectura Transversal

El directorio `core` contiene toda la **infraestructura transversal** de la aplicación que es **independiente del dominio de negocio**. Esta capa proporciona servicios, utilidades y componentes reutilizables que pueden ser utilizados por todas las demás capas del proyecto.

## 📋 Principios de Diseño

### Clean Architecture Compliance
- **Independencia de Frameworks**: Los componentes core no dependen de Flutter específicamente
- **Testabilidad**: Todos los servicios son testables unitariamente
- **Separación de Responsabilidades**: Cada subdirectorio tiene una responsabilidad específica
- **Inversión de Dependencias**: Los contratos están definidos antes que las implementaciones

### Patrones Aplicados
- **Repository Pattern**: Para abstraer el acceso a datos
- **Service Locator**: Para inyección de dependencias
- **Factory Pattern**: Para creación de objetos complejos
- **Observer Pattern**: Para notificaciones reactivas

## 🗂️ Estructura del Directorio

```
lib/core/
├── constants/          # Constantes y configuraciones estáticas
├── config/            # Configuraciones de la aplicación
├── services/          # Servicios transversales de infraestructura
├── utils/             # Utilidades y helpers reutilizables
├── widgets/           # Componentes UI reutilizables
├── extensions/        # Extensions de Dart/Flutter
├── mixins/           # Mixins reutilizables
└── exceptions/       # Manejo centralizado de errores
```

## 🎯 Propósito y Responsabilidades

### ✅ Lo que SÍ pertenece aquí
- Servicios de infraestructura (base de datos, HTTP, storage)
- Widgets UI reutilizables entre diferentes features
- Utilidades de formateo, validación y transformación
- Configuraciones globales de la aplicación
- Extensiones que mejoran tipos base de Dart/Flutter
- Manejo centralizado de errores y excepciones

### ❌ Lo que NO pertenece aquí
- Lógica de negocio específica
- Entidades de dominio
- Casos de uso específicos
- Providers específicos de features
- Páginas o screens completas

## 📖 Guías de Uso

### Para Desarrolladores
1. **Antes de crear algo nuevo**: Verificar si ya existe algo similar en core
2. **Reutilización**: Priorizar uso de componentes existentes antes de crear nuevos
3. **Documentación**: Cada archivo debe estar documentado con su propósito
4. **Testing**: Todo servicio/utilidad debe tener pruebas unitarias

### Convenciones de Nomenclatura
- **Archivos**: `snake_case.dart`
- **Clases**: `PascalCase`
- **Constantes**: `UPPER_SNAKE_CASE`
- **Métodos/Variables**: `camelCase`

### Import Strategy
```dart
// ✅ Correcto - Import específico
import 'package:sell_web/core/utils/formatters/currency_formatter.dart';

// ❌ Evitar - Import general que expone todo
import 'package:sell_web/core/core.dart';
```

## 🔧 Configuración y Setup

### Dependencias Clave
- **firebase_core**: Configuración de Firebase
- **shared_preferences**: Persistencia local
- **http**: Cliente HTTP para servicios externos
- **intl**: Internacionalización y formateo

### Inicialización
Los servicios core se inicializan en `main.dart` antes que cualquier otra capa:

```dart
void main() async {
  // 1. Inicializar servicios core
  await CoreServices.initialize();
  
  // 2. Configurar providers
  // 3. Ejecutar app
}
```

## 📊 Métricas de Calidad

### Objetivos
- **Coverage**: > 80% en servicios core
- **Complexity**: Funciones con complejidad ciclomática < 10
- **Dependencies**: Máximo 3 niveles de dependencia
- **Performance**: Widgets core con rebuild < 16ms

### Monitoreo
- Usar `flutter analyze` para verificar calidad de código
- Ejecutar tests unitarios: `flutter test test/core/`
- Verificar performance: Flutter Inspector

## 🚀 Roadmap y Evolución

### ✅ Implementaciones Completadas
1. **Sistema de Excepciones** - Manejo centralizado de errores con logging multi-destino
2. **Widgets Reorganizados** - Categorización por responsabilidad (buttons, inputs, dialogs, etc.)
3. **Arquitectura Clean** - Separación clara de capas y responsabilidades

### Próximas Mejoras
1. Implementar cache inteligente en servicios
2. Sistema de configuración centralizado
3. Extensiones útiles para tipos base
4. Utilidades centralizadas (formatters, validators, etc.)
5. Optimizar performance de widgets complejos

### Deprecaciones
- Consultar `CHANGELOG.md` para componentes deprecados
- Migrar gradualmente componentes legacy

---

📚 **Para más detalles**, revisar el README específico de cada subdirectorio.
