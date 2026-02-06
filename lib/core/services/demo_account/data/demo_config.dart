/// Configuración para generación de datos demo
///
/// Este archivo centraliza todos los parámetros configurables
/// para la generación de datos de prueba en el modo invitado.

// ==========================================
// CANTIDADES
// ==========================================

/// Cantidad total de productos a generar
const int kDemoProductsCount = 100;

/// Cantidad de usuarios admin a generar
const int kDemoUsersCount = 2;

/// Cantidad de tickets/transacciones mensuales (últimos 30 días)
const int kDemoMonthlyTicketsCount = 150;

/// Cantidad de tickets/transacciones anuales (para analytics)
const int kDemoAnnualTicketsCount = 500;

/// Cantidad de arqueos de caja a generar (últimos N días)
const int kDemoCashRegistersCount = 15;

// ==========================================
// CONFIGURACIÓN DE PRECIOS Y GANANCIAS
// ==========================================

/// Precios base por categoría (en pesos argentinos)
const Map<String, double> kDemoBasePricesByCategory = {
  'Lácteos': 800.0,          // \$500-\$1100
  'Carnes y Pescados': 3500.0, // \$2500-\$4500
  'Frutas y Verduras': 600.0,  // \$400-\$800
  'Panadería': 1200.0,         // \$800-\$1600
  'Bebidas': 900.0,            // \$600-\$1200
  'Limpieza': 1500.0,          // \$1000-\$2000
  'Snacks y Dulces': 700.0,    // \$500-\$900
  'Despensa': 1000.0,          // \$700-\$1300
  'Congelados': 2500.0,        // \$1800-\$3200
  'Perfumería': 1800.0,        // \$1300-\$2300
  'Bazar': 900.0,              // \$600-\$1200
  'Mascotas': 4000.0,          // \$3000-\$5000
};

/// Rangos de porcentaje de ganancia por categoría [min, max]
const Map<String, List<double>> kDemoProfitRangesByCategory = {
  'Lácteos': [15.0, 25.0],          // Margen bajo-medio
  'Carnes y Pescados': [20.0, 35.0], // Margen medio-alto
  'Frutas y Verduras': [30.0, 50.0], // Margen alto
  'Panadería': [40.0, 60.0],         // Margen alto
  'Bebidas': [20.0, 30.0],           // Margen medio
  'Limpieza': [25.0, 40.0],          // Margen medio-alto
  'Snacks y Dulces': [30.0, 45.0],   // Margen medio-alto
  'Despensa': [20.0, 35.0],          // Margen medio
  'Congelados': [25.0, 40.0],        // Margen medio-alto
  'Perfumería': [35.0, 55.0],        // Margen alto
  'Bazar': [40.0, 60.0],             // Margen alto
  'Mascotas': [30.0, 45.0],          // Margen medio-alto
};

/// Variación de precio (porcentaje ±)
const double kDemoPriceVariation = 0.30; // ±30%

// ==========================================
// CONFIGURACIÓN DE STOCK
// ==========================================

/// Opciones de stock disponibles
const List<double> kDemoStockOptions = [5.0, 12.0, 25.0, 50.0, 100.0, 150.0, 200.0];

/// Stock de alerta por defecto
const double kDemoAlertStock = 10.0;

/// Porcentaje de productos marcados como favoritos
const double kDemoFavoritePercentage = 0.20; // 20%

// ==========================================
// CONFIGURACIÓN DE TRANSACCIONES
// ==========================================

/// Rango de tickets por día (entre semana)
const int kDemoMinTicketsPerWeekday = 5;
const int kDemoMaxTicketsPerWeekday = 8;

/// Rango de tickets por día (fines de semana)
const int kDemoMinTicketsPerWeekend = 3;
const int kDemoMaxTicketsPerWeekend = 6;

/// Horario comercial (horas)
const int kDemoOpeningHour = 8;
const int kDemoClosingHour = 22;

/// Rango de productos por ticket
const int kDemoMinProductsPerTicket = 1;
const int kDemoMaxProductsPerTicket = 10;

/// Rango de cantidad por producto en ticket
const int kDemoMinQuantityPerProduct = 1;
const int kDemoMaxQuantityPerProduct = 5;

/// Probabilidad de descuento en ticket
const double kDemoDiscountProbability = 0.10; // 10%

/// Rango de descuento (porcentaje)
const double kDemoMinDiscount = 5.0;
const double kDemoMaxDiscount = 20.0;

/// Distribución de medios de pago (deben sumar 1.0)
const Map<String, double> kDemoPaymentMethodDistribution = {
  'cash': 0.40,      // Efectivo: 40%
  'transfer': 0.30,  // Transferencia: 30%
  'card': 0.20,      // Tarjeta: 20%
  'qr': 0.10,        // QR: 10%
};

// ==========================================
// CONFIGURACIÓN DE TICKETS ANUALES (ANALYTICS)
// ==========================================

/// Distribución temporal de tickets anuales
/// Últimos 2 días: alta densidad
const int kDemoRecentDaysHighDensity = 2;
const int kDemoTicketsPerRecentDay = 50;

/// Días 3-60: densidad media
const int kDemoMediumDensityDays = 58;
const int kDemoTicketsPerMediumDay = 4;

/// Días 61-365: densidad baja
const int kDemoLowDensityDays = 305;

/// Probabilidad de hora pico
const double kDemoPeakHourProbability = 0.60; // 60%

/// Horarios pico (almuerzo y tarde)
const int kDemoLunchPeakStart = 12;
const int kDemoLunchPeakEnd = 14;
const int kDemoEveningPeakStart = 18;
const int kDemoEveningPeakEnd = 21;

/// Porcentaje de productos de lenta rotación
const double kDemoSlowMovingProductsPercentage = 0.15; // 15%

/// Distribución de vendedores
const double kDemoSuperAdminSalesPercentage = 0.60; // 60% superusuario, 40% empleado

// ==========================================
// CONFIGURACIÓN DE CAJA
// ==========================================

/// Rango de efectivo inicial en caja
const double kDemoMinInitialCash = 5000.0;
const double kDemoMaxInitialCash = 10000.0;

/// Rango de flujos de caja entrantes por día
const int kDemoMinCashInFlows = 1;
const int kDemoMaxCashInFlows = 2;

/// Rango de monto de flujo entrante
const double kDemoMinCashInAmount = 100.0;
const double kDemoMaxCashInAmount = 1000.0;

/// Rango de flujos de caja salientes por día
const int kDemoMinCashOutFlows = 0;
const int kDemoMaxCashOutFlows = 2;

/// Rango de monto de flujo saliente
const double kDemoMinCashOutAmount = 50.0;
const double kDemoMaxCashOutAmount = 500.0;

/// Diferencia permitida en balance (±)
const double kDemoCashBalanceDifference = 50.0;

// ==========================================
// CONFIGURACIÓN DE CUENTA DEMO
// ==========================================

/// ID de la cuenta demo
const String kDemoAccountId = 'demo';

/// Nombre del negocio demo
const String kDemoAccountName = 'Negocio de Prueba';

/// País de la cuenta demo
const String kDemoAccountCountry = 'Argentina';

/// Provincia de la cuenta demo
const String kDemoAccountProvince = 'Buenos Aires';

/// Ciudad de la cuenta demo
const String kDemoAccountCity = 'Demo City';

/// Símbolo de moneda
const String kDemoCurrencySymbol = '\$';

/// Duración del trial (días)
const int kDemoTrialDuration = 30;

// ==========================================
// SEED PARA GENERACIÓN DETERMINÍSTICA
// ==========================================

/// Seed para Random (garantiza consistencia en demos)
const int kDemoRandomSeed = 42;
