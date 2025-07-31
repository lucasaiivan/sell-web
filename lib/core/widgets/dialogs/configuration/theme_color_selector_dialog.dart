import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/base_dialog.dart';
import '../../../../presentation/providers/theme_data_app_provider.dart';

/// Diálogo para personalizar el tema de la aplicación (color y brillo)
class ThemeColorSelectorDialog extends StatelessWidget {
  const ThemeColorSelectorDialog({super.key});

  /// Lista unificada de colores semilla disponibles para cualquier tema
  /// Seleccionados siguiendo las mejores prácticas de Material Design
  static const List<Color> availableColors = [
    Colors.black, // Negro: elegante y premium
    Colors.blue, // Azul: clásico y confiable
    Colors.indigo, // Índigo: profesional y confiable
    Colors.deepPurple, // Púrpura profundo: moderno y creativo
    Colors.orange, // Naranja: vibrante y enérgico
    Colors.pink, // Rosa: juguetón y romántico
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
          title: 'Personalizar tema',
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

  Widget _buildContent(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Control de brillo
        _buildBrightnessControl(context, themeProvider),

        const SizedBox(height: 20),

        // Colores disponibles
        Text(
          'Color del tema',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Grid de colores simplificado
        _buildSimpleColorGrid(context, themeProvider),
      ],
    );
  }

  Widget _buildBrightnessControl(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

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
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tema ${isDark ? 'oscuro' : 'claro'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleColorGrid(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final currentColor = themeProvider.seedColor;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: availableColors.map((color) {
        final isSelected = color == currentColor;
        return _buildSimpleColorOption(
          context,
          color,
          isSelected,
          () => themeProvider.changeSeedColor(color),
        );
      }).toList(),
    );
  }

  Widget _buildSimpleColorOption(
    BuildContext context,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: isSelected ? 0.9 : 1.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
