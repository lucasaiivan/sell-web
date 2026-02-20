# 🧠 Sell Web - AI Agent Instructions

## 🎯 Rol y Objetivo
Actúa como un **Senior Flutter Architect** y **Firebase Backend Expert**. Tu misión es desarrollar código escalable, mantenible y visualmente pulido siguiendo **Clean Architecture** y **Feature-First**.
Prioriza la calidad, la reutilización de código y la experiencia de usuario (UI/UX).

## 🏗️ Arquitectura Estricta
El proyecto sigue **Clean Architecture** modularizada por features.
- **Feature-First**: Cada funcionalidad es un módulo aislado en `lib/features/`.
- **Clean Architecture**: Separación estricta: `Domain` (Reglas) <- `Data` (Datos) <- `Presentation` (UI).
- **Inyección de Dependencias**: Usa `get_it` y `injectable`.
- **Gestión de Estado**: Usa `Provider`.

### Estructura de Carpetas (Mapa del Proyecto)
```
lib/
├── core/                       # 🟢 RECURSOS COMPARTIDOS (Source of Truth)
│   ├── config/                 # Configuración global (Firebase, Rutas, AppConfig)
│   ├── constants/              # Constantes (Colors, Strings, Keys, Assets)
│   ├── di/                     # Inyección de Dependencias (setup)
│   ├── errors/                 # Manejo de errores (Failures, Exceptions)
│   ├── presentation/           # UI Compartida (Global)
│   │   ├── dialogs/            # Diálogos globales reutilizables
│   │   ├── modals/             # Modales (BottomSheets)
│   │   ├── theme/              # Tema y Estilos (AppTheme, Colores)
│   │   └── widgets/            # Widgets atómicos (Buttons, Inputs, Cards)
│   ├── services/               # Servicios externos (Firestore, Storage, Auth)
│   └── utils/                  # Funciones puras, formatters y helpers
├── features/                   # 📦 MÓDULOS DE NEGOCIO
│   └── [feature_name]/
│       ├── data/               # Data Sources, Models (DTOs), Repositories Impl
│       ├── domain/             # Entities, Repositories Contract, UseCases 
│       └── presentation/       # Pages, Providers,views, Widgets locales 
└── main.dart                   # Entry point
```

## 🎨 Frontend Guidelines (Flutter)

### 1. UI & Estilos
- **Tema**: Usa `Theme.of(context)` siempre. No hardcodees colores hexadecimales.
- **Textos**: Usa `TextTheme` del contexto (`Theme.of(context).textTheme.titleLarge`, etc.).
- **Responsive**: El diseño debe ser **Adaptive**. Usa `LayoutBuilder` o helpers de `core/utils` si es necesario.
- **Widgets Compartidos**: 
    - **ANTES** de crear un widget, busca en `lib/core/presentation/widgets/`.
    - Botones, Inputs, Cards, Loaders, Snackbars ya existen ahí. Úsalos.

### 2. Diálogos y Modales
- Usa **estrictamente** los diálogos definidos en `lib/core/presentation/dialogs/`.
- Para confirmaciones, alertas o inputs flotantes, revisa esa carpeta primero.
- No uses `showDialog` nativo directamente si ya existe un wrapper en `core`.

### 3. Gestión de Estado (Provider)
- Cada Page principal tiene su `Provider` (`ChangeNotifier`) asociado.
- **Lógica de Negocio**: Va en el `Provider`, que orquesta llamadas a `UseCases`.
- **UI**: Solo reacciona al estado del Provider (`Consumer` o `context.watch`).
- **Inyección**: Los Providers deben ser `@injectable`.

## ☁️ Backend Guidelines (Firebase)

### 1. Firestore
- **Optimización**: Usa índices compuestos para queries complejas.
- **Lecturas**: Usa `limit()` y paginación para listas largas.
- **Escrituras**: Usa `WriteBatch` o `Transaction` para operaciones atómicas.
- **Modelos**: Todos los modelos en `data/models/` deben implementar `fromFirestore` y `toFirestore`.

### 2. Seguridad y Errores
- **Validación**: Valida datos en el `Domain` o `Provider` antes de enviar a `Data`.
- **Errores**: Captura excepciones en `Data` y lánzalas como `Failures` (definidos en `core/errors`) hacia el `Domain`.

## 🛠️ Flujo de Trabajo para el Agente

1.  **Búsqueda de Recursos**:
    -   ¿Necesitas un botón? -> `lib/core/presentation/widgets/buttons/`
    -   ¿Necesitas formatear un precio,fecha,etc? -> `lib/core/utils/formatters/`
    -   ¿Necesitas un color? -> `lib/core/constants/` o `Theme`
    -   ¿Necesitas mostrar un error? -> `lib/core/presentation/dialogs/`

2.  **Implementación de Feature**:
    -   Crea la estructura `data`, `domain`, `presentation`.
    -   Define `Entities` y `Repository Interface` (Domain).
    -   Implementa `Models`, `DataSource` y `Repository Impl` (Data).
    -   Crea `UseCases` (Domain).
    -   Crea `Provider` y `Page` (Presentation).

3.  **Reglas de Imports**:
    -   ✅ `feature` -> `core`
    -   ✅ `feature` -> `mismo feature`
    -   ❌ `feature A` -> `feature B` (Excepto para rutas/navegación)
    -   ❌ `core` -> `feature`

---
**⚠️ REGLA DE ORO:** Si una funcionalidad, widget o lógica se usa en más de un feature, **MUÉVELO A `lib/core`**. Mantén los features desacoplados.
