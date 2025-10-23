# Light Instructions - Flutter Web Sell App

## 🎯 Guía Rápida para Componentes

### Estructura del Proyecto
```
lib/
├── core/                           # Servicios y utilidades compartidas
│   ├── config/                     # Configuraciones globales
│   │   ├── app_config.dart         # Configuración de la app
│   │   ├── firebase_options.dart   # Configuración Firebase
│   │   └── oauth_config.dart       # Configuración OAuth
│   ├── constants/                  # Constantes globales
│   │   ├── app_constants.dart      # Constantes de la app
│   │   └── shared_prefs_keys.dart  # Claves SharedPreferences
│   ├── mixins/                     # Mixins reutilizables
│   ├── services/                   # Servicios compartidos
│   │   ├── database/               # Servicios de base de datos
│   │   │   └── database_cloud.dart # Firebase Firestore
│   │   ├── external/               # Servicios externos
│   │   │   └── thermal_printer_http_service.dart
│   │   ├── storage/                # Almacenamiento local
│   │   │   └── app_data_persistence_service.dart
│   │   ├── search_catalogue_service.dart
│   │   └── theme_service.dart
│   ├── utils/                      # Utilidades y helpers
│   │   ├── formatters/             # Formateadores (fecha, moneda)
│   │   ├── helpers/                # Helpers especializados 
│   └── core.dart                   # Exportaciones centralizadas
│
├── data/                           # Implementaciones de repositorios
│   ├── account_repository_impl.dart
│   ├── auth_repository_impl.dart
│   ├── cash_register_repository_impl.dart
│   └── catalogue_repository_impl.dart
│
├── domain/                         # Entidades, repositorios, casos de uso
│   ├── entities/                   # Modelos de dominio
│   │   ├── cash_register_model.dart
│   │   ├── catalogue.dart
│   │   ├── ticket_model.dart
│   │   └── user.dart
│   ├── repositories/               # Contratos de repositorios
│   │   ├── account_repository.dart
│   │   ├── auth_repository.dart
│   │   ├── cash_register_repository.dart
│   │   └── catalogue_repository.dart
│   └── usecases/                   # Casos de uso de negocio
│       ├── account_usecase.dart
│       ├── auth_usecases.dart
│       ├── cash_register_usecases.dart
│       ├── catalogue_usecases.dart
│       └── sell_usecases.dart
│
└── presentation/                   # UI - páginas, providers, widgets
    ├── pages/                      # Páginas principales
    │   ├── login_page.dart
    │   ├── presentation_page.dart
    │   └── sell_page.dart
    ├── providers/                  # Estado con Provider
    │   ├── auth_provider.dart
    │   ├── cash_register_provider.dart
    │   ├── catalogue_provider.dart
    │   ├── printer_provider.dart
    │   ├── sell_provider.dart
    │   └── theme_data_app_provider.dart
    └── widgets/                    # Componentes UI reutilizables
        ├── buttons/                # Botones especializados
        │   ├── app_bar_button.dart
        │   ├── app_button.dart
        │   ├── app_floating_action_button.dart
        │   ├── app_text_button.dart
        │   ├── search_button.dart
        │   ├── theme_control_buttons.dart
        │   └── buttons.dart        # Exportaciones centralizadas
        ├── component/              # Componentes básicos reutilizables
        │   ├── avatar_product.dart
        │   ├── dividers.dart
        │   ├── image.dart
        │   ├── progress_indicators.dart
        │   ├── responsive_helper.dart
        │   ├── user_avatar.dart
        │   └── ui.dart             # Exportaciones centralizadas
        ├── dialogs/                # Diálogos modales especializados
        │   ├── base/               # Componentes base para diálogos
        │   ├── catalogue/          # Diálogos del catálogo
        │   ├── components/         # Componentes de diálogos
        │   ├── configuration/      # Diálogos de configuración
        │   ├── examples/           # Ejemplos y plantillas
        │   ├── feedback/           # Diálogos de feedback
        │   ├── sales/              # Diálogos de ventas
        │   ├── tickets/            # Diálogos de tickets
        │   └── dialogs.dart        # Exportaciones centralizadas
        ├── feedback/               # Estados de carga y errores
        │   ├── auth_feedback_widget.dart
        │   └── feedback.dart       # Exportaciones centralizadas
        ├── inputs/                 # Campos de entrada especializados
        │   ├── input_text_field.dart
        │   ├── money_input_text_field.dart
        │   ├── product_search_field.dart
        │   └── inputs.dart         # Exportaciones centralizadas
        ├── navigation/             # Componentes de navegación
        │   ├── drawer_ticket/      # Drawer específico de tickets
        │   └── navigation.dart     # Exportaciones centralizadas
        ├── responsive/             # Componentes responsive
        │   ├── responsive_helper.dart
        │   └── README.md
        ├── views/                  # Vistas complejas reutilizables
        │   ├── search_catalogue_full_screen_view.dart
        │   ├── welcome_selected_account_page.dart
        │   └── views.dart          # Exportaciones centralizadas
        └── core_widgets.dart       # Exportaciones centralizadas de widgets
```

## 📏 Buenas Prácticas  ⚡ Reglas Rápidas

### 🚨 REGLA DE ORO: REUTILIZAR ANTES DE CREAR
**ANTES** de crear cualquier componente nuevo:
1. ✅ **Revisa** `presentation/widgets/` y sus subcarpetas
2. ✅ **Verifica** los archivos de exportación (`.dart`) en cada carpeta
3. ✅ **Consulta** `core_widgets.dart` para todos los widgets disponibles
4. ✅ **Busca** en `core/services/` para servicios,metodos,etc. existentes

### 📋 Checklist Obligatorio
- [ ] ¿Existe un botón similar en `buttons/`? → Usar `AppButton`, `AppTextButton`, etc.
- [ ] ¿Necesitas un input? → Usar `InputTextField`, `MoneyInputTextField`, etc.
- [ ] ¿Requieres un diálogo? → Revisar `dialogs/base/` y subcarpetas
- [ ] ¿Es un componente básico? → Verificar `component/` (avatars, imágenes, etc.)
- [ ] ¿Necesitas feedback? → Usar widgets de `feedback/`
- [ ] ¿Es responsive? → Usar `responsive_helper.dart`

### 🎯 Flujo de Trabajo
```
1. ANALIZAR → ¿Qué necesito crear?
2. BUSCAR → ¿Ya existe algo similar?
3. REUTILIZAR → Usar componente existente
4. EXTENDER → Solo si es necesario, extender el existente
5. CREAR → Como último recurso, crear nuevo componente
6. EXPORTAR → Agregar a archivo .dart correspondiente
```

### 💡 Reglas Adicionales
1. **Responsive first**: Considerar mobile, tablet, desktop SIEMPRE
2. **Material Design 3**: Usar componentes y colores del tema
3. **Provider pattern**: Consumer para UI, Provider.of para acciones
4. **Clean imports**: Agrupar imports (dart, flutter, packages, local)
5. **Documentar**: Agregar o actualiza el README.md local y el padre para mantener siempre todo actualizado loas README.md

## 📁 Dónde Crear Qué

### README (obligatorio): archivo de documentación para cada carpeta
actualizar o crear en cada carpeta debe contener un archivo README.md con y solo el formato (Descripcion,Contenido(lista en arbol con descripcion)) , crear un documentacion mas extensa si es realmente necesario que se tenga que explicar algun archivo .dart implementado

### 🔍 PRIMERO: Componentes Existentes Disponibles

| Tipo | Componentes Disponibles | Ubicación |
|------|------------------------|-----------|
| **Botones** | `AppButton`, `AppTextButton`, `AppFloatingActionButton`, `AppBarButton`, `SearchButton`, `ThemeControlButtons` | `buttons/` |
| **Inputs** | `InputTextField`, `MoneyInputTextField`, `ProductSearchField` | `inputs/` |
| **Componentes básicos** | `UserAvatar`, `AvatarProduct`, `ImageWidget`, `ProgressIndicators`, `Dividers` | `component/` |
| **Feedback** | `AuthFeedbackWidget` + widgets de feedback general | `feedback/` |
| **Responsive** | `responsive_helper` | `helpers/` |
| **Navegación** | Componentes drawer, navigation helpers | `navigation/` |
| **Vistas** | `SearchCatalogueFullScreenView`, `WelcomeSelectedAccountPage` | `views/` |
| **Diálogos** | Sistema completo con base, catalogue, sales, tickets, etc. | `dialogs/` |

### 🆕 Solo Si NO Existe: Crear Nuevo

| Tipo de Componente | Ubicación | Ejemplo | Exportar en |
|-------------------|-----------|---------|-------------|
| Botón especializado | `presentation/widgets/buttons/` | `AddToCartButton` | `buttons.dart` |
| Campo de entrada específico | `presentation/widgets/inputs/` | `CategoryInput` | `inputs.dart` |
| Diálogo nuevo dominio | `presentation/widgets/dialogs/[dominio]/` | `InventoryDialog` | `dialogs.dart` |
| Card/Lista específica | `presentation/widgets/component/` | `ProductCard` | `ui.dart` |
| Feedback especializado | `presentation/widgets/feedback/` | `SalesFeedback` | `feedback.dart` |
| Vista compleja | `presentation/widgets/views/` | `DashboardView` | `views.dart` |
| Servicio nuevo | `core/services/[categoria]/` | `NotificationService` | `core.dart` |
| Utilidad específica | `core/utils/[categoria]/` | `CurrencyFormatter` | Crear exportador |

### ⚠️ IMPORTANTE: Proceso de Creación
1. **Verificar** que NO existe componente similar
2. **Crear** en la ubicación apropiada
3. **Exportar** en el archivo `.dart` correspondiente de la carpeta
4. **Documentar** en README.md si es significativo
5. **Actualizar** `core_widgets.dart` si es widget reutilizable

---

## 🎯 Ejemplos de Uso de Componentes Existentes

### Usar Botones Existentes
```dart
// ✅ CORRECTO - Usar botones existentes
AppButton(
  onPressed: () => _handleAction(),
  text: 'Agregar al Carrito',
  icon: Icons.add_shopping_cart,
)

// ❌ INCORRECTO - Crear botón desde cero
ElevatedButton(...)
```

### Usar Inputs Existentes
```dart
// ✅ CORRECTO - Usar input especializado
MoneyInputTextField(
  controller: _priceController,
  label: 'Precio',
  onChanged: (value) => _updatePrice(value),
)

// ❌ INCORRECTO - Crear input genérico
TextFormField(...)
```

### Usar Diálogos Existentes
```dart
// ✅ CORRECTO - Reutilizar sistema de diálogos
showDialog(
  context: context,
  builder: (context) => BaseDialog(
    title: 'Confirmar Acción',
    content: Text('¿Estás seguro?'),
    actions: [/* usar botones existentes */],
  ),
)
```

---
**🔥 Recuerda**: 
- **Clean Architecture** es la base del proyecto
- **Provider** para gestión de estado global
- **Reutilizar SIEMPRE** antes de crear
- **Material Design 3** para consistencia visual
- **Responsive Design** en todos los componentes
