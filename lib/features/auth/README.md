# Feature: Auth 🔐

**Módulo de Autenticación y Gestión de Cuentas**

Este feature implementa toda la lógica de autenticación de usuarios, gestión de perfiles y cuentas administrativas utilizando **Clean Architecture** con **Firebase Authentication** y **Firestore**.

---

## 📋 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Arquitectura](#-arquitectura)
- [Estructura del Feature](#-estructura-del-feature)
- [Componentes Principales](#-componentes-principales)
- [Flujo de Autenticación](#-flujo-de-autenticación)
- [Casos de Uso](#-casos-de-uso)
- [Entidades de Dominio](#-entidades-de-dominio)
- [Integración](#-integración)
- [Configuración](#-configuración)

---

## 🎯 Descripción General

El feature **Auth** proporciona:
- ✅ Autenticación con **Google Sign-In**
- ✅ Autenticación **Anónima** (modo invitado)
- ✅ **Sign-in silencioso** para sesiones persistentes
- ✅ Gestión de **múltiples cuentas** administrativas por usuario
- ✅ Persistencia de **perfil seleccionado** localmente
- ✅ **Modo Demo** con datos de prueba para usuarios invitados
- ✅ Stream reactivo del estado de autenticación

---

## 🏛️ Arquitectura

### Clean Architecture - 3 Capas

```
lib/features/auth/
├── domain/          # Lógica de negocio pura (sin dependencias externas)
├── data/            # Implementaciones con Firebase/Firestore
└── presentation/    # UI y state management con Provider
```

### Principios Aplicados

- **Dependency Inversion**: Domain define contratos, Data los implementa
- **Single Responsibility**: Cada UseCase tiene una responsabilidad clara
- **Dependency Injection**: GetIt + Injectable para todas las dependencias
- **Immutability**: Entidades inmutables con `copyWith()`
- **Reactive Programming**: Streams para estado de autenticación

---

## 📁 Estructura del Feature

```
lib/features/auth/
│
├── data/                                    # Capa de Datos
│   ├── models/                              # DTOs con conversión Firestore
│   │   ├── auth_profile_model.dart          # DTO para AuthProfile
│   │   ├── admin_profile_model.dart         # DTO para AdminProfile
│   │   └── account_profile_model.dart       # DTO para AccountProfile
│   └── repositories/                        # Implementaciones de repositorios
│       ├── auth_repository_impl.dart        # @LazySingleton - Firebase Auth
│       └── account_repository_impl.dart     # @LazySingleton - Firestore
│
├── domain/                                  # Capa de Dominio
│   ├── entities/                            # Entidades puras inmutables
│   │   ├── auth_profile.dart                # Perfil básico del usuario autenticado
│   │   ├── admin_profile.dart               # Perfil admin con email y rol
│   │   └── account_profile.dart             # Cuenta completa con trial y config
│   ├── repositories/                        # Contratos (interfaces abstractas)
│   │   ├── auth_repository.dart             # Contrato de autenticación
│   │   └── account_repository.dart          # Contrato de gestión de cuentas
│   └── usecases/                            # Casos de uso (@lazySingleton)
│       ├── sign_in_with_google_usecase.dart # Login con Google
│       ├── sign_in_silently_usecase.dart    # Login silencioso
│       ├── sign_in_anonymously_usecase.dart # Login anónimo
│       ├── sign_out_usecase.dart            # Cerrar sesión
│       ├── get_user_stream_usecase.dart     # Stream reactivo del usuario
│       └── get_user_accounts_usecase.dart   # Gestión de cuentas y perfiles
│
├── presentation/                            # Capa de Presentación
│   ├── providers/
│   │   └── auth_provider.dart               # @injectable - State management
│   ├── pages/
│   │   └── login_page.dart                  # Página de inicio de sesión
│   └── widgets/
│       ├── login_form.dart                  # Formulario de autenticación
│       └── onboarding_introduction_app.dart # Introducción de la app
│
└── README.md                                # 📄 Esta documentación
```

---

## 🧩 Componentes Principales

### 1. AuthProvider (@injectable)

**Responsabilidad:** Coordinar UI y casos de uso de autenticación.

```dart
@injectable
class AuthProvider extends ChangeNotifier {
  // Estado del usuario autenticado
  AuthProfile? _user;
  List<AccountProfile> _accountsAssociateds = [];
  
  // Estados de carga
  bool _isSigningInWithGoogle = false;
  bool _isSigningInAsGuest = false;
  bool _isLoadingAccounts = false;
  
  // Métodos principales
  Future<void> signInWithGoogle();
  Future<void> signInAsGuest();
  Future<void> signOut();
  Future<void> getUserAssociatedAccount(String email);
}
```

**Inyección en `main.dart`:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => getIt<AuthProvider>(),
    ),
  ],
)
```

### 2. Repositorios

#### AuthRepository (Contrato)
```dart
abstract class AuthRepository {
  Future<AuthProfile?> signInWithGoogle();
  Future<AuthProfile?> signInSilently();
  Future<AuthProfile?> signInAnonymously();
  Future<void> signOut();
  Stream<AuthProfile?> get user;
}
```

#### AccountRepository (Contrato)
```dart
abstract class AccountRepository {
  Future<List<AdminProfile>> getUserAccounts(String email);
  Future<AccountProfile?> getAccount(String accountId);
  Future<void> saveSelectedAccountId(String accountId);
  Future<String?> getSelectedAccountId();
  Future<void> removeSelectedAccountId();
}
```

### 3. Casos de Uso

Todos los UseCases están anotados con `@lazySingleton` para ser inyectados automáticamente.

| UseCase | Responsabilidad | Dependencias |
|---------|----------------|--------------|
| `SignInWithGoogleUseCase` | Login con cuenta de Google | `AuthRepository` |
| `SignInSilentlyUseCase` | Login silencioso automático | `AuthRepository` |
| `SignInAnonymouslyUseCase` | Login como invitado | `AuthRepository` |
| `SignOutUseCase` | Cerrar sesión | `AuthRepository` |
| `GetUserStreamUseCase` | Stream reactivo del usuario | `AuthRepository` |
| `GetUserAccountsUseCase` | Gestionar cuentas y perfiles | `AccountRepository`, `AppDataPersistenceService` |

---

## 🔄 Flujo de Autenticación

### 1. Login con Google

```
Usuario → LoginPage → AuthProvider.signInWithGoogle()
  → SignInWithGoogleUseCase(AuthRepository)
  → AuthRepositoryImpl (Firebase Auth + Google Sign-In)
  → AuthProfile retornado
  → getUserAssociatedAccount(email)
  → GetUserAccountsUseCase.getProfilesAccountsAssociated()
  → AccountRepositoryImpl (Firestore: user_roles, accounts)
  → List<AccountProfile> cargada
  → UI actualizada con cuentas disponibles
```

### 2. Login Silencioso (Auto-login)

```
App Startup → AuthProvider constructor
  → GetUserStreamUseCase.call() (Stream<AuthProfile?>)
  → AuthRepositoryImpl.user (Firebase Auth State Stream)
  → Si user != null: getUserAssociatedAccount(email)
  → Carga automática de cuentas asociadas
```

### 3. Login como Invitado

```
Usuario → LoginPage → AuthProvider.signInAsGuest()
  → SignInAnonymouslyUseCase(AuthRepository)
  → AuthRepositoryImpl.signInAnonymously() (Firebase Anonymous Auth)
  → AuthProfile con isAnonymous: true
  → No carga cuentas (invitado no tiene cuentas)
  → Usuario puede explorar con datos demo
```

---

## 📦 Casos de Uso

### GetUserAccountsUseCase

**El caso de uso más complejo del feature**, gestiona múltiples operaciones:

#### Métodos Principales

```dart
@lazySingleton
class GetUserAccountsUseCase {
  // Obtener todas las cuentas asociadas a un usuario
  Future<List<AccountProfile>> getProfilesAccountsAssociated(String email);
  
  // Obtener una cuenta específica por ID
  Future<AccountProfile> getAccount({required String idAccount});
  
  // Gestión de cuenta seleccionada (persistencia local)
  Future<void> saveSelectedAccountId(String accountId);
  Future<String?> getSelectedAccountId();
  Future<void> removeSelectedAccountId();
  
  // Cargar/guardar AdminProfile localmente
  Future<AdminProfile?> loadAdminProfile();
  Future<void> saveAdminProfile(AdminProfile adminProfile);
  
  // Datos demo para usuarios invitados
  List<AccountProfile> getAccountsWithDemo(List<AccountProfile> accounts, bool isGuest);
  AdminProfile getDemoAdminProfile();
  List<Product> getDemoProducts();
}
```

#### Flujo Complejo: getProfilesAccountsAssociated()

```
1. Obtener AdminProfiles del usuario desde Firestore (colección: user_roles)
   → Query: user_roles where email == userEmail
   → Retorna: List<AdminProfile> con {email, account, role}

2. Para cada AdminProfile:
   → Obtener AccountProfile completo desde Firestore (colección: accounts)
   → Document: accounts/{accountId}
   → Retorna: AccountProfile completo con config, trial, etc.

3. Si usuario es invitado:
   → Agregar cuenta demo con getAccountsWithDemo()

4. Guardar AdminProfile localmente con saveAdminProfile()

5. Retornar: List<AccountProfile> completa
```

---

## 🧱 Entidades de Dominio

### AuthProfile

**Perfil básico del usuario autenticado (de Firebase Auth).**

```dart
class AuthProfile {
  final String? uid;           // ID único del usuario
  final String? email;         // Email de autenticación
  final String? displayName;   // Nombre para mostrar
  final bool? isAnonymous;     // true si es usuario invitado
  final String? photoUrl;      // URL de foto de perfil
}
```

**Uso:**
```dart
// Verificar si usuario está autenticado
if (authProvider.user != null) {
  // Usuario autenticado
}

// Verificar si es invitado
if (authProvider.isGuest) {
  // Mostrar modo demo
}
```

### AdminProfile

**Perfil administrativo del usuario (relación N:N con cuentas).**

```dart
class AdminProfile {
  final String email;           // Email del administrador
  final String account;         // ID de la cuenta que administra
  final String role;            // Rol: 'admin', 'owner', 'employee'
  final DateTime? creation;     // Fecha de creación
  final DateTime? lastUpdate;   // Última actualización
}
```

**Colección Firestore:** `user_roles`

**Estructura:**
```firestore
user_roles/
  {docId}/
    email: "user@example.com"
    account: "account123"
    role: "admin"
    creation: Timestamp
    lastUpdate: Timestamp
```

### AccountProfile

**Cuenta completa con configuración y trial.**

```dart
class AccountProfile {
  final String id;                    // ID de la cuenta
  final String accountName;           // Nombre de la cuenta
  final bool isActive;                // Estado de la cuenta
  final DateTime? creation;           // Fecha de creación
  final DateTime? trialStart;         // Inicio del trial
  final DateTime? trialEnd;           // Fin del trial
  final bool isPaid;                  // Si está en plan pago
  final Map<String, dynamic>? config; // Configuración personalizada
}
```

**Colección Firestore:** `accounts`

**Estructura:**
```firestore
accounts/
  {accountId}/
    accountName: "Mi Tienda"
    isActive: true
    creation: Timestamp
    trialStart: Timestamp
    trialEnd: Timestamp
    isPaid: false
    config: {
      currency: "USD",
      timezone: "America/Mexico_City",
      // ... más configuraciones
    }
```

---

## 🔌 Integración

### 1. Configurar Dependency Injection

Todas las dependencias están registradas automáticamente con `@injectable` y `@lazySingleton`.

**Regenerar código DI cuando agregues nuevos componentes:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. Usar AuthProvider en UI

```dart
// Acceder al estado de autenticación
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.user == null) {
      return LoginPage();
    }
    
    if (authProvider.isLoadingAccounts) {
      return CircularProgressIndicator();
    }
    
    return HomePage(
      accounts: authProvider.accountsAssociateds,
    );
  },
)
```

### 3. Ejecutar Acciones de Autenticación

```dart
// Login con Google
await context.read<AuthProvider>().signInWithGoogle();

// Login como invitado
await context.read<AuthProvider>().signInAsGuest();

// Cerrar sesión
await context.read<AuthProvider>().signOut();

// Cargar cuentas manualmente
await context.read<AuthProvider>()
  .getUserAssociatedAccount(user.email!);
```

### 4. Acceder a UseCases Directamente

Si necesitas acceder a UseCases fuera del AuthProvider:

```dart
// Obtener instancia del contenedor DI
final getUserAccountsUseCase = getIt<GetUserAccountsUseCase>();

// Usar el caso de uso
final accounts = await getUserAccountsUseCase
  .getProfilesAccountsAssociated(email);
```

---

## ⚙️ Configuración

### Firebase Authentication

**Métodos habilitados en Firebase Console:**
- ✅ Google Sign-In
- ✅ Anonymous Authentication

**OAuth Config:** `lib/core/config/oauth_config.dart`

### Firestore Collections

**Requeridas para el feature Auth:**

#### `user_roles` (AdminProfile)
```
Indexes:
  - email (ascending)
  - account (ascending)

Security Rules:
  - Read: authenticated users
  - Write: admin users only
```

#### `accounts` (AccountProfile)
```
Indexes:
  - isActive (ascending)
  - creation (descending)

Security Rules:
  - Read: authenticated users with admin role
  - Write: account owners only
```

### Persistencia Local

**SharedPreferences keys:** `lib/core/constants/shared_prefs_keys.dart`

```dart
class SharedPrefsKeys {
  static const String selectedAccountId = 'selected_account_id';
  static const String adminProfile = 'admin_profile';
}
```

---

## 🐛 Fix Importante: Conversión Timestamp

**Problema resuelto:** Firestore retorna `Timestamp`, pero las entidades esperaban `DateTime`.

**Solución aplicada en modelos:**

```dart
// AdminProfileModel.fromDocument()
creation: data.containsKey("creation")
  ? (doc["creation"] is Timestamp 
      ? (doc["creation"] as Timestamp).toDate() 
      : doc["creation"] as DateTime)
  : DateTime.now()
```

Esta **conversión defensiva** se aplica en:
- ✅ `AdminProfileModel`: `creation`, `lastUpdate`
- ✅ `AccountProfileModel`: `creation`, `trialStart`, `trialEnd`

---

## ✅ Estado del Feature

- ✅ **Arquitectura Clean**: Implementación completa con 3 capas
- ✅ **Dependency Injection**: GetIt + Injectable configurado
- ✅ **Bug Timestamp**: Corregido con conversión defensiva
- ✅ **Testing**: Compatible con mocks para testing unitario
- ✅ **Documentación**: README completo
- ✅ **Sin archivos legacy**: Migración completa finalizada

---

## 📚 Referencias

- **Firebase Auth**: [Documentación oficial](https://firebase.google.com/docs/auth)
- **Clean Architecture**: [Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- **Injectable**: [Package documentation](https://pub.dev/packages/injectable)
- **Provider**: [Package documentation](https://pub.dev/packages/provider)

---

## 🤝 Contribución

Al modificar este feature:

1. **Mantén Clean Architecture**: Respeta la separación de capas
2. **Usa Dependency Injection**: Anota con `@injectable` o `@lazySingleton`
3. **Regenera DI**: Ejecuta `build_runner` después de cambios
4. **Documenta cambios**: Actualiza este README si es necesario
5. **Testing**: Agrega tests unitarios en `test/features/auth/`

---

**Última actualización:** 25 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Producción
