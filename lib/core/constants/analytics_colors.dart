import 'package:flutter/material.dart';

/// Constantes: Colores de Tarjetas de Analíticas
///
/// **Responsabilidad:**
/// - Centralizar la paleta de colores de las tarjetas de analíticas
/// - Facilitar la actualización y mantenimiento del esquema de colores
/// - Garantizar consistencia visual entre tarjetas y modales
///
/// **Esquema de Colores:**
/// - 🟢 Finanzas: Verdes y violetas (crecimiento y valor)
/// - 🔵 Operativo: Azules (datos y volumen)
/// - 🟠 Alertas: Naranjas, rojos y verdes (atención y estado)
/// - 🟡 Clasificación: Amarillos, magentas, grises y cianes (categorías)
class AnalyticsColors {
  AnalyticsColors._(); // Prevenir instanciación

  // ========== 🟢 FINANZAS (Crecimiento y Valor) ==========
  /// Verde Bosque - Facturación
  static const Color billing = Color(0xFF10B981);

  /// Verde Esmeralda - Ganancia
  static const Color profit = Color(0xFF059669);

  /// Violeta - Rentabilidad
  static const Color profitability = Color(0xFF8B5CF6);

  /// Turquesa - Ticket Promedio
  static const Color averageTicket = Color(0xFF14B8A6);

  // ========== 🔵 OPERATIVO (Datos y Volumen) ==========
  /// Azul Real - Ventas
  static const Color sales = Color(0xFF3B82F6);

  /// Azul Índigo - Productos Vendidos
  static const Color products = Color(0xFF6366F1);

  /// Azul Eléctrico - Tendencia de Ventas
  static const Color salesTrend = Color(0xFF0EA5E9);

  // ========== 🟠 ALERTAS Y ESTADO (Atención) ==========
  /// Naranja/Ámbar - Lenta Rotación (Precaución)
  static const Color slowMoving = Color(0xFFF59E0B);

  /// Rojo Coral - Horas Pico (Intensidad)
  static const Color peakHours = Color(0xFFF43F5E);

  /// Azul - Cajas Activas (Estado Online)
  static const Color cashRegisters = Color.fromARGB(255, 74, 92, 171);

  // ========== 🟡 CLASIFICACIÓN (Categorías y Tiempo) ==========
  /// Amarillo Oro - Ranking de Vendedores
  static const Color sellerRanking = Color(0xFFEAB308);

  /// Magenta - Categorías
  static const Color categories = Color(0xFFD946EF);

  /// Gris Azulado - Medios de Pago
  static const Color paymentMethods = Color(0xFF64748B);

  /// Cian - Días de Venta
  static const Color weekdaySales = Color(0xFF06B6D4);

  // ========== 💳 MÉTODOS DE PAGO ==========
  /// Verde - Efectivo
  static const Color paymentCash = Color(0xFF4CAF50);

  /// Azul - Transferencia
  static const Color paymentTransfer = Color(0xFF2196F3);

  /// Naranja - Tarjeta
  static const Color paymentCard = Color(0xFFFF9800);

  /// Púrpura - QR
  static const Color paymentQR = Color(0xFF9C27B0);

  /// Gris - Sin Especificar
  static const Color paymentUnspecified = Color(0xFF9E9E9E);
}
