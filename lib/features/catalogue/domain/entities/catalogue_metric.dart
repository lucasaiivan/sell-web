import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'product_catalogue.dart';

/// Tipos de métricas disponibles para el catálogo
enum CatalogueMetricType {
  articles,
  inventory,
  inventoryValue,
}

/// Entidad que representa una métrica del catálogo
///
/// Diseñada para ser extensible y soportar nuevas métricas en el futuro.
class CatalogueMetric {
  /// Tipo de métrica
  final CatalogueMetricType type;

  /// Valor numérico de la métrica
  final num value;

  /// Nombre para mostrar
  final String label;

  /// Ícono representativo
  final IconData icon;

  /// Formato del valor (ejemplo: moneda, número, porcentaje)
  final MetricValueFormat format;

  /// Símbolo de moneda (solo aplica si format es currency)
  final String currencySign;

  const CatalogueMetric({
    required this.type,
    required this.value,
    required this.label,
    required this.icon,
    this.format = MetricValueFormat.number,
    this.currencySign = '\$',
  });

  /// Formatea el valor según el tipo de formato
  String get formattedValue {
    switch (format) {
      case MetricValueFormat.currency:
        return '$currencySign${_formatNumber(value.toDouble())}';
      case MetricValueFormat.percentage:
        return '${value.toStringAsFixed(1)}%';
      case MetricValueFormat.number:
        return _formatNumber(value.toDouble());
    }
  }

  /// Formatea un número mostrando el valor completo
  String _formatNumber(double number) {
    if (number == number.truncateToDouble()) {
      // Número entero: usar formato con separadores de miles
      final formatter = NumberFormat('#,###', 'es_ES');
      return formatter.format(number.toInt());
    } else {
      // Número decimal: mostrar con 2 decimales
      final formatter = NumberFormat('#,##0.00', 'es_ES');
      return formatter.format(number);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogueMetric &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

/// Formato para el valor de la métrica
enum MetricValueFormat {
  number,
  currency,
  percentage,
}

/// Contenedor de todas las métricas del catálogo
///
/// Esta clase facilita el cálculo y acceso a las métricas,
/// permitiendo agregar nuevas métricas fácilmente en el futuro.
class CatalogueMetrics {
  /// Número total de artículos (productos únicos)
  final int articles;

  /// Cantidad total de unidades en inventario
  final int inventory;

  /// Valor total del inventario (stock × precio de venta)
  final double inventoryValue;

  /// Símbolo de moneda
  final String currencySign;

  const CatalogueMetrics({
    required this.articles,
    required this.inventory,
    required this.inventoryValue,
    this.currencySign = '\$',
  });

  /// Construye las métricas a partir de una lista de productos
  factory CatalogueMetrics.fromProducts({
    required List<ProductCatalogue> products,
    String currencySign = '\$',
  }) {
    final articles = products.length;

    int inventory = 0;
    double inventoryValue = 0.0;

    for (final product in products) {
      // Si tiene control de stock, usar la cantidad real
      if (product.stock) {
        inventory += product.quantityStock;
        inventoryValue += product.quantityStock * product.salePrice;
      } else {
        // Si NO tiene control de stock (servicios, ilimitado), contar como 1 unidad
        // para que sume al inventario y al valor total
        inventory += 1;
        inventoryValue += product.salePrice;
      }
    }

    return CatalogueMetrics(
      articles: articles,
      inventory: inventory,
      inventoryValue: inventoryValue,
      currencySign: currencySign,
    );
  }

  /// Obtiene la lista de métricas como objetos CatalogueMetric
  /// Útil para renderizar en la UI como chips
  List<CatalogueMetric> toMetricsList() {
    return [
      CatalogueMetric(
        type: CatalogueMetricType.articles,
        value: articles,
        label: 'Artículos',
        icon: Icons.inventory_2_outlined,
        format: MetricValueFormat.number,
      ),
      CatalogueMetric(
        type: CatalogueMetricType.inventory,
        value: inventory,
        label: 'Inventario',
        icon: Icons.warehouse_outlined,
        format: MetricValueFormat.number,
      ),
      CatalogueMetric(
        type: CatalogueMetricType.inventoryValue,
        value: inventoryValue,
        label: 'Valor inventario',
        icon: Icons.attach_money_rounded,
        format: MetricValueFormat.currency,
        currencySign: currencySign,
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogueMetrics &&
          runtimeType == other.runtimeType &&
          articles == other.articles &&
          inventory == other.inventory &&
          inventoryValue == other.inventoryValue;

  @override
  int get hashCode =>
      articles.hashCode ^ inventory.hashCode ^ inventoryValue.hashCode;
}
