# Sistema de Excepciones - Core

## Descripción

Sistema centralizado de manejo de excepciones, logging y notificación de errores para la aplicación Flutter. Proporciona una arquitectura robusta para capturar, procesar y presentar errores de manera consistente.

## Arquitectura

### Componentes Principales

1. **AppExceptions** (`app_exceptions.dart`)
   - Jerarquía de excepciones tipadas específicas para la aplicación
   - Factory methods para crear excepciones comunes
   - Contexto adicional para debugging

2. **ErrorHandler** (`error_handler.dart`)
   - Manejador centralizado de errores
   - Estrategias de recuperación automática
   - Integración con UI para notificaciones

3. **AppLogger** (`app_logger.dart`)
   - Sistema de logging multi-destino
   - Rotación automática de archivos
   - Niveles de logging configurables

## Tipos de Excepciones

### Excepciones de Dominio

- **ValidationException**: Errores de validación de datos
- **BusinessLogicException**: Violaciones de reglas de negocio
- **ConflictException**: Conflictos de datos (duplicados, etc.)

### Excepciones de Infraestructura

- **NetworkException**: Errores de conectividad
- **DatabaseException**: Errores de base de datos
- **FileException**: Errores de archivos/storage
- **DeviceException**: Errores de hardware/dispositivos

### Excepciones de Autenticación

- **AuthException**: Errores de autenticación
- **AuthorizationException**: Errores de autorización/permisos

### Excepciones Técnicas

- **ParseException**: Errores de parsing/formato
- **ConfigurationException**: Errores de configuración
- **TimeoutException**: Timeouts de operaciones
- **NotFoundException**: Recursos no encontrados

## Uso

### Crear Excepciones

```dart
// Usando factory methods (recomendado)
throw AppExceptions.requiredField('email');
throw AppExceptions.insufficientStock('Producto A', 5, 10);

// Creación directa
throw ValidationException(
  'El email es inválido',
  field: 'email',
  value: invalidEmail,
);
```

### Manejo de Errores

```dart
// Configuración inicial
ErrorHandler.initialize(
  logger: createErrorLogger(),
  notifier: showUserNotification,
);

// Manejo automático
try {
  await someOperation();
} catch (error, stackTrace) {
  final result = ErrorHandler.instance.handleError(
    error,
    stackTrace: stackTrace,
    context: ErrorContext(
      userId: currentUser.id,
      screen: 'ProductList',
      action: 'loadProducts',
    ),
  );
  
  if (result.shouldRetry ?? false) {
    // Implementar retry logic
  }
}

// Con extensión para Futures
final result = await someAsyncOperation().handleErrors(
  context: ErrorContext(screen: 'HomePage'),
);
```

### Configuración de Logging

```dart
// Desarrollo
LoggerConfig.development();

// Producción
LoggerConfig.production();

// Personalizado
AppLogger.initialize(
  destinations: [
    const ConsoleLogDestination(),
    FileLogDestination(maxFileSizeBytes: 1024 * 1024 * 5),
    MemoryLogDestination(maxEntries: 1000),
  ],
  minLevel: LogLevel.warning,
);

// Uso
AppLogger.instance.info('Operation completed');
AppLogger.instance.error('Failed to load data', error: exception);
```

### ErrorBoundary para Widgets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary.wrapBuilder(
      (context) => RiskyWidget(),
      errorBuilder: (context, error, stackTrace) => ErrorWidget(),
      errorContext: ErrorContext(screen: 'MyWidget'),
    )(context, null);
  }
}
```

## Configuración por Entorno

### Desarrollo
- Logging completo a consola
- Buffer en memoria para debugging
- Nivel mínimo: debug

### Testing
- Solo logging en memoria
- Sin archivos ni consola
- Nivel mínimo: info

### Producción
- Logging a archivos con rotación
- Solo errores/warnings
- Sin logging de debug

## Integración con Clean Architecture

### Presentación
- ErrorBoundary para UI
- Notificaciones de usuario
- Mapeo de errores a mensajes

### Dominio
- BusinessLogicException para reglas de negocio
- ValidationException para entidades
- Excepciones específicas de use cases

### Datos
- NetworkException para APIs
- DatabaseException para persistencia
- ParseException para mappers

## Mejores Prácticas

### 1. Especificidad
```dart
// ✅ Específico y útil
throw AppExceptions.insufficientStock(productName, available, requested);

// ❌ Genérico y poco útil
throw Exception('Error');
```

### 2. Contexto
```dart
// ✅ Con contexto
ErrorHandler.instance.handleError(
  error,
  context: ErrorContext(
    userId: user.id,
    screen: 'ProductEdit',
    action: 'saveProduct',
    metadata: {'productId': product.id},
  ),
);
```

### 3. Recovery
```dart
// ✅ Manejo con recovery
final result = ErrorHandler.instance.handleError(error);
if (result.shouldRetry ?? false) {
  await Future.delayed(result.retryDelay ?? Duration(seconds: 1));
  return await retryOperation();
}
```

### 4. Logging Estructurado
```dart
// ✅ Con metadatos
AppLogger.instance.error(
  'Failed to process payment',
  tag: 'Payment',
  error: exception,
  metadata: {
    'amount': payment.amount,
    'currency': payment.currency,
    'paymentMethod': payment.method,
  },
);
```

## Monitoreo y Debugging

### Acceso a Logs
```dart
// Obtener logs del archivo
final fileDestination = AppLogger.instance.destinations
    .whereType<FileLogDestination>()
    .first;
final logs = await fileDestination.getLogs();

// Obtener logs de memoria
final memoryDestination = AppLogger.instance.destinations
    .whereType<MemoryLogDestination>()
    .first;
final errorEntries = memoryDestination.getEntriesByLevel(LogLevel.error);
```

### Métricas de Errores
- Contar errores por tipo
- Tracking de recovery success rate
- Monitoreo de timeouts y retries

## Extensibilidad

### Nuevos Tipos de Excepción
1. Heredar de `AppException`
2. Agregar al factory `AppExceptions`
3. Configurar manejo en `ErrorHandler`

### Nuevos Destinos de Logging
1. Implementar `LogDestination`
2. Agregar a configuración de `AppLogger`
3. Considerar performance y threading

### Integración Externa
- Crashlytics/Sentry para errores remotos
- Analytics para métricas de errores
- APM tools para performance monitoring
