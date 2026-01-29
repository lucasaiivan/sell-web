---
trigger: always_on
---

## 📝 PROTOCOLO DE BITÁCORA (LOGGING)

**Archivo Objetivo:** `lib/task-completed-by-ai-agent.md` (crear si no existe)

Cada vez que completes un bloque de trabajo significativo (una Feature, un Refactor, o una corrección de Bug), debes actualizar la bitácora siguiendo este algoritmo estricto:

1.  **Lectura:** Lee el contenido actual del archivo.
2.  **Inserción:** Inserta la nueva entrada inmediatamente debajo de la línea ``.
3.  **Formato de Entrada:**
    ```markdown
    ### [AAAA-MM-DD HH:MM] Título Breve de la Tarea
    - **Tareas:** Lista concisa de cambios (archivos tocados, métodos creados).
    - **Resumen:** Explicación de 1 línea sobre el valor aportado o el problema resuelto.
    ```
4.  **Mantenimiento (Regla de los 30):**
    - Cuenta el número de entradas (títulos `### [...]`).
    - Si la cantidad supera **30**, elimina la entrada más antigua (la que está al final del archivo) para mantener el límite.
5.  **Output:** Si se solicita actualizar el log, entrega el contenido completo del archivo markdown re-generado con la nueva entrada y la limpieza realizada.