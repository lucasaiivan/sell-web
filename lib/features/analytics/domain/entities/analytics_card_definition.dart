import 'package:flutter/material.dart';

/// Categoría de una tarjeta de analíticas
///
/// Usado para agrupar tarjetas en el diálogo de personalización
enum AnalyticsCardCategory {
  /// Métricas principales (Facturación, Ganancia, Ventas, Ticket Promedio)
  metrics,

  /// Rendimiento temporal (Horas Pico, Días de Venta, Tendencia)
  performance,

  /// Análisis de productos (Top, Lentos, Categorías)
  products,

  /// Análisis de equipo (Ranking de Vendedores)
  team,

  /// Análisis financiero (Medios de Pago, Rentabilidad)
  financial,

  /// Operaciones (Cajas Activas)
  operations,
}

/// Definición de una tarjeta de analíticas disponible
///
/// **Responsabilidad:**
/// - Contener metadata de cada tarjeta disponible
/// - Facilitar la categorización y búsqueda
/// - Definir cuáles son tarjetas por defecto
///
/// **Uso:**
/// - En `AnalyticsCardRegistry` para el registro maestro
/// - En `CustomizeCardsDialog` para mostrar opciones
/// - En `AnalyticsProvider` para gestionar preferencias
class AnalyticsCardDefinition {
  /// Identificador único de la tarjeta (ej: 'billing', 'profit')
  final String id;

  /// Título visible en la UI (ej: 'Facturación')
  final String title;

  /// Descripción breve de la tarjeta
  final String description;

  /// Color distintivo de la tarjeta
  final Color color;

  /// Ícono representativo
  final IconData icon;

  /// Categoría para agrupación
  final AnalyticsCardCategory category;

  /// Si esta tarjeta se muestra por defecto en la primera carga
  /// Solo debe haber UNA tarjeta con isDefault = true
  final bool isDefault;

  const AnalyticsCardDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnalyticsCardDefinition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AnalyticsCardDefinition(id: $id, title: $title, category: $category)';
  }
}

/// Extensión para obtener el label de cada categoría
extension AnalyticsCardCategoryExtension on AnalyticsCardCategory {
  String get label {
    switch (this) {
      case AnalyticsCardCategory.metrics:
        return 'Métricas Principales';
      case AnalyticsCardCategory.performance:
        return 'Rendimiento';
      case AnalyticsCardCategory.products:
        return 'Productos';
      case AnalyticsCardCategory.team:
        return 'Equipo';
      case AnalyticsCardCategory.financial:
        return 'Análisis Financiero';
      case AnalyticsCardCategory.operations:
        return 'Operaciones';
    }
  }

  IconData get icon {
    switch (this) {
      case AnalyticsCardCategory.metrics:
        return Icons.analytics_outlined;
      case AnalyticsCardCategory.performance:
        return Icons.trending_up_rounded;
      case AnalyticsCardCategory.products:
        return Icons.inventory_2_outlined;
      case AnalyticsCardCategory.team:
        return Icons.people_outline_rounded;
      case AnalyticsCardCategory.financial:
        return Icons.account_balance_wallet_outlined;
      case AnalyticsCardCategory.operations:
        return Icons.settings_outlined;
    }
  }
}
