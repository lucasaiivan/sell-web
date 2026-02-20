# 🔐 Sistema de Control de Acceso de Usuarios

## 📋 Descripción

Sistema de seguridad que valida el acceso de usuarios administradores según tres criterios:

1. **Estado de Usuario** - Usuario bloqueado/inactivado
2. **Días de Acceso** - Restricción por días de la semana
3. **Horario de Acceso** - Restricción por rango horario

## 🏗️ Arquitectura

### Componentes Principales

#### 1. **UserAccessValidator** (`core/utils/helpers/`)
Helper estático que valida el acceso del usuario.

**Responsabilidad:**
- Validar si un usuario tiene acceso permitido
- Retornar resultado con razón de denegación si aplica

**Uso:**
```dart
final accessResult = UserAccessValidator.validateAccess(adminProfile);
if (!accessResult.hasAccess) {
  print(accessResult.message);
}
```

#### 2. **AccessDeniedDialog** (`features/auth/presentation/dialogs/`)
Diálogo que informa al usuario por qué no tiene acceso.

**Características:**
- Muestra icono y mensaje según tipo de restricción
- Opciones: Cerrar Sesión o Cambiar de Cuenta
- No se puede cerrar tocando fuera (barrierDismissible: false)

**Uso:**
```dart
await AccessDeniedDialog.show(
  context: context,
  accessResult: accessResult,
  onSignOut: () async => await authProvider.signOut(),
  onChangeAccount: () async => sellProvider.cleanData(),
);
```

#### 3. **HomePage con Verificación Integrada**
Página principal con verificación de acceso automática.

**Características:**
- Verificación al iniciar (`initState`)
- Verificación periódica cada minuto (Timer)
- Verificación cuando cambia AdminProfile (`addPostFrameCallback`)
- Prevención de múltiples diálogos simultáneos

## 🔄 Flujo de Verificación

```
Usuario inicia sesión
    ↓
HomePage se monta
    ↓
Verifica AdminProfile actual
    ↓
UserAccessValidator.validateAccess()
    ↓
┌─────────────────┐
│ ¿Tiene acceso?  │
└─────┬───────┬───┘
      │       │
   ✅ Sí    ❌ No
      │       │
   Continuar │
            ↓
    AccessDeniedDialog
            ↓
    ┌───────────────┐
    │ Opciones:     │
    ├───────────────┤
    │ - Cerrar      │
    │   Sesión      │
    │ - Cambiar     │
    │   Cuenta      │
    └───────────────┘
```

## 📊 Estados de Verificación

### UserAccessDeniedReason

| Razón | Descripción | Icono |
|-------|-------------|-------|
| `none` | Acceso permitido | - |
| `userBlocked` | Usuario bloqueado por admin | 🚫 |
| `dayNotAllowed` | Día de semana no permitido | 📅 |
| `outsideAllowedHours` | Fuera del horario permitido | 🕒 |

## 🔒 Reglas de Validación

### 1. Super Administrador
✅ **Siempre tiene acceso completo**
- No se aplica ninguna restricción
- Bypass de todas las validaciones

### 2. Usuario Inactivado
❌ **Acceso denegado inmediato**
- Campo `inactivate: true`
- Bloqueo manual por administrador

### 3. Días de la Semana
❌ **Acceso denegado si día no permitido**
- Solo si `daysOfWeek` no está vacío
- Valida con `hasAccessDay`

### 4. Horario de Acceso
❌ **Acceso denegado si fuera de horario**
- Solo si tiene configuración de horario
- Valida con `hasAccessHour`

## 🔧 Configuración

### Timer de Verificación Periódica
```dart
_accessCheckTimer = Timer.periodic(
  const Duration(minutes: 1), // Ajustable según necesidad
  (_) => _checkUserAccess(),
);
```

### Prevención de Múltiples Diálogos
```dart
bool _isShowingAccessDeniedDialog = false;

if (!mounted || _isShowingAccessDeniedDialog) return;
```

## 📱 Comportamiento de UI

### Cambiar de Cuenta
```dart
onChangeAccount: () async {
  Navigator.of(context).pop(); // Cierra diálogo
  sellProvider.cleanData();    // Limpia datos de cuenta
  // Vuelve a WelcomeSelectedAccountPage
}
```

### Cerrar Sesión
```dart
onSignOut: () async {
  Navigator.of(context).pop();   // Cierra diálogo
  await authProvider.signOut();  // Cierra sesión Firebase
  // Vuelve a AppPresentationPage
}
```

## 🧪 Casos de Prueba

### Caso 1: Usuario Bloqueado
```dart
// Setup
final admin = AdminProfile(inactivate: true, ...);

// Test
final result = UserAccessValidator.validateAccess(admin);

// Assert
assert(!result.hasAccess);
assert(result.reason == UserAccessDeniedReason.userBlocked);
```

### Caso 2: Día No Permitido
```dart
// Setup (hoy es lunes)
final admin = AdminProfile(
  daysOfWeek: ['tuesday', 'wednesday'], 
  ...
);

// Test
final result = UserAccessValidator.validateAccess(admin);

// Assert
assert(!result.hasAccess);
assert(result.reason == UserAccessDeniedReason.dayNotAllowed);
```

### Caso 3: Fuera de Horario
```dart
// Setup (hora actual: 23:00)
final admin = AdminProfile(
  startTime: {'hour': 8, 'minute': 0},
  endTime: {'hour': 18, 'minute': 0},
  ...
);

// Test
final result = UserAccessValidator.validateAccess(admin);

// Assert
assert(!result.hasAccess);
assert(result.reason == UserAccessDeniedReason.outsideAllowedHours);
```

## 🔄 Integración con Features Existentes

### UserAdminDialog
✅ **Ahora incluye:**
- Toggle de estado activo/inactivo
- Fecha de creación en header

### AdminProfile Entity
✅ **Propiedades utilizadas:**
- `inactivate`: Estado de bloqueo
- `superAdmin`: Bypass de validaciones
- `daysOfWeek`: Restricción de días
- `startTime` / `endTime`: Restricción de horario
- `hasAccessDay` / `hasAccessHour`: Getters de validación

### SalesProvider
✅ **Se integra automáticamente:**
- `currentAdminProfile` es monitoreado
- Cambios disparan verificación en HomePage

## ⚙️ Consideraciones Técnicas

### Performance
- Verificación cada minuto (bajo impacto)
- Validaciones O(1) - constantes
- No requiere llamadas a Firebase

### Seguridad
- Validación en cliente (UX)
- **IMPORTANTE:** Debe complementarse con validación en backend/Firestore Rules
- Timer previene acceso continuo después de restricción

### UX
- Diálogo no dismissible (fuerza decisión)
- Mensajes claros y específicos
- Opciones de salida evidentes

## 📝 TODO / Mejoras Futuras

- [ ] Agregar logs de intentos de acceso denegados
- [ ] Implementar notificación push al administrador cuando usuario bloqueado intenta acceder
- [ ] Permitir mensaje personalizado en bloqueo
- [ ] Agregar "Solicitar Acceso" button para usuarios bloqueados
- [ ] Implementar validación en Firestore Security Rules (backend)

## 🚀 Deployment

### Pre-requisitos
- ✅ AdminProfile debe tener campo `inactivate`
- ✅ Firestore debe sincronizar cambios en tiempo real
- ✅ AdminProfile debe actualizarse cuando cambia en multiuser

### Migraciones Necesarias
Ninguna. El campo `inactivate` ya existe en AdminProfile desde el principio.

---

**Última actualización:** 28 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Implementado
