import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_dialog.dart';
import '../../../../presentation/providers/theme_data_app_provider.dart';

/// Diálogo para seleccionar el color semilla del tema de la aplicación
class ThemeColorSelectorDialog extends StatelessWidget {
  const ThemeColorSelectorDialog({super.key});

  /// Lista de colores semilla disponibles para tema claro
  static const List<Color> lightColors = [
    Colors.blue,
    Colors.teal,
  ];

  /// Lista de colores semilla disponibles para tema oscuro
  static const List<Color> darkColors = [
    Colors.deepPurple,
    Colors.indigo,
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
        // Título de colores claros
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Colores para tema claro',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Colores para tema claro
        _buildColorRow(
          context,
          lightColors,
          currentColor,
          themeProvider,
          isForDarkTheme: false,
        ),

        const SizedBox(height: 24),

        // Título de colores oscuros
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Colores para tema oscuro',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Colores para tema oscuro
        _buildColorRow(
          context,
          darkColors,
          currentColor,
          themeProvider,
          isForDarkTheme: true,
        ),

        const SizedBox(height: 16),

        // Vista previa del color actual
        _buildPreview(context, themeProvider),
      ],
    );
  }

  Widget _buildColorRow(
    BuildContext context,
    List<Color> colors,
    Color currentColor,
    ThemeDataAppProvider themeProvider,
    {required bool isForDarkTheme}
  ) {
    return Row(
      children: colors.map((color) {
        final isSelected = color == currentColor;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildColorOption(
              context,
              color,
              isSelected,
              () => themeProvider.changeSeedColor(color),
              isForDarkTheme: isForDarkTheme,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    {required bool isForDarkTheme}
  ) {
    final theme = Theme.of(context);
    final brightness = isForDarkTheme ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightness,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Área del color principal
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                  ),
                  child: isSelected
                    ? Icon(
                        Icons.check,
                        color: colorScheme.onPrimary,
                        size: 24,
                      )
                    : null,
                ),
              ),
              
              // Área del color secundario
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(11),
                      bottomRight: Radius.circular(11),
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
    if (color == Colors.blue) return 'Azul';
    if (color == Colors.teal) return 'Verde azulado';
    if (color == Colors.deepPurple) return 'Púrpura profundo';
    if (color == Colors.indigo) return 'Índigo';
    return 'Color personalizado';
  }
}
