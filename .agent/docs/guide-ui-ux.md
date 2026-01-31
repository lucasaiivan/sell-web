# Guía de UI/UX y Sistema de Diseño

El proyecto utiliza **Material Design 3** con una implementación modular de componentes reutilizables.

### 1. Theme
*   Gestión centralizada de temas (Light/Dark) en `theme/`.
*   Colores y tipografía definidos globalmente.

### 2. Estructuran y Componentes Globales de UI (`lib/core/presentation/`)
Para mantener consistencia, usa los componentes base en lugar de crear widgets desde cero:
*   **Dialogs:** Alertas y confirmaciones estándar en `dialogs/`.
*   **Modals:** BottomSheets para acciones secundarias en `modals/`.
*   **Widgets:** Librería de átomos y moléculas compartidos en `widgets/`.
    *   `buttons` : Botones personalizados.
    *   `dialogs` : Dialogs personalizados.
    *   `feedback` : Feedbacks personalizados.
    *   `graphics` : Gráficos personalizados (PercentageBarChart).
    *   `inputs` : Inputs personalizados.
    *   `navigation` : widgets personalizados para navegación.
    *   `success` : Widget reutilizable para mostrar confirmación visual de procesos
    *   `ui` : mas widgets personalizados para UI (avartar de producto, avatar de usuario, divider, image, listile,progress, etc...).
    

## Principios de Diseño
1.  **Atomismo:** Reutiliza los widgests de la carpeta `/lib/core/presentation/` en lo posible, crea widgests reutilizables si es necesario y va reutilizar en mas de una pantalla, Crea widgets modulares segun las responsabilidades de cada uno (avitar generar muchos wisgets desacoplados innecesariamente).
2.  **Adaptive:** La UI debe responder bien a Mobile, Tablet, Desktop y Web con metricas definidas en `helpers/`.
3.  **Feedback:** reutiliza `/feedback/` o crea 'feedback' realmente util en la UI para mensajes efímeros.
4.  **Loading:** Implementa estados de carga visuales (Skeletons/Shimmer) mientras esperas datos asíncronos y `/success` para despues de cada operacion critica.

## Recursos
*   **Iconografía:** Standard Material Icons de material design. 
*   **Fuentes:**  default de material design.
