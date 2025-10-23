# Diálogos de Cuenta (Account Dialogs)

## Descripción
Diálogos relacionados con la gestión de cuentas de usuario y perfiles de administrador.

## Contenido

### Archivos
```
account/
├── README.md                           # Este archivo
├── admin_profile_info_dialog.dart      # Diálogo de información de AdminProfile
└── account_selection_dialog.dart       # Diálogo de selección de cuentas
```

### Componentes

#### `admin_profile_info_dialog.dart`
Diálogo que muestra la información completa de un perfil de administrador (`AdminProfile`).

**Características:**
- ✅ Información básica (nombre, email, ID, cuenta)
- ✅ Estado y roles (activo/inactivo, super admin, admin)
- ✅ Fechas de creación y última actualización
- ✅ Horarios de acceso configurados
- ✅ Días de la semana habilitados
- ✅ Permisos personalizados detallados
- ✅ Diseño responsive con Material Design 3
- ✅ Interfaz limpia y organizada por secciones

**Uso:**
```dart
showAdminProfileInfoDialog(
  context: context,
  admin: miAdminProfile,
);
```

**Parámetros:**
- `context` (BuildContext, required): Contexto de Flutter
- `admin` (AdminProfile, required): Perfil de administrador a mostrar

**Secciones mostradas:**
1. **Información Básica**: Nombre, email, ID de usuario, ID de cuenta
2. **Estado y Roles**: Estado activo/inactivo, badges de super admin, admin, permisos personalizados
3. **Fechas**: Creación y última actualización (formato dd/MM/yyyy HH:mm)
4. **Horarios de Acceso**: Horario de inicio y cierre (si están configurados)
5. **Días Habilitados**: Días de la semana con acceso permitido (si están configurados)
6. **Permisos**: Permisos personalizados detallados con iconos (arqueo, historial, transacciones, catálogo, multiusuario, editar cuenta)

**Diseño:**
- Ancho: 500px
- Header con icono de persona
- Botón de cerrar en la parte inferior
- Secciones con iconos descriptivos y contenedores con bordes redondeados
- Estados visuales con colores del tema (verde para activo, rojo para inactivo)
- Badges coloridos para roles y permisos
- Chips para días de la semana

#### `account_selection_dialog.dart`
Diálogo moderno para la selección de cuentas asociadas con información del usuario administrador.

**Características:**
- ✅ Perfil del usuario administrador (avatar, nombre, email) - clickeable para ver detalles
- ✅ Lista de cuentas asociadas con avatares y ubicación
- ✅ Indicador visual de cuenta seleccionada (check icon)
- ✅ Botones de acción: Cerrar sesión y Cerrar
- ✅ Integración con providers (AuthProvider, SellProvider)
- ✅ Soporte para cuenta demo si el usuario es anónimo
- ✅ Diseño responsive con Material Design 3
- ✅ Lista expandible/colapsable para muchas cuentas

**Uso:**
```dart
showAccountSelectionDialog(
  context: context,
);
```

**Parámetros:**
- `context` (BuildContext, required): Contexto de Flutter

**Secciones mostradas:**
1. **Usuario Administrador**: Avatar, nombre y email del usuario autenticado (clickeable para ver AdminProfile)
2. **Cuentas Asociadas**: Lista de cuentas con avatar, nombre y ubicación
3. **Acciones**: Botones de Cerrar sesión y Cerrar

**Interacciones:**
- Click en usuario administrador: muestra `admin_profile_info_dialog`
- Click en cuenta: selecciona la cuenta y cierra el diálogo
- Botón "Cerrar sesión": muestra confirmación y cierra sesión de Firebase
- Botón "Cerrar": cierra el diálogo

**Diseño:**
- Ancho: 500px
- Header con icono de negocio
- Secciones con `DialogComponents.infoSection`
- Lista con `DialogComponents.itemList` (max 4 items visibles, expandible)
- Botones de acción en la parte inferior
- UserAvatar para mostrar avatares de usuario y cuentas

---

## Componentes Reutilizados
- `BaseDialog` - Estructura base del diálogo con Material Design 3
- `DialogComponents` - Componentes estandarizados para secciones, filas de info, botones
- `showBaseDialog` - Función helper para mostrar diálogos
- `DateFormat` (intl) - Formateo de fechas
- Material Design 3 widgets

## Notas de Diseño
- Usa colores del tema para estados (verde para activo, rojo para inactivo)
- Organización clara por secciones con `DialogComponents.infoSection`
- Visualización de días de la semana con chips coloridos
- Badges con bordes y colores para roles (primary, secondary, tertiary)
- Permisos mostrados como chips con iconos descriptivos
- Responsive: padding y espaciado adaptable
- Iconografía consistente con Material Icons (outlined y rounded)
