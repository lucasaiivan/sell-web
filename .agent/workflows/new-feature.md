---
description: Guía para implementar una nueva funcionalidad siguiendo Clean Architecture.
---

# Workflow: Nueva Feature

Sigue este orden estricto para mantener la arquitectura limpia.

1.  **Preparar Estructura:**
    Crea las carpetas en `lib/features/[nombre_feature]/`:
    *   `data/datasources`
    *   `data/models`
    *   `data/repositories`
    *   `domain/entities`
    *   `domain/repositories`
    *   `domain/usecases`
    *   `presentation/providers`
    *   `presentation/screens`
    *   `presentation/widgets`

2.  **Capa DOMAIN (El "Qué"):**
    *   Define la **Entity** (Clase pura Dart).
    *   Define la interfaz del **Repository** (Contrato abstracto).
    *   Crea los **UseCases** (Una clase por operación lógica).

3.  **Capa DATA (El "Cómo"):**
    *   Crea el **Model** (Extiende Entity, añade `fromJson`/`toJson`).
    *   Implementa el **RemoteDataSource** (Llamadas a Firebase/API).
    *   Implementa el **Repository** (Une DataSource con Domain, maneja excepciones).

4.  **Capa PRESENTATION (El "Ver"):**
    *   Crea el **Provider/Controller** (Gestiona estado usando UseCases).
    *   Construye las **Screens** (Scaffold principal).
    *   Extrae **Widgets** reutilizables.

5.  **Inyección:**
    Registra tus Providers/Repositorios en el árbol principal (si usas `MultiProvider` global o local).
