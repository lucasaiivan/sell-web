/// Constantes para datos demo del modo invitado
///
/// Este archivo centraliza todas las constantes estáticas utilizadas
/// para generar datos de prueba coherentes y realistas para el modo demo.
///
/// **Estructura:**
/// - Categorías de productos (orientadas a supermercado)
/// - Marcas organizadas por categoría
/// - Proveedores organizados por categoría
/// - Nombres de productos típicos por categoría

// ==========================================
// CATEGORÍAS
// ==========================================

/// Categorías de productos disponibles (orientadas a supermercado)
const List<String> kDemoCategories = [
  'Lácteos',
  'Carnes y Pescados',
  'Frutas y Verduras',
  'Panadería',
  'Bebidas',
  'Limpieza',
  'Snacks y Dulces',
  'Despensa',
  'Congelados',
  'Perfumería',
  'Bazar',
  'Mascotas',
];

// ==========================================
// MARCAS POR CATEGORÍA
// ==========================================

/// Marcas organizadas por categoría de producto
const Map<String, List<String>> kDemoBrandsByCategory = {
  'Lácteos': ['La Serenísima', 'Sancor', 'Milkaut', 'Ilolay', 'Tregar'],
  'Carnes y Pescados': ['Swift', 'Quickfood', 'Paladini', 'Granja del Sol', 'Paty'],
  'Frutas y Verduras': ['Campo Fresco', 'Huerta Verde', 'Orgánico+', 'Del Campo', 'Freshmart'],
  'Panadería': ['Bimbo', 'Fargo', 'Lactal', 'Ideal', 'Pan Casero'],
  'Bebidas': ['Coca-Cola', 'Pepsi', 'Sprite', 'Villavicencio', 'Cepita'],
  'Limpieza': ['Cif', 'Ayudín', 'Magistral', 'Mr Músculo', 'Odex'],
  'Snacks y Dulces': ['Arcor', 'Cadbury', 'Milka', 'Oreo', 'Terrabusi'],
  'Despensa': ['Marolio', 'Molto', 'Knorr', 'Hellmann\'s', 'Alicante'],
  'Congelados': ['Granja del Sol', 'McCain', 'La Campagnola', 'Frigor', 'Patagonik'],
  'Perfumería': ['Dove', 'Sedal', 'Pantene', 'Colgate', 'Gillette'],
  'Bazar': ['Tramontina', 'Essen', 'Durax', 'Plastirod', 'Bazar Total'],
  'Mascotas': ['Eukanuba', 'Royal Canin', 'Pedigree', 'Whiskas', 'Purina'],
};

// ==========================================
// PROVEEDORES POR CATEGORÍA
// ==========================================

/// Proveedores organizados por categoría de producto
const Map<String, List<String>> kDemoProvidersByCategory = {
  'Lácteos': ['Distribuidora Los Andes', 'Mayorista Sur', 'Distribuidora Central'],
  'Carnes y Pescados': ['Frigorífico del Norte', 'Distribuidora de Carnes Premium', 'Proveedor Central'],
  'Frutas y Verduras': ['Mercado Frutihortícola', 'Distribuidora Verde', 'Proveedor del Campo'],
  'Panadería': ['Panadería Industrial', 'Distribuidora de Panificados', 'Proveedor de Masas'],
  'Bebidas': ['Distribuidora de Bebidas SA', 'Mayorista Refrescos', 'Proveedor Central'],
  'Limpieza': ['Distribuidora de Limpieza Total', 'Mayorista Productos de Limpieza', 'Proveedor Industrial'],
  'Snacks y Dulces': ['Distribuidora de Golosinas', 'Mayorista Dulces y Snacks', 'Proveedor de Alfajores'],
  'Despensa': ['Distribuidora de Alimentos Secos', 'Mayorista Despensa', 'Proveedor Central'],
  'Congelados': ['Distribuidora de Congelados', 'Frigorífico Industrial', 'Mayorista Frío'],
  'Perfumería': ['Distribuidora de Cosméticos', 'Mayorista Perfumería', 'Proveedor de Higiene'],
  'Bazar': ['Distribuidora de Bazar', 'Mayorista Plásticos', 'Proveedor de Artículos del Hogar'],
  'Mascotas': ['Distribuidora Veterinaria', 'Mayorista Pet Shop', 'Proveedor de Alimentos para Mascotas'],
};

// ==========================================
// NOMBRES DE PRODUCTOS POR CATEGORÍA
// ==========================================

/// Nombres de productos típicos organizados por categoría
const Map<String, List<String>> kDemoProductNamesByCategory = {
  'Lácteos': [
    'Leche Entera 1L',
    'Leche Descremada 1L',
    'Yogur Natural 190g',
    'Yogur con Frutas 190g',
    'Queso Cremoso 200g',
    'Queso Rallado 100g',
    'Manteca 200g',
    'Crema de Leche 200ml',
  ],
  'Carnes y Pescados': [
    'Carne Picada 500g',
    'Pollo Entero kg',
    'Milanesas de Pollo 400g',
    'Hamburguesas x4',
    'Chorizo Parrillero kg',
    'Salchichas x6',
    'Atún en Lata 170g',
    'Filet de Merluza 400g',
  ],
  'Frutas y Verduras': [
    'Manzanas Rojas kg',
    'Bananas kg',
    'Tomates kg',
    'Lechuga Unidad',
    'Papas kg',
    'Cebollas kg',
    'Naranjas kg',
    'Zanahoria kg',
  ],
  'Panadería': [
    'Pan de Molde Blanco',
    'Pan Integral',
    'Medialunas x6',
    'Facturas Surtidas x6',
    'Pan Francés Unidad',
    'Pan Rallado 500g',
    'Galletas de Agua x3',
    'Bizcochos x12',
    'Tostadas x24',
  ],
  'Bebidas': [
    'Gaseosa Cola 2.25L',
    'Agua Mineral 2L',
    'Jugo de Naranja 1L',
    'Gaseosa Lima-Limón 1.5L',
    'Agua con Gas 1.5L',
    'Cerveza Lata 473ml',
    'Vino Tinto 750ml',
    'Soda 2.25L',
  ],
  'Limpieza': [
    'Detergente Líquido 750ml',
    'Lavandina 1L',
    'Limpiador Multiuso 500ml',
    'Jabón en Polvo 800g',
    'Suavizante 1L',
    'Limpiavidrios 500ml',
    'Esponjas x3',
    'Bolsas de Basura x10',
  ],
  'Snacks y Dulces': [
    'Papas Fritas 200g',
    'Galletitas Chocolate 150g',
    'Alfajores x3',
    'Chocolate con Leche 100g',
    'Caramelos Mix 150g',
    'Maní Salado 200g',
    'Palitos 100g',
    'Turrones x6',
  ],
  'Despensa': [
    'Arroz 1kg',
    'Fideos Secos 500g',
    'Aceite Girasol 900ml',
    'Azúcar 1kg',
    'Harina 000 1kg',
    'Sal Fina 500g',
    'Puré de Tomate 520g',
    'Atún al Natural 170g',
  ],
  'Congelados': [
    'Pizza Muzzarella 650g',
    'Papas Fritas Congeladas 1kg',
    'Empanadas de Carne x12',
    'Medallones de Pollo 400g',
    'Helado Frutilla 1L',
    'Helado Chocolate 1L',
    'Tapa de Empanadas x12',
    'Vegetales Mixtos 500g',
    'Hamburguesas Congeladas x6',
  ],
  'Perfumería': [
    'Shampoo 400ml',
    'Acondicionador 400ml',
    'Jabón de Tocador x3',
    'Crema Dental 90g',
    'Desodorante Aerosol 150ml',
    'Jabón Líquido Manos 250ml',
    'Papel Higiénico Doble Hoja x6',
    'Pañuelos Descartables x100',
    'Afeitadora Descartable x3',
  ],
  'Bazar': [
    'Platos Descartables x20',
    'Vasos Descartables x50',
    'Servilletas de Papel x100',
    'Bolsas Plásticas x50',
    'Film Transparente 30m',
    'Papel Aluminio 10m',
    'Cubiertos Descartables x20',
    'Velas x6',
    'Fósforos Largos',
  ],
  'Mascotas': [
    'Alimento para Perro 3kg',
    'Alimento para Gato 1.5kg',
    'Arena para Gato 5kg',
    'Snack para Perro 200g',
    'Huesos de Carnaza x3',
    'Piedras Sanitarias 3kg',
    'Alimento Premium Perro 1kg',
    'Alimento Premium Gato 500g',
  ],
};

// ==========================================
// DESCRIPCIONES POR CATEGORÍA
// ==========================================

/// Descripciones genéricas para productos según categoría
const Map<String, String> kDemoProductDescriptions = {
  'Lácteos': 'Producto lácteo fresco de alta calidad, ideal para toda la familia.',
  'Carnes y Pescados': 'Carne fresca seleccionada, refrigerada y lista para cocinar.',
  'Frutas y Verduras': 'Producto fresco del campo, seleccionado diariamente.',
  'Panadería': 'Pan fresco elaborado artesanalmente todos los días.',
  'Bebidas': 'Bebida refrescante para acompañar tus comidas.',
  'Limpieza': 'Producto de limpieza efectivo para mantener tu hogar impecable.',
  'Snacks y Dulces': 'Snack delicioso para disfrutar en cualquier momento.',
  'Despensa': 'Producto esencial para tu cocina, de calidad garantizada.',
  'Congelados': 'Producto congelado de calidad premium, listo para preparar.',
  'Perfumería': 'Producto de higiene personal para tu cuidado diario.',
  'Bazar': 'Artículo práctico para el hogar y eventos.',
  'Mascotas': 'Alimento y accesorios de calidad para tu mascota.',
};
