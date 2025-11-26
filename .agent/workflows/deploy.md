---
description: Deploy rápido a Firebase Hosting
---

# Deploy Workflow

Este workflow realiza un deploy completo de la aplicación Flutter Web a Firebase Hosting.

## Pasos:

// turbo-all

1. **Limpiar build anterior**
   ```bash
   flutter clean
   ```

2. **Obtener dependencias**
   ```bash
   flutter pub get
   ```

3. **Build para web (release)**
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

4. **Deploy a Firebase Hosting**
   ```bash
   firebase deploy --only hosting
   ```

## Notas:
- Usa `--web-renderer canvaskit` para mejor rendimiento y compatibilidad
- El comando `firebase deploy --only hosting` solo actualiza el hosting (más rápido)
- Si necesitas actualizar reglas de storage también, usa: `firebase deploy`
