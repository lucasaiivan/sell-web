# Data Layer - Multiuser Feature

## 📂 Estructura

### Datasources
- `MultiUserRemoteDataSource`: Maneja la comunicación con la fuente de datos remota (Firestore/API) para la gestión de usuarios.

### Repositories (Implementación)
- Implementación de los contratos definidos en el dominio.
- Coordina la obtención y persistencia de datos a través de los datasources.

## 🛠️ Responsabilidades
- Serialización y deserialización de datos (Models).
- Manejo de excepciones de infraestructura.
- Mapeo de modelos de datos a entidades de dominio.
