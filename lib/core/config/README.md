# 🔧 Config - Configuraciones de la Aplicación

El directorio `config` contiene todas las **configuraciones centralizadas** de la aplicación, incluyendo configuraciones de servicios externos, credenciales y parámetros de inicialización.

## 🎯 Propósito

Centralizar todas las configuraciones de la aplicación siguiendo el principio de **Single Source of Truth** y facilitando el mantenimiento y despliegue en diferentes entornos.

## 📁 Archivos y Responsabilidades

### `app_config.dart`
**Configuraciones generales de la aplicación**
- Variables de entorno
- Configuraciones por ambiente (dev, staging, prod)
- Feature flags
- Configuraciones globales de UI/UX

```dart
class AppConfig {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const bool enableDebugFeatures = true;
  static const String appTitle = 'Sell Web';
}
```

### `oauth_config.dart`
**Configuración específica de OAuth y autenticación externa**
- Configuración de Google Sign-In
- Client IDs y secrets
- Scopes de autenticación
- Configuraciones específicas de OAuth

```dart
class OAuthConfig {
  static String get googleSignInClientId => 
      DefaultFirebaseOptions.currentPlatform.googleSignInClientId;
  
  static const List<String> scopes = ['email', 'profile'];
}
```

### `firebase_options.dart`
**Configuración generada por FlutterFire CLI**
- Configuraciones de Firebase por plataforma
- API Keys y Project IDs
- Client IDs para diferentes plataformas
- Configuraciones de servicios Firebase

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.web:
        return web;
      // ... otras plataformas
    }
  }
}
```

## 🏗️ Arquitectura de Configuración

### Jerarquía de Configuraciones
```
app_config.dart           # Configuraciones generales de app
    ↓
oauth_config.dart         # Configuraciones específicas de OAuth
    ↓                     # (obtiene datos de firebase_options.dart)
firebase_options.dart     # Configuraciones base de Firebase
```

### Patrón de Proxy Configuration
```dart
// ✅ Correcto - OAuthConfig actúa como proxy
class OAuthConfig {
  static String get googleSignInClientId => 
      DefaultFirebaseOptions.currentPlatform.googleSignInClientId;
}

// ❌ Evitar - Duplicación de configuraciones
class OAuthConfig {
  static const String googleSignInClientId = '123456789...'; // Duplicado
}
```

## 🔧 Convenciones de Uso

### Variables de Entorno
```dart
// ✅ Usar const constructor para variables de build-time
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: 'https://api.sellweb.dev'
  );
}

// Uso en comandos de build
// flutter build web --dart-define=API_URL=https://api.sellweb.prod
```

### Configuraciones por Ambiente
```dart
enum Environment { dev, staging, prod }

class AppConfig {
  static Environment get currentEnvironment {
    switch (const String.fromEnvironment('ENV')) {
      case 'staging':
        return Environment.staging;
      case 'prod':
        return Environment.prod;
      default:
        return Environment.dev;
    }
  }
  
  static bool get isProduction => currentEnvironment == Environment.prod;
  static bool get enableLogging => !isProduction;
}
```

### Feature Flags
```dart
class FeatureFlags {
  static const bool enableNewCheckout = bool.fromEnvironment(
    'ENABLE_NEW_CHECKOUT', 
    defaultValue: false
  );
  
  static const bool enableDarkMode = bool.fromEnvironment(
    'ENABLE_DARK_MODE', 
    defaultValue: true
  );
}
```

## 🔒 Seguridad y Mejores Prácticas

### Manejo de Credenciales
```dart
// ✅ Correcto - Credenciales desde variables de entorno
class ApiConfig {
  static const String apiKey = String.fromEnvironment('API_KEY');
  
  static String get authHeader {
    assert(apiKey.isNotEmpty, 'API_KEY debe estar configurada');
    return 'Bearer $apiKey';
  }
}

// ❌ Evitar - Credenciales hardcodeadas
class ApiConfig {
  static const String apiKey = 'sk_live_123456789'; // ¡Nunca!
}
```

### Validación de Configuraciones
```dart
class ConfigValidator {
  static void validateConfig() {
    assert(AppConfig.apiUrl.isNotEmpty, 'API URL no configurada');
    assert(OAuthConfig.googleSignInClientId.isNotEmpty, 'Google Client ID no configurado');
    
    if (AppConfig.isProduction) {
      assert(!AppConfig.enableDebugFeatures, 'Debug features habilitadas en producción');
    }
  }
}
```

## 📚 Inicialización y Setup

### Orden de Inicialización
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Validar configuraciones
  ConfigValidator.validateConfig();
  
  // 2. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 3. Configurar servicios OAuth
  await GoogleSignIn.standard(
    clientId: OAuthConfig.googleSignInClientId,
  );
  
  // 4. Ejecutar app
  runApp(MyApp());
}
```

### Configuración Web Específica
```html
<!-- web/index.html -->
<meta name="google-signin-client_id" content="{{GOOGLE_CLIENT_ID}}">
<script>
  window.firebaseConfig = {
    // Configuraciones inyectadas en build time
  };
</script>
```

## ✅ Buenas Prácticas

1. **Single Source of Truth**: Una sola fuente para cada configuración
2. **Variables de Entorno**: Usar variables de entorno para configuraciones sensibles
3. **Validación Temprana**: Validar configuraciones al inicio de la app
4. **Documentación**: Documentar cada configuración y su propósito
5. **Separación por Contexto**: Agrupar configuraciones relacionadas
6. **Immutabilidad**: Usar `const` y `static` para configuraciones inmutables

## 🚫 Anti-patterns a Evitar

```dart
// ❌ Configuraciones mutables
class BadConfig {
  static String apiUrl = 'https://api.dev'; // Puede cambiar en runtime
}

// ❌ Configuraciones hardcodeadas sensibles
class BadConfig {
  static const String password = 'super_secret'; // ¡Nunca!
}

// ❌ Configuraciones dispersas
// Diferentes archivos con configuraciones no relacionadas entre sí
```

## 🔧 Comandos de Build

### Desarrollo
```bash
flutter run -d chrome --dart-define=ENV=dev
```

### Staging
```bash
flutter build web --dart-define=ENV=staging --dart-define=API_URL=https://api.staging.sellweb.com
```

### Producción
```bash
flutter build web --dart-define=ENV=prod --dart-define=API_URL=https://api.sellweb.com --dart-define=ENABLE_DEBUG_FEATURES=false
```

---

💡 **Tip**: Nunca commitear credenciales reales en el repositorio. Usar variables de entorno y archivos de configuración locales para desarrollo.
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
