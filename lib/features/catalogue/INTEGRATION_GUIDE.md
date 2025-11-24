# Guía de Integración: Feature Catalogue con Clean Architecture

## 🎯 Resumen de lo Implementado

Hemos creado el módulo **Catalogue** siguiendo Clean Architecture + Feature-first, con:
- ✅ Inyección de Dependencias configurada (get_it + injectable)
- ✅ Provider nuevo que usa UseCases
- ✅ Estructura completa de Domain, Data y Presentation

## 📋 Pasos para Integrar en tu App

### 1. Inicializar Dependency Injection en `main.dart`

Actualiza tu archivo `main.dart` para configurar las dependencias al inicio:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/di/injection_container.dart'; // ← AGREGAR

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // ← AGREGAR: Configurar inyección de dependencias
  await configureDependencies();
  
  runApp(const MyApp());
}
```

### 2. Proveer el CatalogueProvider en tu árbol de widgets

Tienes dos opciones:

#### Opción A: Usar Provider + get_it (Recomendado)

En tu `main.dart` o donde configures tus providers:

```dart
import 'package:provider/provider.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'core/di/injection_container.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Tus providers existentes...
        
        // ← AGREGAR: Nuevo CatalogueProvider usando DI
        ChangeNotifierProvider(
          create: (_) => getIt<CatalogueProvider>(),
        ),
      ],
      child: MaterialApp(
        // ...
      ),
    );
  }
}
```

#### Opción B: Usar solo en páginas específicas

Si solo quieres usarlo en `CataloguePage`:

```dart
import 'package:provider/provider.dart';
import '../providers/catalogue_provider.dart';
import '../../core/di/injection_container.dart';

class CataloguePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<CatalogueProvider>(),
      child: _CataloguePageContent(),
    );
  }
}
```

### 3. Actualizar Imports en `catalogue_page.dart`

Cambia el import del provider antiguo por el nuevo:

```dart
// ANTES:
// import '../providers/catalogue_provider.dart';

// DESPUÉS:
import '../../features/catalogue/presentation/providers/catalogue_provider.dart';
import '../../features/catalogue/domain/entities/product_catalogue.dart';
```

### 4. Adaptar la Llamada Inicial de Carga

En tu `catalogue_page.dart`, donde cargues los productos, pasa el `accountId`:

```dart
@override
void initState() {
  super.initState();
  
  // Obtener accountId (de donde lo tengas actualmente)
  final accountId = /* tu lógica para obtener el accountId */;
  
  // Cargar productos usando el nuevo provider
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<CatalogueProvider>().loadProducts(accountId);
  });
}
```

## 🔄 Migración Gradual (opcional)

Si prefieres migrar gradualmente:

1. **Mantén ambos providers** (el viejo y el nuevo) temporalmente
2. **Crea una página de prueba** que use el nuevo `CatalogueProvider`
3. **Compara resultados** y ajusta
4. **Elimina el provider antiguo** una vez validado

## 📁 Estructura Final del Proyecto

```
lib/
├── core/
│   └── di/
│       ├── injection_container.dart ✅
│       └── injection_container.config.dart ✅ (generado)
│
├── features/
│   └── catalogue/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           │   └── catalogue_provider.dart ✅ NUEVO
│           ├── pages/
│           └── widgets/
│
├── presentation/ (ANTIGUO - mantener temporalmente)
│   ├── pages/
│   │   └── catalogue_page.dart (migrar o adaptar)
│   └── providers/
│       └── catalogue_provider.dart (VIEJO)
│
└── main.dart (actualizar)
```

## 🧪 Testing Rápido

Para verificar que todo funciona:

```dart
// En algún lugar de tu código
final provider = getIt<CatalogueProvider>();
print('Provider obtenido correctamente: ${provider != null}');
```

## ⚠️ Posibles Problemas y Soluciones

### Problema: "No se puede resolver CatalogueProvider"
**Solución**: Asegúrate de haber ejecutado `flutter pub run build_runner build`

### Problema: "GetIt no encuentra FirebaseFirestore"
**Solución**: Verifica que Firebase esté inicializado ANTES de `configureDependencies()`

### Problema: Imports rotos en catalogue_page.dart
**Solución**: Actualiza los imports para usar las entidades del nuevo feature:
```dart
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
```

## 🚀 Próximos Pasos

Una vez integrado el provider:

1. **Migrar la página** completa a `features/catalogue/presentation/pages/`
2. **Crear casos de uso adicionales**:
   - `CreateProductUseCase`
   - `DeleteProductUseCase`
   - `SearchProductsUseCase`
3. **Agregar manejo de errores** con `Either<Failure, Success>`
4. **Escribir tests unitarios** para los UseCases

## 📞 Ayuda

Si encuentras errores específicos, revisa:
- Los logs de `flutter pub run build_runner build`
- Que todas las anotaciones `@injectable`, `@LazySingleton` estén correctas
- Que `injection_container.config.dart` se haya generado
