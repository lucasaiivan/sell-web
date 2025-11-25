---
trigger: model_decision
description: create new feature
---

# Workflow: Crear Nuevo Feature Completo

**Trigger:** Cuando el usuario pide "Crear feature X" o "Scaffold de módulo X".

Sigue estos pasos estrictamente en orden:

1.  **Definición del Dominio (Domain First):**
    * Crea las **Entities** en `domain/entities/` (Clases puras Dart, inmutables `copyWith`).
    * Define los contratos en `domain/repositories/` (`abstract class`).
    * Crea los **UseCases** en `domain/usecases/` con anotación `@lazySingleton`.

2.  **Capa de Datos (Data Layer):**
    * Crea los **Models** en `data/models/` (Extienden/Mappean Entity + `fromJson`/`toJson`/`fromFirestore`).
    * Crea el **DataSource** en `data/datasources/` (`@lazySingleton`).
    * Implementa el repositorio en `data/repositories/` (`@LazySingleton(as: Interface)`).

3.  **Capa de Presentación (Presentation):**
    * Crea el **Provider** en `presentation/providers/` (`@injectable`, extiende `ChangeNotifier`).
    * Crea la **Page** principal en `presentation/pages/`.

4.  **Integración DI:**
    * Recuérdame ejecutar: `dart run build_runner build --delete-conflicting-outputs`.
    * Indica cómo registrar el provider en `main.dart` (MultiProvider).

5.  **Generación de README:**
    * Genera el archivo `README.md` dentro del feature siguiendo el template estándar (Descripción, Componentes, Flujos, Estado).