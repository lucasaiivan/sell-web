# Diálogos - Material Design 3 UI System

## 📋 Propósito
Sistema completo de diálogos que implementa Material Design 3 con componentes reutilizables y consistencia visual en toda la aplicación. Sigue los principios de Clean Architecture y proporciona una experiencia de usuario cohesiva.

## 🏗️ Arquitectura del Sistema

### **Componentes Base**
- `base_dialog.dart` - **NUEVO** - Diálogo base con estructura estándar MD3
- `standard_dialogs.dart` - **NUEVO** - Diálogos predefinidos (confirmación, error, info, carga)
- `dialog_components.dart` - **NUEVO** - Componentes UI reutilizables para diálogos complejos
- `example_modern_dialog.dart` - **NUEVO** - Ejemplos de implementación y migración

### **Guías y Documentación**
- `DIALOG_DESIGN_GUIDE.md` - **NUEVO** - Guía completa de diseño Material Design 3
- `README.md` - Este archivo - Documentación técnica completa

### **Diálogos Específicos** (Legacy - En proceso de migración)
- `add_product_dialog.dart` - Diálogo para agregar/crear productos al catálogo
- `product_edit_dialog.dart` - Diálogo de edición de productos existentes
- `quick_sale_dialog.dart` - Diálogo de venta rápida por monto fijo
- `ticket_options_dialog.dart` - Opciones de ticket (PDF, impresión, compartir)
- `printer_config_dialog.dart` - Configuración de impresora térmica
- `last_ticket_dialog.dart` - Visualización y reimpresión del último ticket

### **Archivo de Exports**
- `dialogs.dart` - Centraliza todas las exportaciones y funciones helper

## � Sistema de Diseño Material Design 3

### **Nuevos Estándares Implementados**

#### **BaseDialog - Estructura Estándar**
```dart
BaseDialog(
  title: 'Título Descriptivo',
  icon: Icons.icon_rounded, // Iconos con sufijo _rounded
  width: 450, // Ancho específico o adaptativo
  content: Widget(), // Contenido principal
  actions: [
    // Botones de acción estándar
    TextButton(onPressed: () {}, child: Text('Cancelar')),
    FilledButton(onPressed: () {}, child: Text('Confirmar')),
  ],
)
```

#### **Componentes Estándar Reutilizables**
- **Secciones de información** con contenedores estilizados
- **Listas de elementos** con divisores opcionales
- **Campos de formulario** consistentes
- **Botones de acción** primarios y secundarios
- **Contenedores de resumen** destacados
- **Badges informativos** y chips

#### **Temas y Colores**
- **Header**: `primaryContainer` / `errorContainer` para destructivos
- **Superficie**: `surface` con sombras Material Design 3
- **Botones**: `FilledButton` para primarios, `OutlinedButton` para secundarios
- **Soporte completo** para modo claro/oscuro
## 🚀 Guía de Implementación

### **Para Nuevos Diálogos**
1. **Usar BaseDialog** como estructura base
2. **Aplicar DialogComponents** para elementos complejos
3. **Seguir convenciones** de iconografía Material Design 3
4. **Implementar helper functions** para facilitar el uso

### **Patrón Estándar para Diálogos Simples**
```dart
// Diálogo de confirmación
final result = await showConfirmationDialog(
  context: context,
  title: 'Eliminar Producto',
  message: '¿Estás seguro de que deseas eliminar este producto?',
  isDestructive: true,
);

// Diálogo de información
await showInfoDialog(
  context: context,
  title: 'Operación Exitosa',
  message: 'El producto se ha guardado correctamente.',
);

// Diálogo de error
await showErrorDialog(
  context: context,
  title: 'Error de Conexión',
  message: 'No se pudo conectar con el servidor.',
  details: error.toString(),
);
```

### **Patrón para Diálogos Complejos**
```dart
Future<void> showCustomDialog(BuildContext context) {
  return showBaseDialog(
    context: context,
    title: 'Diálogo Complejo',
    icon: Icons.settings_rounded,
    width: 500,
    content: Column(
      children: [
        DialogComponents.infoSection(
          context: context,
          title: 'Configuración',
          icon: Icons.tune_rounded,
          content: Column(
            children: [
              DialogComponents.textField(
                context: context,
                controller: controller,
                label: 'Configuración',
                prefixIcon: Icons.settings_outlined,
              ),
            ],
          ),
        ),
        DialogComponents.sectionSpacing,
        DialogComponents.summaryContainer(
          context: context,
          label: 'Resultado',
          value: 'Valor calculado',
          icon: Icons.calculate_rounded,
        ),
      ],
    ),
    actions: [
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
      DialogComponents.primaryActionButton(
        context: context,
        text: 'Aplicar',
        icon: Icons.check_rounded,
        onPressed: () => _applyChanges(),
      ),
    ],
  );
}
```

## � Migración de Diálogos Existentes

### **Checklist de Migración**
- [ ] Cambiar base de `AlertDialog` a `BaseDialog`
- [ ] Actualizar iconografía a Material Design 3 (`_rounded` sufijos)
- [ ] Aplicar `DialogComponents` para elementos complejos
- [ ] Usar colores del tema (`colorScheme`)
- [ ] Implementar helper function con prefijo `show`
- [ ] Actualizar exports en `dialogs.dart`
- [ ] Probar en modo claro y oscuro

### **Ejemplo de Migración**
Ver `example_modern_dialog.dart` para ejemplos completos de:
- Migración de diálogos simples
- Implementación de diálogos complejos
- Uso de todos los componentes estándar
- Manejo de estados de carga y errores

## 🎯 Funcionalidades por Diálogo (Legacy)

### **LastTicketDialog** 
- **Contexto**: Muestra el último ticket vendido con acceso a opciones completas
- **Propósito**: Acceso rápido al último ticket desde el AppBar
- **Uso**: Llamado desde el IconButton del último ticket en sell_page.dart
- **Estado**: ✅ Migrado a nuevos estándares

### **AddProductDialog**, **ProductEditDialog**, **QuickSaleDialog**
- **Estado**: 🔄 Pendiente de migración a BaseDialog
- **Prioridad**: Alta - Diálogos críticos del flujo principal

### **TicketOptionsDialog**, **PrinterConfigDialog**
- **Estado**: � Pendiente de migración a BaseDialog
- **Prioridad**: Media - Funcionalidades complementarias

## ⚡ Performance y Optimización

### **Optimizaciones Implementadas**
- **Constructores const** en todos los widgets posibles
- **Lazy loading** de contenido pesado
- **Minimización de rebuilds** con `Consumer` granular
- **Gestión de memoria** apropiada con dispose de controllers

### **Recomendaciones de Uso**
- Usar `showDialog` con `barrierDismissible: false` para operaciones críticas
- Implementar validación en tiempo real en formularios
- Usar `Navigator.of(context).pop()` con valores de retorno apropiados
- Manejar estados de carga con indicadores visuales

## 🔍 Testing y Calidad

### **Áreas de Testing Prioritarias**
- **Responsive**: Verificar en móvil, tablet y desktop
- **Temas**: Probar modo claro y oscuro
- **Accesibilidad**: Navegación por teclado y lectores de pantalla
- **Estados**: Validar carga, error y éxito
- **Formularios**: Validación y manejo de errores

### **Herramientas de Debug**
- Flutter Inspector para análisis de árbol de widgets
- DevTools para monitoreo de performance
- `debugPrint` para logging estructurado
- Análisis estático con `flutter analyze`

## 🛠️ Herramientas y Configuración

### **Dependencias Requeridas**
- `flutter/material.dart` - Componentes base Material Design 3
- `provider` - Gestión de estado cuando sea necesario
- Dependencias del dominio para entidades y repositorios

### **Análisis Estático**
El sistema cumple con las reglas definidas en `analysis_options.yaml`:
- `prefer_const_constructors: true`
- `prefer_const_literals_to_create_immutables: true`
- Nomenclatura consistente en inglés
- Documentación en español para funciones complejas

## 📋 Roadmap de Migración

### **Fase 1: Fundación** ✅ Completada
- [x] Implementar `BaseDialog` con Material Design 3
- [x] Crear `DialogComponents` reutilizables
- [x] Desarrollar `StandardDialogs` predefinidos
- [x] Documentar guía de diseño completa
- [x] Crear ejemplos de migración

### **Fase 2: Migración Critical Path** 🔄 En Progreso
- [ ] Migrar `AddProductDialog` a nuevos estándares
- [ ] Migrar `ProductEditDialog` a BaseDialog
- [ ] Migrar `QuickSaleDialog` con componentes estándar
- [ ] Actualizar tests existentes

### **Fase 3: Migración Complementaria** 📋 Planificada
- [ ] Migrar `TicketOptionsDialog`
- [ ] Migrar `PrinterConfigDialog`
- [ ] Optimizar `LastTicketDialog` con nuevos componentes
- [ ] Implementar accessibility testing

### **Fase 4: Optimización** 🎯 Futura
- [ ] Implementar animaciones Material Design 3
- [ ] Agregar soporte para temas personalizados
- [ ] Optimizar performance en dispositivos de gama baja
- [ ] Implementar analytics de UX en diálogos

## 🔗 Referencias y Recursos

### **Documentación Relacionada**
- `DIALOG_DESIGN_GUIDE.md` - Guía completa de diseño
- `example_modern_dialog.dart` - Ejemplos prácticos
- Material Design 3 Guidelines
- Flutter Documentation - DialogRoute

### **Componentes Relacionados**
- `../buttons/` - Botones estándar de la aplicación
- `../inputs/` - Campos de formulario complementarios
- `../feedback/` - Componentes de retroalimentación
- `../../utils/` - Utilidades de formateo y validación

---

**Última actualización**: Julio 2025 - Sistema completo Material Design 3
**Mantenido por**: Equipo de desarrollo siguiendo Clean Architecture y MD3
