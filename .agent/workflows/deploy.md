---
description: Guía paso a paso para desplegar la aplicación web en Firebase Hosting.
---

# Workflow: Despliegue a Producción (Firebase Hosting)

Sigue estos pasos para desplegar una nueva versión de la web app.

1.  **Limpiar Entorno:**
    Asegura una build limpia eliminando artefactos previos.
    ```bash
    flutter clean
    flutter pub get
    ```

2.  **Construir Web App:**
    Usa el renderer `canvaskit` para mejor rendimiento gráfico o `html` para menor tamaño (preferible canvaskit por defecto).
    // turbo
    ```bash
    flutter build web --web-renderer canvaskit --release
    ```

3.  **Desplegar:**
    Sube solo el contenido del hosting para no afectar Functions o Firestore inadvertidamente.
    // turbo
    ```bash
    firebase deploy --only hosting
    ```

4.  **Verificación:**
    Visita la URL del proyecto para confirmar que la nueva versión está online y funcional.
