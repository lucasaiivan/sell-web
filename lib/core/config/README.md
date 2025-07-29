# Configuración de OAuth - README

## 📋 Descripción

Este archivo maneja la configuración centralizada de OAuth para la aplicación Flutter Web Sell, específicamente para Google Sign-In, obteniendo las credenciales desde `firebase_options.dart` para mantener una única fuente de verdad.

## 🔧 Archivos

### `/core/config/oauth_config.dart`
**Propósito**: Configuración específica de OAuth y autenticación externa.
**Contexto**: Actúa como proxy hacia `firebase_options.dart` para obtener credenciales OAuth.
**Uso**: Importar `OAuthConfig` donde se necesite configurar Google Sign-In.

### `/core/config/firebase_options.dart`
**Propósito**: Configuración generada por FlutterFire CLI + Google Sign-In Client ID.
**Contexto**: Fuente única de verdad para todas las configuraciones de Firebase y OAuth.
**Uso**: Automáticamente usado por `OAuthConfig` y `Firebase.initializeApp()`.

## 🚀 Implementación

### Antes (Duplicado)
```dart
// Client ID duplicado en múltiples archivos
// firebase_options.dart
static const String googleSignInClientId = '232181553323-...';

// oauth_config.dart  
static const String googleSignInClientId = '232181553323-...'; // ❌ Duplicado
```

### Después (Centralizado)
```dart
// oauth_config.dart - Obtiene desde firebase_options.dart
static String get googleSignInClientId => 
    DefaultFirebaseOptions.googleSignInClientId; // ✅ Fuente única
```

## 🔒 Beneficios de Seguridad

1. **Fuente única de verdad**: Client ID definido solo en `firebase_options.dart`
2. **Eliminación de duplicación**: No hay credenciales duplicadas en múltiples archivos
3. **Centralización**: Todas las configuraciones Firebase en un solo lugar
4. **Mantenibilidad**: Un solo lugar para actualizar configuraciones OAuth
5. **Consistencia**: Garantiza que el mismo Client ID se use en toda la aplicación
6. **Separación de responsabilidades**: OAuth config actúa como proxy hacia Firebase options

## 🔧 Configuración Adicional

### Verificar web/index.html
Asegúrate de que el `client_id` en `web/index.html` coincida:
```html
<meta name="google-signin-client_id" content="232181553323-eilihkps148nu7dp45cole4mlr7pkf1d.apps.googleusercontent.com">
```

### Variables de Entorno (Opcional)
Para mayor seguridad en producción, considera usar variables de entorno:
```dart
// En desarrollo futuro
static const String googleSignInClientId = 
    String.fromEnvironment('GOOGLE_CLIENT_ID', 
        defaultValue: 'fallback-client-id');
```

## 📱 Uso en la Aplicación

```dart
// Importar la configuración
import 'package:sellweb/core/config/oauth_config.dart';

// El OAuthConfig obtiene automáticamente el Client ID desde firebase_options.dart
final googleSignIn = GoogleSignIn(
  scopes: OAuthConfig.googleSignInScopes,
  clientId: OAuthConfig.googleSignInClientId, // ← Obtiene desde DefaultFirebaseOptions
);
```

## 🔗 Flujo de Configuración

```
web/index.html (meta tag)
        ↓
firebase_options.dart (fuente única de verdad)
        ↓
oauth_config.dart (proxy + validación)
        ↓  
main.dart (uso final)
        ↓
GoogleSignIn (configuración aplicada)
```

## 🧪 Verificación

El proyecto incluye pruebas automatizadas que verifican:
- ✅ Consistencia entre `OAuthConfig` y `DefaultFirebaseOptions`
- ✅ Presencia de scopes requeridos
- ✅ Formato correcto del Client ID
- ✅ Configuración completa disponible

Ejecutar pruebas:
```bash
flutter test test/core/config/oauth_config_test.dart
```

## ✅ Mejores Prácticas Implementadas

- ✅ **Fuente única de verdad**: Client ID definido solo en `firebase_options.dart`
- ✅ **Eliminación de duplicación**: No hay credenciales repetidas en múltiples archivos
- ✅ **Configuración proxy**: `OAuthConfig` actúa como proxy hacia `DefaultFirebaseOptions`
- ✅ **Documentación clara**: Cada configuración está documentada con su propósito
- ✅ **Separación de responsabilidades**: OAuth config separado de la lógica principal
- ✅ **Reutilización**: Configuraciones reutilizables en toda la aplicación
- ✅ **Mantenibilidad**: Un solo lugar para actualizar credenciales OAuth
- ✅ **Consistencia**: Garantiza el uso del mismo Client ID en toda la app
