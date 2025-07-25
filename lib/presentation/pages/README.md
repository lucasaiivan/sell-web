# Páginas de la Aplicación

Esta carpeta contiene las páginas principales de la aplicación Flutter Web de ventas.

## Archivos

### `sell_page.dart`
Página principal de ventas que implementa el punto de venta completo.

**Contexto**: Página central donde se realizan todas las ventas, con acceso al catálogo de productos, gestión de tickets y procesamiento de pagos.

**Propósito**: 
- Mostrar y gestionar el catálogo de productos
- Procesamiento de ventas y tickets
- Integración con cajas registradoras
- Gestión de métodos de pago
- Vista de pantalla completa para selección de productos con buscador dinámico

**Uso**: 
- Interfaz responsive para móvil, tablet y desktop
- Búsqueda de productos por código de barras
- Modal de pantalla completa para catálogo con buscador inteligente
- Gestión de estado con Provider pattern

**Componentes principales**:
- `_SellPageState`: Estado principal de la página de ventas
- `_ProductCatalogueFullScreenView`: Vista de pantalla completa para mostrar el catálogo con buscador dinámico

### `login_page.dart`
Página de inicio de sesión con Firebase Auth y Google Sign-In.

**Contexto**: Primera página que ve el usuario para autenticarse en la aplicación.

**Propósito**: Gestionar la autenticación de usuarios con múltiples métodos de login.

**Uso**: Entrada principal a la aplicación, manejo de sesiones de usuario.

### `welcome_page.dart`
Página de bienvenida y selección de cuenta de negocio.

**Contexto**: Página intermedia después del login para seleccionar cuenta de trabajo.

**Propósito**: Permitir al usuario seleccionar la cuenta de negocio con la que desea trabajar.

**Uso**: Transición entre autenticación y página principal de ventas.

## Patrones de Diseño

- **Clean Architecture**: Separación clara entre UI, lógica de negocio y datos
- **Provider Pattern**: Gestión de estado reactiva
- **Material Design 3**: Componentes UI modernos y consistentes
- **Responsive Design**: Adaptación automática a diferentes tamaños de pantalla

## Funcionalidades Destacadas

### Vista de Catálogo de Pantalla Completa
- **Búsqueda centrada**: Campo de búsqueda inicial centrado en pantalla
- **Transición animada**: Al escribir, el campo se mueve a la parte superior
- **Búsqueda en tiempo real**: Filtrado instantáneo por nombre, marca o código
- **Interfaz Material 3**: Diseño moderno con animaciones fluidas
- **Estado visual**: Indicadores de productos seleccionados en el ticket
