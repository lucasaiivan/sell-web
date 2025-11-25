## Descripción
Directorio principal de la aplicación que contiene toda la lógica de negocio, presentación y datos organizados siguiendo **Feature-First + Clean Architecture**.

## Estructura Actual

```
lib/
├── main.dart                # Punto de entrada de la aplicación
├── core/                    # Funcionalidades compartidas y transversales
│   ├── config/              # Configuraciones (Firebase, OAuth, App)
│   ├── constants/           # Constantes globales
│   ├── di/                  # Inyección de dependencias (get_it + injectable)
│   ├── errors/              # Failures y Exceptions
│   ├── mixins/              # Mixins reutilizables
│   ├── presentation/        # UI compartida (widgets, theme, helpers)
│   ├── services/            # Servicios de infraestructura
│   ├── usecases/            # Contrato base UseCase
│   └── utils/               # Utilidades (formatters, helpers)
│
└── features/                # Módulos de negocio (Feature-First)
    ├── auth/                # Autenticación y autorización
    ├── catalogue/           # Gestión de catálogo de productos
    ├── sales/               # Proceso de ventas y tickets
    ├── cash_register/       # Control de caja registradora
    ├── home/                # Página principal
    └── landing/             # Página de landing/bienvenida
```

Cada feature contiene:
```
feature/
├── domain/          # Lógica de negocio pura (entities, repositories, usecases)
├── data/            # Implementación (models, datasources, repositories impl)
└── presentation/    # UI (pages, widgets, providers)
