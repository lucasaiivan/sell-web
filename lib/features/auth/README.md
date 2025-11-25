# Feature: Auth

## Propósito
Gestiona la **autenticación y autorización** de usuarios en la aplicación, incluyendo login, gestión de sesiones, y selección de cuentas.

## Responsabilidades
- Autenticación de usuarios (login/logout)
- Gestión de sesiones y tokens
- Permisos y roles de usuario
- Selección de cuenta activa
- Información de perfil de administrador

## Estructura

```
auth/
├── domain/
│   ├── entities/          # AccountProfile
│   ├── repositories/      # Contratos de repositorios
│   └── usecases/          # GetUserAccountsUseCase
├── data/
│   ├── models/            # DTOs para Firebase
│   ├── datasources/       # Firebase Auth datasource
│   └── repositories/      # Implementaciones
└── presentation/
    ├── providers/         # AuthProvider (ChangeNotifier)
    ├── pages/             # LoginPage, WelcomeSelectedAccountPage
    ├── widgets/           # LoginForm
    └── dialogs/           # AccountSelectionDialog, AdminProfileInfoDialog
```

## Dependencias

### Externas
- Firebase Authentication
- Cloud Firestore

### Internas
- `core/services/` - Theme, storage
- `core/presentation/widgets/` - Shared UI components

## Provider Principal

### `AuthProvider`
**Responsabilidad:** Gestionar estado de autenticación y cuentas

**Inyección de Dependencias:**
```dart
@injectable
class AuthProvider extends ChangeNotifier {
  final GetUserAccountsUseCase _getUserAccountsUseCase;
  // ...
}
```

**Uso:**
```dart
final authProvider = context.watch<AuthProvider>();
authProvider.login(email, password);
```

## Páginas Principales

1. **LoginPage** - Formulario de autenticación
2. **WelcomeSelectedAccountPage** - Selección de cuenta después del login

## Diálogos

1. **AccountSelectionDialog** - Selector de múltiples cuentas
2. **AdminProfileInfoDialog** - Información del administrador

## Navegación

**Entrada:** App inicio (unauthenticated) → LoginPage
**Salida:** Login exitoso → HomePage (feature home)

## Clean Architecture

✅ **Domain puro** - Sin dependencias de Flutter
✅ **Data layer** - Implementación con Firebase
✅ **Presentation** - UI con Provider pattern
✅ **DI** - Injectable con get_it
