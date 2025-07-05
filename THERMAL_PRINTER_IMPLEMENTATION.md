# Implementación de Impresora Térmica USB

Este documento describe la implementación del paquete `usb_thermal_printer_web_pro` en el proyecto sell-web.

## Investigación del Paquete

### Compatibilidad
- ✅ **Windows**: Compatible a través de Flutter Web
- ✅ **macOS**: Compatible a través de Flutter Web  
- ✅ **Flutter Web**: Soporte completo
- ❌ **Mobile**: No compatible (solo web)

### Características del Paquete
- **Versión**: 0.1.2
- **Publisher**: spoon.green (verificado)
- **Dependencias**: flutter, usb_device
- **Licencia**: BSD-3-Clause

### Funcionalidades Implementadas
1. **printText**: Impresión de texto con opciones de formato (negrita, alineación, tamaño)
2. **printKeyValue**: Impresión en formato clave-valor
3. **printFlex**: Impresión tabular con flexibilidad de columnas
4. **printDottedLine**: Líneas punteadas como separadores
5. **printBarcode**: Códigos de barras
6. **printEmptyLine**: Líneas vacías para espaciado

## Archivos Creados/Modificados

### 1. Servicio Principal
**`lib/core/services/thermal_printer_service.dart`**
- Servicio singleton para manejo de impresoras térmicas
- Configuración automática para tickets (48 caracteres de ancho)
- Gestión de conexión/desconexión
- Funciones de impresión de tickets completos
- Persistencia de configuración con SharedPreferences

### 2. Diálogo de Configuración
**`lib/core/widgets/printer_config_dialog.dart`**
- Interfaz Material 3 para configurar impresoras
- Detección automática de dispositivos USB
- Configuración avanzada opcional (Vendor ID, Product ID)
- Prueba de impresión integrada
- Indicadores visuales de estado de conexión

### 3. Modificaciones en SellPage
**`lib/presentation/pages/sell_page.dart`**
- Ícono de estado de impresora en AppBar (verde si conectada)
- Checkbox "Imprimir ticket" en vista de ticket
- Integración con confirmación de venta
- Manejo de errores con SnackBars

### 4. Extensión del Provider
**`lib/presentation/providers/sell_provider.dart`**
- Nueva propiedad `shouldPrintTicket`
- Método `setShouldPrintTicket()`
- Persistencia del estado de impresión

### 5. Claves de Configuración
**`lib/core/utils/shared_prefs_keys.dart`**
- Nuevas claves para configuración de impresora:
  - `printerName`
  - `printerVendorId` 
  - `printerProductId`

## Dependencias Agregadas

```yaml
dependencies:
  usb_thermal_printer_web_pro: ^0.1.2
  shared_preferences: ^2.5.3  # (ya existía, actualizada)
```

## Flujo de Uso

### Primera Configuración
1. Usuario hace clic en ícono de impresora (gris) en AppBar
2. Se abre diálogo de configuración
3. Sistema solicita permisos USB del navegador
4. Usuario selecciona impresora térmica de la lista
5. Sistema configura automáticamente parámetros
6. Prueba de impresión opcional

### Impresión de Tickets
1. Usuario agrega productos al ticket
2. Selecciona método de pago
3. Marca checkbox "Imprimir ticket" (si impresora conectada)
4. Confirma venta
5. Sistema imprime ticket automáticamente
6. Muestra confirmación visual

## Características Técnicas

### Configuración de Impresora
- **Ancho de impresión**: 48 caracteres
- **Padding lateral**: 2 caracteres cada lado
- **Formato**: ESC/POS estándar
- **Conexión**: USB directo via WebUSB API

### Formato de Ticket
```
    NOMBRE DEL NEGOCIO
    
      TICKET DE VENTA
      
Fecha: 04/01/2025
Hora: 14:30
Cliente: [Opcional]

--------------------------------
CANT. DESCRIPCIÓN        PRECIO
--------------------------------
1     Producto ejemplo   $10.50
2     Otro producto      $25.00
--------------------------------
                  TOTAL: $35.50

Método de pago: Efectivo
Efectivo recibido: $40.00
Vuelto: $4.50

   Gracias por su compra

    [CÓDIGO DE BARRAS]
```

## Manejo de Errores

### Errores Comunes y Soluciones

1. **"No hay impresora conectada"**
   - Verificar conexión USB
   - Configurar impresora desde AppBar

2. **"Error al conectar impresora"**
   - Reintentar conexión
   - Verificar permisos del navegador
   - Comprobar compatibilidad de impresora

3. **"Error al imprimir ticket"**
   - Verificar papel en impresora
   - Revisar conexión USB
   - Reiniciar impresora

### Depuración
- Logs detallados en modo debug
- Mensajes de error específicos
- Estado de conexión en tiempo real

## Limitaciones Identificadas

1. **Solo Web**: No funciona en aplicaciones móviles nativas
2. **Permisos**: Requiere permiso USB del navegador cada sesión
3. **Compatibilidad**: Depende del soporte WebUSB del navegador
4. **Detección**: Algunos modelos de impresora requieren IDs específicos

## Navegadores Compatibles

- ✅ Chrome 61+
- ✅ Edge 79+
- ✅ Opera 48+
- ❌ Firefox (no soporta WebUSB)
- ❌ Safari (no soporta WebUSB)

## Recomendaciones

### Para Producción
1. Usar Chrome o Edge como navegador principal
2. Configurar IDs de impresora específicos para mejor compatibilidad
3. Documentar modelo de impresora recomendado
4. Implementar fallback manual si la impresión falla

### Para Desarrollo
1. Probar con diferentes modelos de impresoras térmicas
2. Validar formato de ticket en papel real
3. Testear reconexión después de desconexión USB
4. Optimizar timeouts para impresoras lentas

## Próximas Mejoras

1. **Plantillas de ticket personalizables**
2. **Soporte para logos/imágenes**
3. **Configuración de tamaño de papel**
4. **Impresión de reportes de ventas**
5. **Integración con gaveta de dinero**

---

**Nota**: Esta implementación sigue las mejores prácticas de Clean Architecture y Material Design 3 establecidas en el proyecto.
