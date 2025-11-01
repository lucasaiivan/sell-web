## Descripción
Casos de uso que implementan la lógica de negocio específica y orquestan las operaciones del dominio.

## Contenido
```
usecases/
├── account_usecase.dart           # Gestión de cuentas
├── auth_usecases.dart             # Autenticación y autorización
├── cash_register_usecases.dart    # Gestión de cajas, persistencia de tickets, historial
├── catalogue_usecases.dart        # Gestión de catálogo de productos
└── sell_usecases.dart             # Gestión temporal de tickets (productos, cálculos)
```

## Separación de Responsabilidades

### SellUsecases (Gestión Temporal)
- Crear y modificar tickets en memoria
- Agregar/eliminar productos
- Configurar pagos y descuentos
- Preparar tickets para venta
- Persistencia local (SharedPreferences)

### CashRegisterUsecases (Persistencia y Caja)
- Abrir/cerrar cajas registradoras
- Flujos de caja (ingresos/egresos)
- Guardar tickets en Firebase
- Consultar historial de transacciones
- Anular tickets persistidos
- Reportes y análisis
