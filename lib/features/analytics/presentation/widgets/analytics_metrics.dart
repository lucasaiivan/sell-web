import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'metric_card.dart';
import 'products_metric_card.dart';
import 'profitability_metric_card.dart';
import 'seller_ranking_card.dart';
import 'peak_hours_card.dart';
import 'slow_moving_products_card.dart';
import 'payment_methods_card.dart';
import 'active_cash_registers_card.dart';

/// Definición de una métrica card para configuración declarativa
class MetricDefinition {
  final String title;
  final String Function(SalesAnalytics) getValue;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool Function(SalesAnalytics) isZero;

  const MetricDefinition({
    required this.title,
    required this.getValue,
    required this.icon,
    required this.color,
    this.subtitle,
    required this.isZero,
  });
}

/// Configuración de métricas estándar (evita duplicación en layouts)
class AnalyticsMetrics {
  AnalyticsMetrics._();

  // === Colores estándar ===
  static const colorBilling = Color(0xFF059669);
  static const colorProfit = Color(0xFF7C3AED);
  static const colorSales = Color(0xFF2563EB);
  static const colorTicket = Color(0xFF0891B2);
  static const colorProducts = Color(0xFFD97706);
  static const colorProfitability = Color(0xFF10B981);
  static const colorSlowMoving = Color(0xFFEF4444);
  static const colorPeakHours = Color(0xFFF59E0B);
  static const colorSellers = Color(0xFF8B5CF6);

  /// Construye MetricCard de Facturación
  static Widget billing(SalesAnalytics analytics, {String? subtitle}) {
    return MetricCard(
      title: 'Facturación',
      value: CurrencyHelper.formatCurrency(analytics.totalSales),
      icon: Icons.attach_money_rounded,
      color: colorBilling,
      subtitle: subtitle ?? 'Ingresos brutos',
      isZero: analytics.totalSales == 0,
    );
  }

  /// Construye MetricCard de Ganancia
  static Widget profit(SalesAnalytics analytics, {String? subtitle}) {
    return MetricCard(
      title: 'Ganancia',
      value: CurrencyHelper.formatCurrency(analytics.totalProfit),
      icon: Icons.trending_up_rounded,
      color: colorProfit,
      subtitle: subtitle,
      isZero: analytics.totalProfit == 0,
    );
  }

  /// Construye MetricCard de Ventas (transacciones)
  static Widget sales(SalesAnalytics analytics) {
    return MetricCard(
      title: 'Ventas',
      value: analytics.totalTransactions.toString(),
      icon: Icons.receipt_long_rounded,
      color: colorSales,
      isZero: analytics.totalTransactions == 0,
    );
  }

  /// Construye MetricCard de Ticket Promedio
  static Widget averageTicket(SalesAnalytics analytics) {
    return MetricCard(
      title: 'Ticket Prom.',
      value:
          CurrencyHelper.formatCurrency(analytics.averageProfitPerTransaction),
      icon: Icons.analytics_rounded,
      color: colorTicket,
      isZero: analytics.averageProfitPerTransaction == 0,
    );
  }

  /// Construye ProductsMetricCard
  static Widget products(SalesAnalytics analytics, {String? subtitle}) {
    return ProductsMetricCard(
      totalProducts: analytics.totalProductsSold,
      topSellingProducts: analytics.topSellingProducts,
      color: colorProducts,
      isZero: analytics.totalProductsSold == 0,
      subtitle: subtitle,
    );
  }

  /// Construye ProfitabilityMetricCard
  static Widget profitability(SalesAnalytics analytics, {String? subtitle}) {
    return ProfitabilityMetricCard(
      totalProfit: analytics.totalProfit,
      mostProfitableProducts: analytics.mostProfitableProducts,
      color: colorProfitability,
      isZero: analytics.mostProfitableProducts.isEmpty,
      subtitle: subtitle,
    );
  }

  /// Construye SlowMovingProductsCard
  static Widget slowMoving(SalesAnalytics analytics, {String? subtitle}) {
    return SlowMovingProductsCard(
      slowMovingProducts: analytics.slowMovingProducts,
      color: colorSlowMoving,
      isZero: analytics.slowMovingProducts.isEmpty,
      subtitle: subtitle,
    );
  }

  /// Construye PeakHoursCard
  static Widget peakHours(SalesAnalytics analytics, {String? subtitle}) {
    return PeakHoursCard(
      salesByHour: analytics.salesByHour,
      peakHours: analytics.peakHours,
      color: colorPeakHours,
      isZero: analytics.peakHours.isEmpty,
      subtitle: subtitle,
    );
  }

  /// Construye SellerRankingCard
  static Widget sellers(SalesAnalytics analytics, {String? subtitle}) {
    return SellerRankingCard(
      salesBySeller: analytics.salesBySeller,
      color: colorSellers,
      isZero: analytics.salesBySeller.isEmpty,
      subtitle: subtitle,
    );
  }

  /// Construye PaymentMethodsCard
  static Widget paymentMethods(SalesAnalytics analytics) {
    return PaymentMethodsCard(
      paymentMethodsBreakdown: analytics.paymentMethodsBreakdown,
      totalSales: analytics.totalSales,
    );
  }

  /// Construye ActiveCashRegistersCard (si hay cajas activas)
  static Widget? cashRegisters(List<CashRegister> activeCashRegisters) {
    if (activeCashRegisters.isEmpty) return null;
    return ActiveCashRegistersCard(activeCashRegisters: activeCashRegisters);
  }
}
