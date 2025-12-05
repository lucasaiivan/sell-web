import 'package:flutter/material.dart';
import 'analytics_base_card.dart';

/// Widget: Card de Métrica (Rediseñado - Sin desbordamiento)
///
/// **Responsabilidad:**
/// - Mostrar una métrica individual con diseño premium
/// - Adaptarse a diferentes tamaños de celda (Bento Box)
/// - Manejar valores largos sin desbordamiento
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isZero;

  /// Si es true, muestra información adicional (tarjeta más grande)
  final bool moreInformation;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isZero = false,
    this.moreInformation = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsBaseCard(
      color: color,
      isZero: isZero,
      icon: icon,
      title: title,
      subtitle: subtitle,
      moreInformation: moreInformation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Valor principal grande - usa Flexible para expandirse
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsMainValue(
                value: value,
                isZero: isZero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
