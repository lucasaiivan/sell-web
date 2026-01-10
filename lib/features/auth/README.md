# Feature: Auth

## 📋 Propósito
Gestiona la **autenticación y autorización** de usuarios en la aplicación, incluyendo login, gestión de sesiones, creación de cuentas de negocio, y control de acceso multi-usuario.

## 🎯 Responsabilidades
- Autenticación de usuarios (Google OAuth)
- Gestión de sesiones y tokens
- **Creación y gestión de cuentas de negocio**
- **Sistema de permisos y roles granulares**
- Selección de cuenta activa
- Control de acceso multi-colección

---

## 🏗️ Estructura

```
auth/
├── domain/
│   ├── entities/          # AccountProfile, AdminProfile, AuthProfile
│   ├── repositories/      # AuthRepository (contracts)
│   └── usecases/          
│       ├── GetUserAccountsUseCase
│       ├── CreateBusinessAccountUseCase
│       ├── UpdateBusinessAccountUseCase
│       └── SaveSelectedAccountIdUseCase
├── data/
│   ├── models/            # Models con serialización Firestore
│   │   ├── AccountProfileModel
│   │   ├── AdminProfileModel
│   │   └── AuthProfileModel
│   └── repositories/      # AuthRepositoryImpl
└── presentation/
    ├── providers/         # AuthProvider (ChangeNotifier)
    ├── views/             # AccountBusinessView
    ├── pages/             # AppPresentationPage
    └── dialogs/           # Account selection, Admin info
```

---

## 🔐 Lógica de Negocio: Creación de Cuenta

### Criterios y Validaciones

Para crear una nueva cuenta de negocio, se deben cumplir los siguientes criterios:

#### ✅ Validaciones Pre-Creación (UseCase)

1. **Usuario Autenticado**
   - Debe existir un usuario autenticado con Firebase Auth
   - El usuario debe tener un email válido
   - Si no: `ServerFailure('No hay un usuario autenticado...')`

2. **Nombre del Negocio**
   - No puede estar vacío (`trim().isEmpty`)
   - Si falla: `ValidationFailure('El nombre del negocio es requerido')`

3. **Moneda**
   - Debe seleccionar una moneda (`currencySign` no vacío)
   - Si falla: `ValidationFailure('Debe seleccionar una moneda')`

4. **Owner ID**
   - Debe existir el ID del propietario
   - Este se obtiene automáticamente del usuario autenticado
   - Si falla: `ValidationFailure('Error: No se pudo identificar al propietario')`

#### 📝 Campos Opcionales

- `country`, `province`, `town`: Ubicación del negocio

---

### 🔄 Proceso de Creación (Atomic Multi-Collection)

El proceso de creación utiliza **Firestore WriteBatch** para garantizar atomicidad.

#### Pasos de Creación:

```dart
1. Generar ID único del tipo Firestore (IdGenerator.generateAccountId())
2. Crear AccountProfile con el ID generado
3. Crear AdminProfile del usuario creador:
   - superAdmin: true (por defecto)
   - admin: true
   - permissions: [todos los permisos granulares]
   - email: email del usuario autenticado
   - id: uid de Firebase Auth
   
4. Escribir 3 documentos en batch (atómicamente):
   ├─ /ACCOUNTS/{accountId}              → Datos de la cuenta
   ├─ /ACCOUNTS/{accountId}/USERS/{email} → Perfil admin en la cuenta
   └─ /USERS/{email}/ACCOUNTS/{accountId}  → Identificación de acceso
   
5. Commit del batch
```

#### 🗄️ Estructura en Firestore

```
/ACCOUNTS/{accountId}
{
  id: "Xk2jP9mL5n...",
  name: "Mi Tienda",
  currencySign: "AR$",
  country: "Argentina",
  province: "Buenos Aires",
  town: "CABA",
  ownerId: "firebase_uid_123",
  creation: Timestamp,
  trialStart: Timestamp,
  trialEnd: Timestamp,
  // ... otros campos
}

/ACCOUNTS/{accountId}/USERS/{email}
{
  id: "firebase_uid_123",
  email: "user@example.com",
  name: "John Doe",
  account: "{accountId}",
  superAdmin: true,
  admin: true,
  personalized: false,
  permissions: ["createCashCount", "manageCatalogue", ...],
  creation: Timestamp,
  lastUpdate: Timestamp,
  // ... otros campos de AdminProfile
}

/USERS/{email}/ACCOUNTS/{accountId}
{
  // Copia exacta del AdminProfile anterior
  // Permite al usuario descubrir sus cuentas rápidamente
}
```

---

## 👥 Sistema de Roles y Permisos

### Jerarquía de Roles

1. **Super Admin** (`superAdmin: true`)
   - Creador de la cuenta
   - Acceso total e irrevocable
   - Puede gestionar otros usuarios

2. **Admin** (`admin: true`)
   - Acceso completo a todas las funcionalidades
   - Puede gestionar usuarios (si tiene permiso `manageUsers`)

3. **Usuario Personalizado** (`personalized: true`)
   - Solo tiene acceso a permisos específicamente otorgados
   - Lista de permisos en campo `permissions: [...]`

### Permisos Granulares (`AdminPermission` enum)

| Permiso | Descripción |
|---------|-------------|
| `createCashCount` | Crear arqueo de caja |
| `viewCashCountHistory` | Ver historial de arqueos |
| `manageTransactions` | Gestionar transacciones |
| `manageCatalogue` | Gestionar catálogo de productos |
| `manageUsers` | Gestionar usuarios (multiusuario) |
| `manageAccount` | Editar configuración de cuenta |
| `registerSales` | Registrar ventas en el POS |
| `dashboardAnalytics` | Ver analytics del dashboard |

### Verificación de Permisos

```dart
// En la entidad AdminProfile
bool hasPermission(AdminPermission permission) {
  if (superAdmin || admin) return true; // Acceso total
  if (personalized) {
    return permissions.contains(permission.name);
  }
  return false;
}

// Uso
if (currentAdmin.hasPermission(AdminPermission.manageCatalogue)) {
  // Mostrar opción de catálogo
}
```

---

## 🔄 Flujo de Usuario: Creación de Cuenta

```
1. Usuario autenticado con Google
   ↓
2. Navega a "Crear Cuenta"
   ↓
3. Completa formulario:
   - Nombre del negocio (requerido)
   - Moneda (requerido)
   - Ubicación (opcional)
   ↓
4. Presiona "Guardar"
   ↓
5. Vista de éxito (CreationSuccessView):
   - "Creando cuenta espere un momento..." (1.5s)
   - Animación de check + "¡Cuenta creada!" (2s)
   ↓
6. En segundo plano:
   - Se ejecuta CreateBusinessAccountUseCase
   - Se validan los datos
   - Se crea la cuenta atómicamente (3 documentos)
   - Se guarda como cuenta seleccionada
   ↓
7. Redirección automática a HomePage
   ↓
8. Usuario ahora es SuperAdmin de su cuenta
```

---

## 📦 Dependencias

### Externas
- `firebase_auth` - Autenticación
- `cloud_firestore` - Base de datos
- `google_sign_in` - OAuth con Google

### Internas
- `core/services/database/firestore_paths.dart` - Rutas centralizadas
- `core/utils/helpers/id_generator.dart` - Generación de IDs
- `core/presentation/widgets/success/` - Vista de éxito
- `core/errors/failures.dart` - Manejo de errores

---

## 🛠️ Casos de Uso Principales

### 1. `CreateBusinessAccountUseCase`
**Input:** `AccountProfile` (sin ID, se genera automáticamente)  
**Output:** `Either<Failure, AccountProfile>`  
**Responsabilidad:** Validar y crear cuenta con accesos

### 2. `GetUserAccountsUseCase`
**Input:** Email del usuario  
**Output:** Lista de `AccountProfile`  
**Responsabilidad:** Obtener cuentas administradas por el usuario

### 3. `UpdateBusinessAccountUseCase`
**Input:** `AccountProfile` actualizado  
**Output:** `Either<Failure, void>`  
**Responsabilidad:** Actualizar datos de cuenta existente

### 4. `SaveSelectedAccountIdUseCase`
**Input:** ID de cuenta  
**Output:** `Either<Failure, void>`  
**Responsabilidad:** Guardar cuenta seleccionada en preferencias

---

## 📱 Páginas y Vistas

### `AppPresentationPage`
Pantalla de bienvenida y login

### `AccountBusinessView`
Formulario de creación/edición de cuenta
- Modo creación: Sin ID
- Modo edición: Con ID existente

### `CreationSuccessView`
Vista de confirmación con animación

---

## 🔍 Provider Principal

### `AuthProvider`

**Estado:**
```dart
- AuthProfile? authProfile          // Usuario autenticado
- AccountProfile? profileSelected   // Cuenta activa
- List<AccountProfile> accountsAssociateds  // Cuentas del usuario
- AdminProfile? currentAdminProfile // Perfil con permisos
- bool isLoading
- String? authError
```

**Métodos clave:**
```dart
- Future<void> signInWithGoogle()
- Future<void> signOut()
- Future<bool> createBusinessAccount(AccountProfile)
- Future<bool> updateBusinessAccount(AccountProfile, AdminProfile)
- Future<void> loadAccountsOfUser(String email)
- Future<void> setSelectedAccount(AccountProfile)
```

---

## 🎯 Navegación

**Flujo de autenticación:**
```
Sin autenticar → AppPresentationPage (Login)
              ↓ (Google Sign-In exitoso)
          AuthProvider detecta usuario
              ↓
      Carga cuentas del usuario
              ↓
         HomePage (con cuenta seleccionada)
```

**Flujo de creación:**
```
HomePage → AccountBusinessView (modo creación)
        → CreationSuccessView
        → HomePage (cuenta nueva seleccionada)
```

---

## ✅ Clean Architecture

✅ **Domain puro** - Sin dependencias de Flutter  
✅ **Data layer** - Implementación con Firebase  
✅ **Presentation** - UI con Provider pattern  
✅ **DI** - Injectable con get_it  
✅ **Atomic operations** - WriteBatch para consistencia  
✅ **Type-safe paths** - FirestorePaths centralizado

---

## 🚨 Manejo de Errores

### Tipos de Failure

| Failure | Cuándo ocurre |
|---------|---------------|
| `ValidationFailure` | Datos inválidos (nombre vacío, etc.) |
| `ServerFailure` | Usuario no autenticado, error de Firebase Auth |
| `FirestoreFailure` | Error al escribir/leer de Firestore |

### Propagación

```
UseCase → fold(
  (failure) => Provider actualiza authError,
  (success) => Provider actualiza estado
)
```

---

## 📚 Documentación Relacionada

- `/core/services/database/firestore_paths.dart` - Estructura de rutas
- `/features/multiuser/` - Gestión de usuarios adicionales
- `/core/presentation/widgets/success/README.md` - Vista de éxito reutilizable
