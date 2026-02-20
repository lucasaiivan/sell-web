# Guía de UI/UX y Sistema de Diseño (V.3.0)

Este documento es la **REFERENCIA TÉCNICA SUPREMA** para la generación de interfaces.
Todo widget, diálogo o pantalla debe adherirse estrictamente a los patrones aquí descritos. **Ignorar estas reglas es considerado un fallo crítico.**

---

## 1. Filosofía de Diseño: Atomismo Estratégico

El proyecto sigue una arquitectura **Clean** con una capa de presentación modular.
**REGLA DE ORO:** No reinventar la rueda. Utiliza los "Super-Widgets" del Core antes de crear componentes nuevos. Si debes crear algo nuevo local o crear un nuevo widget reutilizable, imita los patrones de estilo existentes del core y reglas de implementación.

### Principios
1.  **Consistencia Eficiencia:** Un enfoque minimalista y eficiente.
2.  **Mantenibilidad Centralizada:** Estilos en `ThemeData` o Widgets Core. NUNCA estilos hardcodeados en vistas.
3.  **Feedback Obsesivo:** El usuario SIEMPRE debe saber qué pasó (Éxito/Error/Carga).
4.  **Responsividad Universal:** Todo debe funcionar fluidamente     en Móvil, Tablet y Desktop sin romperse.

---

## 2. Implementación Técnica (Do's and Don'ts)

### ❌ TOC: Vicios Prohibidos
*   **Hardcoding Colors:** `Color(0xFF...)` o `Colors.blue`. -> Usa `Theme.of(context).colorScheme`.
*   **Raw Widgets:** `ElevatedButton`, `TextField`, `AlertDialog`, `ListTile` crudos. -> Usa componentes de `lib/core/presentation/widgets/`.
*   **Magic Numbers:** `SizedBox(height: 37)`. -> Usa constantes o múltiplos de 4/8.
*   **Duplicación de Lógica UI:** Crear un diálogo confirmación desde cero. -> Usa `showConfirmationDialog`.

### ✅ Virtudes Obligatorias
*   **Contexto de Tema:**
    ```dart
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    ```
*   **Imports de Core:**
    ```dart
    import 'package:sellweb/core/presentation/widgets/widgets.dart';
    import 'package:sellweb/core/presentation/dialogs/dialogs.dart';
    ```

---

## 3. Catálogo de Componentes Core

### 🔘 Botones (`AppButton`)
Unificación total. **Prohibido** usar botones nativos directamente.

| Tipo | Constructor | Uso |
| :--- | :--- | :--- |
| **Primario** | `AppButton.primary(...)` | Acción principal (Guardar, Confirmar). |
| **Secundario** | `AppButton.outlined(...)` | Acción alternativa (Cancelar, Volver). |
| **Terciario** | `AppButton.text(...)` | Navegación menor, detalles. |
| **Loading** | `isLoading: true` | Manejado internamente por el widget. |

### 📝 Inputs (`InputTextField`)
Wrapper de `TextFormField` con estilos y validación pre-configurada.

| Tipo | Widget | Notas |
| :--- | :--- | :--- |
| **Texto** | `InputTextField` | Soporta `validator`, `prefixIcon`, `label`. |
| **Moneda** | `MoneyInputTextField` | Formateo automático de dinero. |
| **Búsqueda** | `SearchTextField` | Estilo pastilla, debounce integrado. |

### 💬 Estrategia de Diálogos (CRÍTICO)
**MANDATORIO:** Todo diálogo debe heredar de la infraestructura base. Esto garantiza modo FullScrren automático en móviles.

#### A. Diálogos Estándar (Helpers)
Para lo cotidiano, usa `lib/core/presentation/widgets/dialog/base/standard_dialogs.dart`.

```dart
// Confirmación (Borrar, Salir)
final bool? result = await showConfirmationDialog(
  context: context,
  title: '¿Eliminar producto?',
  message: 'Esta acción es irreversible.',
  isDestructive: true,
);

// Información simple
await showInfoDialog(context: context, title: 'Info', message: 'Proceso terminado.');

// Error
await showErrorDialog(context: context, title: 'Error', message: 'Sin conexión.');
```

#### B. Diálogos Personalizados (`BaseDialog`)
Para formularios o flujos complejos. Usa `showBaseDialog`.
**IMPORTANTE:** Construye el contenido usando `DialogComponents` (`lib/core/presentation/widgets/dialog/base/dialog_components.dart`).

```dart
showBaseDialog(
  context: context,
  title: 'Editar Dispositivo',
  fullView: true, // ✅ Se convierte en página completa en móvil
  content: Column(
    children: [
      // Bloque de información
      DialogComponents.infoSection(
        context: context,
        title: 'Estado',
        content: DialogComponents.infoRow(
            context: context, label: 'Batería', value: '85%', icon: Icons.battery_full),
      ),
      const SizedBox(height: 16),
      // Input estilizado para diálogo
      DialogComponents.textField(
        context: context,
        controller: _nameCtrl,
        label: 'Nombre',
      ),
    ],
  ),
  actions: [
    DialogComponents.secondaryActionButton(
        context: context, text: 'Cancelar', onPressed: () => Navigator.pop(context)),
    DialogComponents.primaryActionButton(
        context: context, text: 'Guardar', onPressed: _save),
  ],
);
```

#### C. Componentes de Diálogo (`DialogComponents`)
No "inventes" UI dentro de un modal. Ensambla estas piezas:

*   `infoContainer`: Caja con borde para agrupar datos.
*   `infoRow`: Fila clave/valor limpia.
*   `itemList`: Lista de items con separadores.
*   `summaryContainer`: KPI o total grande destacado.
*   `divider`: Línea separadora sutil.

---

## 4. Estructura del Presentation Layer

*   `/lib/core/presentation/`
    *   `widgets/`: Átomos (Buttons, Inputs, DialogComponents).
    *   `dialogs/`: Implementaciones concretas de diálogos de negocio (e.g. `ClientSelectionDialog`).
    *   `theme/`: `ThemeService` y paleta de colores.
    *   `helpers/`: `responsive_helper.dart` y otras utilidades de UI.

## 5. Responsividad
Usa `responsive_helper.dart` o `LayoutBuilder`.
*   Diseña pensando en "Estirable".
*   En Diálogos: `fullView: true` en `showBaseDialog` maneja la adaptación móvil automáticamente.

---

**CHECKLIST MENTAL DEL AGENTE:**
1.  ¿Estoy usando `AppButton`?
2.  ¿Estoy usando `Theme.of(context)`?
3.  ¿Si es un diálogo, estoy usando `showBaseDialog` o un helper estándar?
4.  ¿Si es un diálogo custom, estoy usando `DialogComponents` para el interior?
