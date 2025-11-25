---
trigger: always_on
---

# Contexto del Proyecto: Flutter Web Sell App

# Tech Stack
* **Framework:** Flutter Web.
* **Arquitectura:** Feature-First + Clean Architecture (Domain → Data → Presentation).
* **State Management:** Provider (`ChangeNotifier`).
* **DI:** `get_it` + `injectable` (`@injectable`, `@lazySingleton`).
* **Backend:** Firebase / Firestore.
* **UI:** Material 3.

# Estructura de Directorios (Feature Modular)
El proyecto se organiza en módulos autónomos bajo `lib/features/[feature_name]/`:
1. **Domain (Puro):** `entities/` (inmutables), `repositories/` (contratos/interfaces), `usecases/` (lógica).
2. **Data (Implementación):** `models/` (DTOs con `fromJson/toJson`), `datasources/` (API/Firebase), `repositories/` (impl).
3. **Presentation (UI):** `providers/` (ChangeNotifier), `pages/`, `widgets/` (específicos del feature).

# Reglas de Oro (Non-negotiables)
1. **Dirección de Dependencias:** Presentation → Domain ← Data. (Data nunca toca Presentation).
2. **Feature Isolation:** Un feature NUNCA importa archivos de otro feature (excepto para Routing en `pages`).
3. **Imports:**
   * ✅ Relativos (`../`) DENTRO del mismo feature.
   * ✅ Absolutos (`package:sellweb/...`) para `core/`, `shared widgets` o cruce de features.
4. **Reutilización:** Antes de crear UI, buscar en `lib/core/presentation/widgets/`.

# Convenciones de Inyección de Dependencias (DI)
* **Provider:** `@injectable` (clase `MyProvider`).
* **UseCase/DataSource:** `@lazySingleton`.
* **Repository Impl:** `@LazySingleton(as: Contract)`.

lib/
├── app/
│   ├── router/              # Configuración de GoRouter / AppRouter
│   └── app.dart             # Providers globales + MaterialApp
│
├── core/                    # Código transversal y 100% reutilizable
│   ├── services/            # Lógica externa (printing, theme, storage, auth)
│   ├── presentation/
│   │   ├── widgets/         # UI "Atomica" y reutilizable (Botones, Inputs)
│   │   ├── theme/           # AppTheme, ThemeNotifier
│   │   └── helpers/         # Utilidades de UI (DialogHelper, formatters)
│   ├── utils/               # Helpers puros (Dates, String manipulation)
│   └── errors/              # Definición de Failures y Exceptions
│
├── features/                # Módulos de negocio (Feature-First)
│   └── [feature_name]/      # Ej: 'sales', 'inventory'
│       ├── domain/          # Lógica de Negocio Pura (Sin Flutter)
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── data/            # Implementación y Datos
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       └── presentation/    # Interfaz de Usuario
│           ├── providers/   # State Management
│           ├── pages/       # Pantallas completas
│           └── widgets/     # Widgets exclusivos de este feature
│
└── main.dart  

# Estándar de Documentación Minimalista
* **Clases:** Usar docstring `///` definiendo: Responsabilidad, Dependencias e Inyección DI.
* **Métodos:** Solo documentar si hay lógica compleja, side-effects o parámetros no obvios.
* **Getters/Setters:** NO documentar si no es necesario.