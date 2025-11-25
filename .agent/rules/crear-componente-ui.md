---
trigger: model_decision
description: crear reutilizable o nuevo component ui Para evitar duplicados y decidir dónde poner un widget.
---

# Workflow: Crear Componente UI

**Trigger:** Cuando el usuario pide un widget, botón, input o elemento visual.

1.  **Análisis de Reutilización:**
    * Revisa mentalmente la lista de `presentation/widgets/` (Buttons, Inputs, Dialogs).
    * Si existe algo similar, sugiere usarlo o extenderlo.

2.  **Decisión de Ubicación:**
    * ¿Es genérico (usado en toda la app)? → Sugiere crear en `lib/presentation/widgets/[categoria]/`.
    * ¿Es específico de negocio (solo para este feature)? → Sugiere crear en `lib/features/[feature]/presentation/widgets/`.

3.  **Generación de Código:**
    * Usa `StatelessWidget` por defecto a menos que requiera estado interno efímero.
    * Aplica estilos de Material 3.
    * Si es compartido, añade documentación minimalista `///` explicando parámetros.