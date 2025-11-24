# Feature: Catalogue

Este módulo maneja toda la funcionalidad relacionada con el catálogo de productos.

## Estructura (Clean Architecture + Feature-first)

```
catalogue/
├── data/                   # Capa de Datos
│   ├── datasources/        # Fuentes de datos (Firebase, API, Local)
│   ├── models/             # Modelos con lógica de serialización
│   └── repositories/       # Implementaciones de repositorios
│
├── domain/                 # Capa de Dominio (Pura, sin dependencias externas)
│   ├── entities/           # Entidades de negocio
│   ├── repositories/       # Contratos/Interfaces de repositorios
│   └── usecases/           # Casos de uso (Reglas de negocio)
│
└── presentation/           # Capa de Presentación
    ├── providers/          # Gestión de estado (Provider/Bloc)
    ├── pages/              # Páginas/Pantallas
    └── widgets/            # Componentes UI reutilizables

```

## Flujo de Datos

```
UI (Page/Widget)
    ↓
Provider/Bloc
    ↓
UseCase (Domain)
    ↓
Repository (Interface - Domain)
    ↑ implementado por
Repository Impl (Data)
    ↓
DataSource (Data)
    ↓
Firebase/API
```

## Entidades vs Modelos

### Entidades (Domain)
- **Puras**: Solo Dart, sin dependencias externas
- **Inmutables**: Representan conceptos de negocio
- **Ejemplos**: `Product`, `ProductCatalogue`, `Category`

### Modelos (Data)
- **Extienden entidades**: Agregan funcionalidad
- **Serialización**: `toJson()`, `fromMap()`, `fromDocumentSnapshot()`
- **Conversiones**: Manejo de `Timestamp`, tipos legacy
- **Ejemplos**: `ProductModel`, `ProductCatalogueModel`

## Casos de Uso Implementados

- `GetProductsUseCase`: Obtiene productos del catálogo
- `UpdateStockUseCase`: Actualiza stock con validaciones

## Próximos Pasos

1. Agregar más UseCases según necesidades
2. Implementar Provider/Bloc para gestión de estado
3. Migrar páginas existentes a esta estructura
4. Agregar tests unitarios para UseCases
5. Implementar manejo de errores con `Either<Failure, Success>`
