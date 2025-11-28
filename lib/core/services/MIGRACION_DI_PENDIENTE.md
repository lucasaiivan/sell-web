# 🔄 Guía de Migración DI Pendiente

## Estado Actual de la Migración

### ✅ Completado

1. **Servicios Core Refactorizados:**
   - `ThemeService` → `@lazySingleton` con DI
   - `ThermalPrinterHttpService` → `@lazySingleton` con DI
   - `AppDataPersistenceService` → `@lazySingleton` con DI
   - `SharedPreferences` → Inyectado con `@preResolve`

2. **Componentes Reubicados:**
   - `theme_service.dart`: `core/presentation/theme/` → `core/services/theme/`
   - `printer_provider.dart`: `core/services/printing/` → `features/sales/presentation/providers/`

3. **UseCases de Auth Migrados:**
   - `SaveAdminProfileUseCase` ✅
   - `LoadAdminProfileUseCase` ✅
   - `ClearAdminProfileUseCase` ✅
   - `GetUserAccountsUseCase` ✅

4. **Repositorios Migrados:**
   - `AccountRepositoryImpl` ✅

5. **Providers Migrados:**
   - `ThemeDataAppProvider` ✅ (con DI)
   - `PrinterProvider` ✅ (con DI)

### ⚠️ Pendiente

#### 1. Instanciaciones Directas de `ThermalPrinterHttpService`

**Archivos afectados:**
```
lib/features/sales/presentation/providers/sales_provider.dart:978
lib/features/sales/presentation/dialogs/ticket_options_dialog.dart:39, 322
lib/core/presentation/dialogs/views/configuration/printer_config_dialog.dart:21
```

**Problema:**
```dart
// ❌ Actual
final printerService = ThermalPrinterHttpService();
```

**Solución:**
```dart
// Opción A: Inyectar en constructor (RECOMENDADO)
class SalesProvider {
  final ThermalPrinterHttpService _printerService;
  
  SalesProvider({required ThermalPrinterHttpService printerService})
      : _printerService = printerService;
}

// Opción B: Usar getIt temporal (TRANSITORIO)
final printerService = getIt<ThermalPrinterHttpService>();
```

#### 2. `CashRegisterProvider` usa `.instance`

**Archivos afectados:**
```
lib/features/cash_register/presentation/providers/cash_register_provider.dart:231, 355, 370
```

**Problema:**
```dart
// ❌ Actual (ya no existe .instance)
final persistenceService = AppDataPersistenceService.instance;
```

**Solución Temporal Aplicada:**
```dart
// ⚠️ Temporal con getIt
final persistenceService = getIt<AppDataPersistenceService>();
```

**Solución Final:**
```dart
// ✅ Inyectar en constructor
@injectable
class CashRegisterProvider extends ChangeNotifier {
  final AppDataPersistenceService _persistence;
  
  CashRegisterProvider(
    // ... otros usecases ...
    this._persistence,
  );
}
```

#### 3. `SalesProvider` falta inyección en constructores

**Archivo:** `lib/main.dart:68, 87`

**Problema:**
```dart
// ❌ Falta parámetro persistenceService
return SalesProvider(
  getUserAccountsUseCase: getIt<GetUserAccountsUseCase>(),
  // ... otros parámetros ...
  catalogueUseCases: catalogueUseCases,
);
```

**Solución:**
```dart
// ✅ Agregar persistenceService
return SalesProvider(
  getUserAccountsUseCase: getIt<GetUserAccountsUseCase>(),
  // ... otros parámetros ...
  persistenceService: getIt<AppDataPersistenceService>(),
  catalogueUseCases: catalogueUseCases,
);
```

#### 4. `ThemeDataAppProvider` y `PrinterProvider` en main.dart

**Archivo:** `lib/main.dart:55, 56`

**Problema:**
```dart
// ❌ No pasan dependencias requeridas
ChangeNotifierProvider(create: (_) => ThemeDataAppProvider()),
ChangeNotifierProvider(create: (_) => PrinterProvider()..initialize()),
```

**Solución:**
```dart
// ✅ Usar getIt para resolver dependencias
ChangeNotifierProvider(
  create: (_) => ThemeDataAppProvider(
    getIt<ThemeService>(),
    getIt<AppDataPersistenceService>(),
  ),
),
ChangeNotifierProvider(
  create: (_) => PrinterProvider(
    getIt<ThermalPrinterHttpService>(),
  )..initialize(),
),
```

## 📋 Plan de Acción

### Fase 1: Arreglar Errores de Compilación (URGENTE)

1. ✅ Actualizar `main.dart` para inyectar dependencias en providers
2. ✅ Migrar usos de `AppDataPersistenceService.instance` en `CashRegisterProvider`
3. ✅ Agregar `persistenceService` a `SalesProvider` en `main.dart`

### Fase 2: Refactorizar Instanciaciones Directas

1. ⚠️ Migrar `SalesProvider` para inyectar `ThermalPrinterHttpService`
2. ⚠️ Migrar `ticket_options_dialog.dart` para recibir servicio por parámetro
3. ⚠️ Migrar `printer_config_dialog.dart` para recibir servicio por parámetro

### Fase 3: Testing y Validación

1. ⚠️ Ejecutar tests unitarios
2. ⚠️ Verificar flujos de impresión
3. ⚠️ Validar persistencia de datos

## 🛠️ Comandos Útiles

```bash
# Regenerar DI
dart run build_runner build --delete-conflicting-outputs

# Ver errores de compilación
flutter analyze

# Buscar usos de .instance
rg "\.instance" lib/

# Buscar instanciaciones directas de servicios
rg "ThermalPrinterHttpService\(\)" lib/
rg "AppDataPersistenceService\(\)" lib/
```

## 📝 Notas

### Patrón de Migración Gradual

Estamos aplicando una **estrategia de migración gradual por feature**:

1. ✅ **Auth** → Migrado completamente
2. ⚠️ **Sales** → En progreso (falta refactorizar instanciaciones)
3. ⚠️ **CashRegister** → En progreso (usa getIt temporal)
4. ⏳ **Catalogue** → Pendiente
5. ⏳ **MultiUser** → Pendiente

### Beneficios Logrados

- **Testabilidad:** Servicios ahora son mockeables
- **Mantenibilidad:** Dependencias explícitas
- **Consistencia:** Un solo patrón de DI en todo el proyecto
- **Performance:** SharedPreferences se resuelve una sola vez

### Código Deprecated Eliminado

- ❌ `database_cloud.dart` - God Object con métodos estáticos
- ❌ `storage_service.dart` - Wrapper con métodos deprecated
- ❌ Directorio `core/services/printing/` - Provider mal ubicado

## 🎯 Meta Final

**Eliminar completamente el uso de:**
- ❌ `.instance` (singleton manual)
- ❌ Instanciaciones directas `new Service()`
- ❌ `getIt<>()` en código de negocio (solo en composition root)

**Usar exclusivamente:**
- ✅ Inyección de dependencias en constructores
- ✅ Anotaciones `@injectable`, `@lazySingleton`, etc.
- ✅ `getIt<>()` SOLO en `main.dart` y archivos de setup
