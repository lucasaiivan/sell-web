# Guía de UI/UX y Sistema de Diseño

El proyecto utiliza **Material Design 3** con una implementación modular de componentes reutilizables.

## Estructura de UI (`lib/core/presentation/`)

### 1. Theme
*   Gestión centralizada de temas (Light/Dark) en `theme/`.
*   Colores y tipografía definidos globalmente.

### 2. Componentes Globales
Para mantener consistencia, usa los componentes base en lugar de crear widgets desde cero:
*   **Dialogs:** Alertas y confirmaciones estándar en `dialogs/`.
*   **Modals:** BottomSheets para acciones secundarias en `modals/`.
*   **Widgets:** Librería de átomos y moléculas compartidos en `widgets/`.
    *   Botones personalizados.
    *   Inputs de texto con validación.
    *   Elementos de tarjeta (Cards).

## Principios de Diseño
1.  **Atomismo:** Construye widgets pequeños. Si un widget supera las 100 líneas, divídelo.
2.  **Adaptive:** La UI debe responder bien a Web y Móvil.
3.  **Feedback:** Usa `Feedback` en la UI para mensajes efímeros y `Dialogs` para decisiones críticas.
4.  **Loading:** Implementa estados de carga visuales (Skeletons/Shimmer) mientras esperas datos asíncronos.

## Recursos
*   **Iconografía:** Standard Material Icons de material design. 
*   **Fuentes:**  default de material design.
