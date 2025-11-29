# Domain Layer - Multiuser Feature

## 📂 Estructura

### Use Cases
Contiene la lógica de negocio pura encapsulada en casos de uso individuales:
- `CreateUserUseCase`: Creación de nuevos usuarios.
- `DeleteUserUseCase`: Eliminación de usuarios existentes.
- `GetUsersUseCase`: Obtención del listado de usuarios.
- `UpdateUserUseCase`: Actualización de información de usuarios.

### Repositories (Contratos)
- Define las interfaces que debe implementar la capa de datos.
- Garantiza la inversión de dependencias.

## 🛠️ Responsabilidades
- Definición de reglas de negocio.
- Definición de entidades inmutables.
- Independencia de frameworks y librerías externas.
