# Feature: Multiuser 👥

**Sistema de gestión de múltiples usuarios con control de permisos granulares**

## 🎯 Descripción

El feature **Multiuser** permite la gestión completa de usuarios asociados a una cuenta. Proporciona funcionalidades CRUD (crear, leer, actualizar, eliminar) sobre perfiles de administrador, con un sistema de permisos que controla el acceso a diferentes módulos de la aplicación.

Este módulo está diseñado siguiendo Clean Architecture con separación en capas de dominio, datos y presentación, permitiendo una gestión escalable y mantenible de usuarios con roles personalizados.

## 📦 Componentes Principales

### Entities
- `AdminProfile`: Entidad de dominio que representa un usuario administrador con sus permisos y configuraciones (definida en `features/auth/domain/entities/admin_profile.dart`)

### Use Cases
- `GetUsersUseCase`: Obtiene el stream de usuarios asociados a una cuenta
- `CreateUserUseCase`: Crea un nuevo usuario con sus permisos
- `UpdateUserUseCase`: Actualiza la información y permisos de un usuario existente
- `DeleteUserUseCase`: Elimina un usuario de la cuenta

### Repositories
- `MultiUserRepository` (contract): Define las operaciones disponibles para la gestión de usuarios
- `MultiUserRepositoryImpl`: Implementación del repositorio utilizando Firestore como fuente de datos

### Providers
- `MultiUserProvider`: Gestiona el estado de la UI, coordina los casos de uso y maneja permisos del usuario actual

### Data Sources
- `MultiUserRemoteDataSource`: Maneja la comunicación directa con Firestore para operaciones CRUD de usuarios

## 🔄 Flujos Principales

### Flujo 1: Cargar Usuarios
```
Usuario → MultiUserPage → MultiUserProvider.loadUsers()
    → GetUsersUseCase → MultiUserRepository → MultiUserRemoteDataSource
    → Firestore Stream → UI actualizada automáticamente
```

### Flujo 2: Crear Usuario
```
Usuario → UserAdminDialog → MultiUserProvider.createUser()
    → CreateUserUseCase → MultiUserRepository → MultiUserRemoteDataSource
    → Firestore.add() → Success/Error → UI feedback
```

### Flujo 3: Actualizar/Eliminar Usuario
```
Usuario → Acción (Edit/Delete) → MultiUserProvider.updateUser()/deleteUser()
    → UpdateUserUseCase/DeleteUserUseCase → MultiUserRepository
    → Firestore.update()/delete() → Success/Error → UI actualizada
```

## 🔌 Integración

### Registro en DI
```dart
// Automático con @lazySingleton y @injectable
// Ver: core/di/injection_container.config.dart

// Datasource
@lazySingleton
class MultiUserRemoteDataSourceImpl implements MultiUserRemoteDataSource { }

// Repository
@LazySingleton(as: MultiUserRepository)
class MultiUserRepositoryImpl implements MultiUserRepository { }

// Use Cases
@lazySingleton
class GetUsersUseCase { }

// Provider
@injectable
class MultiUserProvider extends ChangeNotifier { }
```

### Uso en UI
```dart
// En main.dart o routing
ChangeNotifierProvider(
  create: (_) => getIt<MultiUserProvider>()..loadUsers(),
  child: MultiUserPage(),
)

// En widgets
Consumer<MultiUserProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading) return CircularProgressIndicator();
    if (provider.errorMessage != null) return ErrorWidget();
    
    return ListView.builder(
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return UserTile(user: user);
      },
    );
  },
)
```

## ⚙️ Configuración

### Permisos Disponibles
El sistema maneja los siguientes permisos granulares (definidos en `AdminProfile`):
- `superAdmin`: Acceso total sin restricciones
- `admin`: Administrador estándar
- `personalized`: Permite permisos personalizados
- `multiuser`: Gestión de usuarios (requerido para CRUD de usuarios)
- `catalogue`: Gestión del catálogo de productos
- `transactions`: Ver y gestionar transacciones
- `historyArqueo`: Ver historial de arqueos de caja
- `arqueo`: Realizar arqueos de caja
- `editAccount`: Editar configuración de la cuenta

### Estructura en Firestore
```
ACCOUNTS/{accountId}/ADMINS/{userId}
  - id: string
  - email: string
  - name: string
  - superAdmin: bool
  - admin: bool
  - personalized: bool
  - multiuser: bool
  - catalogue: bool
  - transactions: bool
  - (otros permisos...)
  - inactivate: bool
  - creation: Timestamp
  - lastUpdate: Timestamp
```

## 🛡️ Control de Acceso

El `MultiUserProvider` verifica automáticamente si el usuario actual tiene el permiso `multiuser` antes de mostrar opciones de creación/edición:

```dart
// Verificación en provider
bool get canCreateUsers => _currentUser?.multiuser ?? false;

// Uso en UI
if (provider.canCreateUsers) {
  return FloatingActionButton(
    onPressed: () => showUserDialog(),
    child: Icon(Icons.person_add),
  );
}
```

## 📂 Estructura de Carpetas

```
multiuser/
├── data/
│   ├── datasources/
│   │   └── multi_user_remote_datasource.dart
│   └── repositories/
│       └── multi_user_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── multi_user_repository.dart
│   └── usecases/
│       ├── create_user_usecase.dart
│       ├── delete_user_usecase.dart
│       ├── get_users_usecase.dart
│       └── update_user_usecase.dart
└── presentation/
    ├── pages/
    │   └── multi_user_page.dart
    ├── provider/
    │   └── multi_user_provider.dart
    └── widgets/
        └── (componentes específicos de UI)
```

## ✅ Estado

- ✅ Arquitectura Clean implementada
- ✅ CRUD completo de usuarios
- ✅ Sistema de permisos granulares
- ✅ Stream reactivo desde Firestore
- ✅ Control de acceso basado en permisos
- ✅ Dependency Injection configurado
- ✅ UI con estados de loading/error
- 📋 Tests pendientes de implementar
- 📋 Documentación de widgets pendiente

## 🔗 Dependencias Externas

- `fpdart`: Para manejo funcional de errores con `Either<Failure, T>`
- `injectable`: Para inyección de dependencias
- `cloud_firestore`: Base de datos en tiempo real
- Feature `auth`: Para entidades `AdminProfile` y gestión de cuentas

## 📝 Notas Técnicas

1. **Stream en tiempo real**: Los usuarios se actualizan automáticamente cuando hay cambios en Firestore
2. **Gestión de suscripciones**: El provider cancela correctamente las suscripciones en `dispose()`
3. **Validación de permisos**: Se verifica el permiso `multiuser` antes de permitir operaciones
4. **Error handling**: Todos los casos de uso retornan `Either<Failure, T>` para manejo consistente de errores

---

**Última actualización:** 28 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ En producción
