import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../base/base_dialog.dart';
import 'package:sellweb/core/presentation/providers/theme_provider.dart';

/// Diálogo para personalizar el tema de la aplicación (color y brillo)
class ThemeColorSelectorDialog extends StatefulWidget {
  const ThemeColorSelectorDialog({super.key});

  @override
  State<ThemeColorSelectorDialog> createState() =>
      _ThemeColorSelectorDialogState();
}

class _ThemeColorSelectorDialogState extends State<ThemeColorSelectorDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// Lista de colores semilla disponibles para personalización del tema
  /// Seleccionados siguiendo las mejores prácticas de Material Design 3
  static const List<({Color color, String name})> availableColors = [
    (color: Colors.blue, name: 'Azul'),
    (color: Colors.indigo, name: 'Índigo'),
    (color: Colors.deepPurple, name: 'Púrpura'),
    (color: Colors.pink, name: 'Rosa'),
    (color: Colors.red, name: 'Rojo'),
    (color: Colors.orange, name: 'Naranja'),
    (color: Colors.black, name: 'Negro'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeDataAppProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: BaseDialog(
                  title: 'Personalizar apariencia',
                  icon: Icons.palette_rounded,
                  width: 600,
                  maxHeight: 680,
                  content: _buildContent(context, themeProvider),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aceptar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control de brillo mejorado
          _buildEnhancedBrightnessControl(context, themeProvider),

          const SizedBox(height: 28),

          // Sección de colores
          _buildColorSection(context, themeProvider),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedBrightnessControl(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo de apariencia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? 'Tema oscuro activado' : 'Tema claro activado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.color_lens_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Color del tema',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona el color base para personalizar tu tema',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Grid de colores mejorado
        _buildEnhancedColorGrid(context, themeProvider),
      ],
    );
  }

  Widget _buildEnhancedColorGrid(
      BuildContext context, ThemeDataAppProvider themeProvider) {
    final currentColor = themeProvider.seedColor;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: availableColors.map((colorData) {
        final isSelected = colorData.color == currentColor;

        return _buildColorAvatar(
          context,
          colorData,
          isSelected,
          () => themeProvider.changeSeedColor(colorData.color),
        );
      }).toList(),
    );
  }

  Widget _buildColorAvatar(
    BuildContext context,
    ({Color color, String name}) colorData,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = colorData.color;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CircleAvatar con animación
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: _getContrastColor(color),
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Etiqueta del color
        Text(
          colorData.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Obtiene un color de contraste apropiado para el texto sobre el color de fondo
  Color _getContrastColor(Color backgroundColor) {
    // Calcula la luminancia del color de fondo
    final luminance = backgroundColor.computeLuminance();

    // Si la luminancia es alta (color claro), usar texto oscuro
    // Si la luminancia es baja (color oscuro), usar texto claro
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
