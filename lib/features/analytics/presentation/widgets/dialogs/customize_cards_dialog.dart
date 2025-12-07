import 'package:flutter/material.dart';
import 'package:sellweb/features/analytics/domain/entities/analytics_card_definition.dart';
import '../registry/widgets.dart';

/// Modal para personalizar las tarjetas visibles en el dashboard
///
/// **Responsabilidad:**
/// - Mostrar todas las tarjetas disponibles organizadas por categoría
/// - Permitir activar/desactivar tarjetas mediante Cards interactivas
/// - Retornar la lista de tarjetas seleccionadas al confirmar
class CustomizeCardsModal extends StatefulWidget {
  /// Lista de IDs de tarjetas actualmente visibles
  final List<String> currentVisibleCards;

  const CustomizeCardsModal({
    super.key,
    required this.currentVisibleCards,
  });

  @override
  State<CustomizeCardsModal> createState() => _CustomizeCardsModalState();
}

class _CustomizeCardsModalState extends State<CustomizeCardsModal> {
  late Set<String> _selectedCardIds;

  @override
  void initState() {
    super.initState();
    _selectedCardIds = Set<String>.from(widget.currentVisibleCards);
  }

  void _toggleCard(AnalyticsCardDefinition card) {
    setState(() {
      if (_selectedCardIds.contains(card.id)) {
        _selectedCardIds.remove(card.id);
      } else {
        _selectedCardIds.add(card.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardsByCategory = AnalyticsCardRegistry.getCardsByCategories();
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.dashboard_customize_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalizar Dashboard',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selecciona las tarjetas que deseas ver',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider con gradiente
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.outlineVariant.withValues(alpha: 0.0),
                      colorScheme.outlineVariant.withValues(alpha: 0.5),
                      colorScheme.outlineVariant.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              // Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Categorías con tarjetas
                    ...cardsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final cards = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header de categoría
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Grid de tarjetas de la categoría
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: cards.map((card) {
                                  // Ancho dinámico
                                  final width = (constraints.maxWidth - 10) /
                                      (constraints.maxWidth > 500 ? 2 : 1);

                                  return SizedBox(
                                    width: width,
                                    child: _buildSelectableCard(card, theme),
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                    // Espaciado para el FAB
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),

          // FloatingActionButton en la parte inferior izquierda
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedCardIds.toList());
              }, 
              child: const Icon(Icons.check_rounded),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta seleccionable individual con información mejorada
  Widget _buildSelectableCard(AnalyticsCardDefinition card, ThemeData theme) {
    final isSelected = _selectedCardIds.contains(card.id);
    final colorScheme = theme.colorScheme;

    // El color del icono siempre es el color único de la tarjeta
    final iconColor = card.color;

    // Background y border cambian según selección
    final backgroundColor = isSelected
        ? card.color.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final borderColor = isSelected
        ? card.color.withValues(alpha: 0.5)
        : colorScheme.outlineVariant.withValues(alpha: 0.3);

    return InkWell(
      onTap: () => _toggleCard(card),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icono con color único de la tarjeta
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                card.icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            // Título, descripción y badge de categoría
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    card.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Descripción más detallada
                  Text(
                    card.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Badge de categoría (con Flexible para evitar overflow)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: card.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                card.category.icon,
                                size: 10,
                                color: card.color,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  card.category.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: card.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Indicador de selección
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? card.color
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? card.color : colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el modal de personalización de tarjetas
Future<List<String>?> showCustomizeCardsDialog(
  BuildContext context,
  List<String> currentVisibleCards,
) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomizeCardsModal(
      currentVisibleCards: currentVisibleCards,
    ),
  );
}
