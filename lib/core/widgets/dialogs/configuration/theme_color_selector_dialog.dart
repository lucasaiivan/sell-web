import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_dialog.dart';
import '../../../../presentation/providers/theme_data_app_provider.dart';

/// Diálogo para seleccionar el color semilla del tema de la aplicación
class ThemeColorSelectorDialog extends StatelessWidget {
  const ThemeColorSelectorDialog({super.key});

  /// Lista unificada de colores semilla disponibles para cualquier tema
  /// Seleccionados siguiendo las mejores prácticas de Material Design
  static const List<Color> availableColors = [
    Colors.black,        // Negro: elegante y premium
    Colors.indigo,       // Índigo: profesional y confiable  
    Colors.deepPurple,   // Púrpura profundo: moderno y creativo
    Colors.orange,       // Naranja: energético y llamativo
    Colors.teal,         // Verde azulado: fresco y equilibrado
    Colors.blue,         // Azul: clásico y confiable
  ];

  /// Muestra el diálogo de selección de color
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => const ThemeColorSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeDataAppProvider>(
      builder: (context, themeProvider, child) {
        return BaseDialog(
          title: 'Color del tema',
          icon: Icons.palette,
          width: 400,
          content: _buildContent(context, themeProvider),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);
    final currentColor = themeProvider.seedColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(
                Icons.color_lens,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Selecciona tu color favorito',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Grid de colores unificado
        _buildColorGrid(
          context,
          availableColors,
          currentColor,
          themeProvider,
        ),

        const SizedBox(height: 20),

        // Vista previa del color actual
        _buildPreview(context, themeProvider),
      ],
    );
  }

  Widget _buildColorGrid(
    BuildContext context,
    List<Color> colors,
    Color currentColor,
    ThemeDataAppProvider themeProvider,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color == currentColor;
        
        return _buildColorOption(
          context,
          color,
          isSelected,
          () => themeProvider.changeSeedColor(color),
        );
      },
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final currentBrightness = theme.brightness;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: currentBrightness,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              // Área del color principal (más grande)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: colorScheme.onPrimary,
                        size: 28,
                      )
                    : null,
                ),
              ),
              
              // Área del color secundario
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);
    final currentColor = themeProvider.seedColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color actual',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getColorName(currentColor),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.black) return 'Negro';
    if (color == Colors.indigo) return 'Índigo';
    if (color == Colors.deepPurple) return 'Púrpura profundo';
    if (color == Colors.orange) return 'Naranja';
    if (color == Colors.teal) return 'Verde azulado';
    if (color == Colors.blue) return 'Azul';
    return 'Color personalizado';
  }
}
