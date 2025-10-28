# 📚 Guía de Uso - Nueva Arquitectura de Navegación

## 🎯 Para Desarrolladores

### Cómo Agregar una Nueva Página al Sistema de Navegación

#### 1. Crear la Nueva Página

```dart
// lib/presentation/pages/nueva_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/layout/app_drawer.dart';

class NuevaPage extends StatelessWidget {
  const NuevaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Página'),
      ),
      drawer: const AppDrawer(), // Usar el drawer compartido
      body: Center(
        child: Text('Contenido de la nueva página'),
      ),
    );
  }
}
```

#### 2. Actualizar HomeProvider

Agregar el índice de la nueva página:

```dart
// lib/presentation/providers/home_provider.dart
class HomeProvider extends ChangeNotifier {
  int _currentPageIndex = 0;
  
  // Agregar getter para la nueva página
  bool get isNuevaPage => _currentPageIndex == 2;
  
  // Agregar método de navegación
  void navigateToNueva() {
    setPageIndex(2);
  }
}
```

#### 3. Actualizar HomePage

Agregar la nueva página al `IndexedStack` y al `NavigationBar`:

```dart
// lib/presentation/pages/home_page.dart
Widget _buildMainNavigation(BuildContext context, SellProvider sellProvider) {
  return Consumer<HomeProvider>(
    builder: (context, homeProvider, _) {
      return Scaffold(
        body: IndexedStack(
          index: homeProvider.currentPageIndex,
          children: const [
            SellPage(),
            CataloguePage(),
            NuevaPage(), // ← Agregar aquí
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, homeProvider),
      );
    },
  );
}

Widget _buildBottomNavigationBar(BuildContext context, HomeProvider homeProvider) {
  return NavigationBar(
    selectedIndex: homeProvider.currentPageIndex,
    onDestinationSelected: (index) => homeProvider.setPageIndex(index),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'Ventas',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Catálogo',
      ),
      // ← Agregar aquí
      NavigationDestination(
        icon: Icon(Icons.nuevo_icono_outlined),
        selectedIcon: Icon(Icons.nuevo_icono),
        label: 'Nueva',
      ),
    ],
  );
}
```

### Cómo Navegar Programáticamente

#### Desde un Widget con Acceso a HomeProvider

```dart
// Navegar a la página de ventas
context.read<HomeProvider>().navigateToSell();

// Navegar a la página de catálogo
context.read<HomeProvider>().navigateToCatalogue();

// Navegar por índice
context.read<HomeProvider>().setPageIndex(1);
```

#### Desde un Provider

```dart
class MiProvider extends ChangeNotifier {
  void algunMetodo(BuildContext context) {
    // Obtener HomeProvider
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    
    // Navegar
    homeProvider.navigateToSell();
  }
}
```

### Cómo Usar el AppDrawer Compartido

El `AppDrawer` se incluye automáticamente en todas las páginas principales:

```dart
Scaffold(
  drawer: const AppDrawer(), // Simplemente agregarlo
  body: ...,
)
```

Si necesitas personalizar el contenido del drawer para una página específica, puedes crear un drawer personalizado pero siguiendo el mismo estilo visual.

### Cómo Acceder al Estado de Navegación

```dart
// En un Consumer
Consumer<HomeProvider>(
  builder: (context, homeProvider, child) {
    if (homeProvider.isSellPage) {
      return Text('Estás en la página de ventas');
    }
    return Text('Estás en otra página');
  },
)

// Con Provider.of
final homeProvider = Provider.of<HomeProvider>(context);
if (homeProvider.currentPageIndex == 0) {
  // Hacer algo específico para la página de ventas
}
```

## 🔄 Patrones Comunes

### 1. Mantener Estado entre Navegaciones

El `IndexedStack` mantiene automáticamente el estado de las páginas al cambiar entre ellas:

```dart
IndexedStack(
  index: homeProvider.currentPageIndex,
  children: const [
    SellPage(),      // Estado se mantiene al cambiar
    CataloguePage(), // Estado se mantiene al cambiar
  ],
)
```

### 2. Ejecutar Código al Cambiar de Página

Escuchar cambios en `HomeProvider`:

```dart
class MiWidget extends StatefulWidget {
  @override
  State<MiWidget> createState() => _MiWidgetState();
}

class _MiWidgetState extends State<MiWidget> {
  @override
  void initState() {
    super.initState();
    
    // Escuchar cambios de navegación
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.addListener(_onPageChanged);
  }
  
  void _onPageChanged() {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.isSellPage) {
      // Hacer algo cuando se navega a ventas
    }
  }
  
  @override
  void dispose() {
    Provider.of<HomeProvider>(context, listen: false)
      .removeListener(_onPageChanged);
    super.dispose();
  }
}
```

### 3. Navegación Condicional

```dart
void onActionComplete(BuildContext context) {
  final homeProvider = context.read<HomeProvider>();
  
  // Navegar según condición
  if (condition) {
    homeProvider.navigateToSell();
  } else {
    homeProvider.navigateToCatalogue();
  }
}
```

## 🎨 Personalización del AppDrawer

Si necesitas agregar elementos al drawer:

```dart
// Opción 1: Modificar app_drawer.dart directamente
// Opción 2: Crear un wrapper
class CustomAppDrawer extends StatelessWidget {
  final Widget? extraContent;
  
  const CustomAppDrawer({super.key, this.extraContent});
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header del AppDrawer original
            _buildHeader(context),
            
            // Contenido extra
            if (extraContent != null) extraContent!,
            
            const Spacer(),
            
            // Footer del AppDrawer original
            _buildFooter(context),
          ],
        ),
      ),
    );
  }
}
```

## ⚠️ Buenas Prácticas

### ✅ DO

- Usar `const` constructors siempre que sea posible
- Mantener las páginas enfocadas en una sola responsabilidad
- Usar `AppDrawer` para consistencia visual
- Usar `HomeProvider` para toda navegación principal
- Mantener el estado con `IndexedStack`

### ❌ DON'T

- No navegar usando `Navigator.push()` para las páginas principales
- No crear drawers personalizados sin justificación
- No duplicar lógica de navegación
- No modificar `HomePage` sin actualizar la documentación

## 🧪 Testing

### Test del HomeProvider

```dart
void main() {
  test('HomeProvider cambia de página correctamente', () {
    final provider = HomeProvider();
    
    expect(provider.currentPageIndex, 0);
    expect(provider.isSellPage, true);
    
    provider.navigateToCatalogue();
    
    expect(provider.currentPageIndex, 1);
    expect(provider.isCataloguePage, true);
  });
  
  test('HomeProvider reset funciona correctamente', () {
    final provider = HomeProvider();
    
    provider.setPageIndex(2);
    expect(provider.currentPageIndex, 2);
    
    provider.reset();
    expect(provider.currentPageIndex, 0);
  });
}
```

### Test de Navegación en HomePage

```dart
testWidgets('HomePage navega entre páginas', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        // ... otros providers
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
  
  // Verificar que empieza en SellPage
  expect(find.byType(SellPage), findsOneWidget);
  
  // Tap en el botón de Catálogo
  await tester.tap(find.text('Catálogo'));
  await tester.pumpAndSettle();
  
  // Verificar que cambió a CataloguePage
  expect(find.byType(CataloguePage), findsOneWidget);
});
```

## 📖 Referencias

- [Documentación de Provider](https://pub.dev/packages/provider)
- [Material 3 Navigation](https://m3.material.io/components/navigation-bar/overview)
- [IndexedStack Documentation](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html)
- [REFACTORING_NAVIGATION.md](./REFACTORING_NAVIGATION.md) - Detalles de la refactorización
- [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md) - Diagramas visuales

## 🆘 Solución de Problemas

### El estado de la página se pierde al navegar

**Problema**: Al volver a una página, pierde su estado (scroll, formularios, etc.)

**Solución**: Verificar que estás usando `IndexedStack` en lugar de mostrar/ocultar widgets condicionalmente.

### No puedo acceder a HomeProvider

**Problema**: `Provider.of<HomeProvider>` lanza error

**Solución**: Verificar que `HomeProvider` está registrado en el árbol de providers en `main.dart`:

```dart
ChangeNotifierProvider(create: (_) => HomeProvider()),
```

### El drawer no se cierra al seleccionar cuenta

**Problema**: Al seleccionar cuenta en el diálogo, el drawer no se cierra

**Solución**: El drawer se cierra automáticamente. Si no lo hace, verificar que estás usando `showAccountSelectionDialog` correctamente.

## 💡 Tips

1. **Performance**: `IndexedStack` construye todos los widgets, pero solo muestra uno. Para páginas muy pesadas, considera lazy loading.

2. **Deep Linking**: Para implementar deep linking, puedes usar el `currentPageIndex` de `HomeProvider`.

3. **Animaciones**: Para animaciones personalizadas entre páginas, considera reemplazar `IndexedStack` con `PageView` o `AnimatedSwitcher`.

4. **Estado Persistente**: El estado de las páginas persiste mientras la app esté abierta. Para persistencia entre sesiones, usa `SharedPreferences` o similar.

## 🔮 Roadmap Futuro

- [ ] Implementar deep linking con índices de página
- [ ] Agregar animaciones entre transiciones
- [ ] Implementar lazy loading para páginas pesadas
- [ ] Agregar más páginas (Reportes, Clientes, etc.)
- [ ] Implementar navegación jerárquica (subrutas)
