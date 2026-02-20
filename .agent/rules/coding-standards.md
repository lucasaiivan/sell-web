# Estándares de Codificación

## 1. Arquitectura: Feature-First Clean Architecture
El proyecto se organiza por funcionalidades (features), no por capas técnicas globales.

### Estructura de Carpetas
```text
lib/features/[feature_name]/
├── data/
│   ├── datasources/ (Remote/Local Data Source)
│   ├── models/ (DTOs, extends Entity, fromJson/toJson)
│   └── repositories/ (Implementación del contrato de Domain)
├── domain/
│   ├── entities/ (Objetos de negocio puros, equatable)
│   ├── repositories/ (Interfaces abstractas)
│   └── usecases/ (Una clase por acción, ej: LoginUser)
└── presentation/
    ├── providers/ (ChangeNotifiers)
    ├── screens/ (Páginas completas)
    └── widgets/ (Componentes pequeños y locales)
```

## 2. Principios SOLID
*   **S:** Single Responsibility. Una clase, una razón para cambiar.
*   **O:** Open/Closed. Extiende funcionalidad sin modificar código base.
*   **L:** Liskov Substitution. Subclases reemplazables.
*   **I:** Interface Segregation. Interfaces pequeñas y específicas.
*   **D:** Dependency Inversion. Depende de abstracciones (Domain), no de implementaciones (Data).

## 3. Style Guide & Buenas Prácticas
*   **Null Safety:** Estricto. Evita `!` (bang operator) a menos que sea absolutamente seguro. Usa `?` y `??`.
*   **Error Handling:**
    *   `Data`: Captura excepciones y lanza `Failure` (custom class).
    *   `Domain`: Retorna `Either<Failure, Type>` o lanza excepciones controladas.
    *   `Presentation`: Muestra UI de error amigable.
*   **Nombres:**
    *   Clases: `PascalCase` (UserProfile).
    *   Variables/Funciones: `camelCase` (getUserData).
    *   Archivos: `snake_case` (user_profile.dart).
*   **Async:** Usa `async/await` en lugar de `.then()`.

## 4. UI/UX Code
*   **Composición:** Divide widgets grandes en pequeños `StatelessWidget` con `const`.
*   **Const:** Usa `const` en constructores siempre que sea posible para optimizar rebuilds.
*   **Providers:** Inyecta dependencias en el árbol de widgets lo más alto posible pero lee lo más bajo posible (Consumer).
