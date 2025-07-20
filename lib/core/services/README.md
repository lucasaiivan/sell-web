# Core Services - README

Esta carpeta contiene los servicios fundamentales de la aplicación que proporcionan funcionalidades compartidas y configuraciones centralizadas.

## 📁 Servicios Disponibles

### `theme_service.dart`
**Propósito**: Servicio centralizado para gestión de temas y estilos de la aplicación.

**Características**:
- **Gestión de ThemeMode**: Control dinámico entre modo claro, oscuro y sistema
- **Configuración centralizada**: Todos los estilos de componentes en un solo lugar
- **Material Design 3**: Implementación completa con ColorScheme.fromSeed()
- **Estilos personalizados**: Configuración específica para todos los tipos de botones
- **Componentes adicionales**: AppBar, Cards, InputFields con estilos consistentes

**Uso**:
```dart
// En main.dart
theme: ThemeService.lightTheme,
darkTheme: ThemeService.darkTheme,

// Cambiar color semilla
ThemeService.seedColor = Colors.green; // Requiere restart
```

**Componentes configurados**:
- `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`
- `FloatingActionButton`
- `AppBar` con estilos diferenciados
- `Card` con bordes redondeados
- `InputDecoration` con focus states

### `database_cloud.dart`
**Propósito**: Servicio para interacciones con Firebase Firestore.

**Uso**: Manejo de operaciones CRUD con la base de datos en la nube.

### `app_data_persistence_service.dart`
**Propósito**: Servicio centralizado para gestionar la persistencia local de todos los datos de configuración de la aplicación.

**Características**:
- **Gestión de cuentas**: Persistencia de cuenta seleccionada
- **Gestión de cajas registradoras**: Persistencia de caja registradora seleccionada
- **Gestión de tema**: Persistencia del modo de tema (claro/oscuro)
- **Gestión de tickets**: Persistencia de ticket actual y último vendido
- **Configuraciones de impresión**: Persistencia de configuraciones de impresora
- **Operaciones generales**: Limpieza de datos, verificación de claves, etc.

**Uso**:
```dart
final persistenceService = AppDataPersistenceService.instance;

// Gestión de cuentas
await persistenceService.saveSelectedAccountId('account123');
String? accountId = await persistenceService.getSelectedAccountId();

// Gestión de tema
await persistenceService.saveThemeMode('dark');
String? theme = await persistenceService.getThemeMode();

// Gestión de tickets
await persistenceService.saveCurrentTicket(ticketJson);
String? ticket = await persistenceService.getCurrentTicket();

// Limpieza de datos
await persistenceService.clearSessionData(); // Solo datos de sesión
await persistenceService.clearAllData(); // Todos los datos
```

**Beneficios**:
- Centralización de toda la persistencia local
- API consistente para todos los tipos de datos
- Gestión de errores unificada
- Facilita el mantenimiento y testing

### `thermal_printer_http_service.dart`
**Propósito**: Servicio HTTP para comunicación con impresoras térmicas.

**Uso**: Envío de comandos de impresión a través de HTTP a impresoras térmicas en red.

## 🏗️ Patrón de Arquitectura

Los servicios siguen el patrón de **Clean Architecture**:
- **Independientes**: No dependen de frameworks específicos
- **Testables**: Fácil inyección de dependencias para testing
- **Reutilizables**: Pueden ser usados por múltiples capas
- **Centralizados**: Configuración única para toda la aplicación

## 🎨 Personalización de Temas

Para personalizar los temas de la aplicación:

1. **Cambiar color principal**:
```dart
// En ThemeService
static const MaterialColor seedColor = Colors.green; // Cambiar aquí
```

2. **Personalizar botones específicos**:
```dart
// Modificar los métodos _lightElevatedButtonTheme, _darkElevatedButtonTheme, etc.
```

3. **Agregar nuevos componentes**:
```dart
// Agregar nuevas configuraciones en lightTheme y darkTheme
dialogTheme: _lightDialogTheme,
```

## 🔧 Mejores Prácticas

1. **Mantenga las configuraciones centralizadas** en `ThemeService`
2. **Use constantes** para valores que se repiten
3. **Documente cambios** en los estilos personalizados
4. **Teste en ambos modos** (claro y oscuro) al hacer cambios
5. **Siga Material Design 3** guidelines para consistencia

## 🚀 Extensibilidad

Para agregar nuevos servicios:

1. Crear el archivo en esta carpeta
2. Seguir el patrón de singleton o static methods según corresponda
3. Documentar en este README
4. Agregar export en el archivo principal si es necesario
