# Arquitectura del Sistema: Feature-First Clean Architecture

El proyecto `sell-web` implementa una arquitectura modular y escalable basada en **Clean Architecture**, organizada verticalmente por **Features**.

## Diagrama (Top-Down) de Estructura de Proyecto
```mermaid
graph TD
    %% Estilos
    classDef folder fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef core fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;
    classDef feature fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5;
    classDef layer fill:#ffffff,stroke:#333,stroke-width:1px;

    subgraph App [📱 App Architecture]
        direction TB
        
        subgraph CoreModule [🧩 Core Module]
            direction TB
            DI[🛠️ DI]:::core
            Router[🚏 Router]:::core
            Theme[🎨 Theme]:::core
            Network[📡 Services/Network]:::core
            Utils[🔧 Utils/Helpers]:::core
        end

        subgraph Features [📦 Features Strategy]
            direction TB
            
            subgraph FeatureExample [Feature: Catalogue/Sales/Auth...]
                direction TB
                
                subgraph Presentation [🎨 Presentation Layer]
                    Screens[📱 Screens]:::layer
                    Providers[🧠 Providers]:::layer
                    Widgets[🧱 Local Widgets]:::layer
                end
                
                subgraph Domain [🧠 Domain Layer (Pure Dart)]
                    UseCases[⚡ UseCases]:::layer
                    Entities[🧊 Entities]:::layer
                    RepoInterface[📝 Repo Interface]:::layer
                end
                
                subgraph Data [� Data Layer]
                    RepoImpl[⚙️ Repo Impl]:::layer
                    DataSources[🔌 DataSources]:::layer
                    Models[📄 Models (DTOs)]:::layer
                end
            end
        end
    end

    %% Relaciones
    CoreModule --> Features
    
    %% Flujo interno Feature
    Screens --> Providers
    Providers --> UseCases
    UseCases --> RepoInterface
    RepoImpl -.->|Implements| RepoInterface
    RepoImpl --> DataSources
    DataSources --> Models
    Models -.->|Maps to| Entities
    
    %% Dependencias Cruzadas
    DataSources --> Network
    Providers --> DI
```

## Descripción de Módulos (Ingeniería Inversa)

### 1. Features (`lib/features/`)
El núcleo del negocio está dividido en dominios estancos.
*   **auth:** Gestión de sesión, perfiles y seguridad.
*   **catalogue:** Gestión de productos, categorías, variantes y combos.
*   **sales:** Puntos de venta, lógica de facturación y carritos.
*   **cash_register:** Control de caja, aperturas y cierres.
*   **analytics:** Métricas y reportes.
*   **multiuser:** Gestión de roles y permisos.
*   **landing:** Páginas públicas/informativas.

### 2. Core (`lib/core/`)
Utilidades transversales compartidas por todas las features. Esta carpeta organiza los componentes compartidos y la lógica base de toda la aplicación.

*   **config:** Configuraciones globales de la app y Firebase.
*   **constants:** Constantes (Colores, UI, SharedPrefs, Units).
*   **di:** Inyección de dependencias (Service Locator).
*   **domain:** Definiciones de dominio base.
    *   `entities`: Entidades base compartidas.
    *   `repositories`: Interfaces de repositorio base.
*   **errors:** Manejo de errores (`Failure`, `Exception`, `Mapper`).
*   **mixins:** Mixins reutilizables (validaciones, loggers).
*   **presentation:** Componentes de UI compartidos y sistema de diseño.
    *   `dialogs`: Lógica y vistas de diálogos complejos (configuración, feedback, tickets).
    *   `helpers`: Ayudantes de UI.
    *   `modals`: Hojas modales (BottomSheets).
    *   `providers`: Providers globales (`Theme`, `Connectivity`, `Account`, `Initializable`).
    *   `theme`: Definiciones de tema (`ThemeData`).
    *   `views`: Vistas genéricas o de error.
    *   `widgets`: Biblioteca de Widgets reutilizables (Atomic Design): `buttons`, `feedback`, `graphics`, `inputs`, `monitoring`, `navigation`, `success`, `ui`.
*   **services:** Servicios de infraestructura y wrappers para librerías externas.
    *   `database`: Implementación de Firestore.
    *   `external`: Servicios externos (Impresoras Térmicas, etc).
    *   `monitoring`: Servicios de monitoreo.
    *   `storage`: Almacenamiento local y remoto.
    *   `sync`: Sincronización de datos.
    *   `theme`: Servicio de persistencia de tema.
    *   `window`: Gestión de ventanas (Desktop/Web).
*   **usecases:** Clase base para casos de uso (`UseCase<Type, Params>`).
*   **utils:** Utilidades puras de Dart.
    *   `formatters`: Formateadores (Moneda, Fecha).
    *   `helpers`: Lógica auxiliar (Validadores, Generadores de ID, Cálculos).

## Flujo de Datos (The Loop)
1.  **UI (Screen/Widget)** escucha cambios de un **Provider**.
2.  **Provider** invoca un **UseCase** del dominio.
3.  **UseCase** orquesta lógica de negocio y llama al **Repository (Interface)**.
4.  **Repository (Impl)** decide la fuente de datos (Remote/Local) y llama al **DataSource**.
5.  **DataSource** ejecuta la petición (Firestore/HTTP/Storage) y retorna datos crudos o `ProductModel`.
6.  `ProductModel` mapea los datos a `Product` (Entity) y retorna hacia arriba.
