---
trigger: model_decision
description: Para revisar si la inyección de dependencias está bien configurada
---

# Workflow: Auditoría de Inyección de Dependencias

**Trigger:** Cuando hay errores de "Instance not found" o se pide revisar el código.

1.  **Verificar Anotaciones:**
    * ¿UseCase tiene `@lazySingleton`?
    * ¿Repository Impl tiene `@LazySingleton(as: RepositoryInterface)`?
    * ¿Provider tiene `@injectable`?

2.  **Verificar Constructor:**
    * Asegura que todas las dependencias en el constructor son `final`.

3.  **Verificar Registro:**
    * Si es un Provider, ¿está en el `MultiProvider` de `main.dart`?
    * ¿Se ha ejecutado `configureDependencies()` antes de `runApp`?

4.  **Acción:**
    * Si corregimos algo, instruye al usuario a correr: `dart run build_runner build --delete-conflicting-outputs`.