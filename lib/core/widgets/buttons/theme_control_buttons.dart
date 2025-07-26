import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/dialogs.dart';
import '../../../presentation/providers/theme_data_app_provider.dart';

/// Widget reutilizable para controles de tema dinámico
///
/// Proporciona botones para cambiar el brillo del tema y seleccionar
/// el color semilla de manera consistente en toda la aplicación
class ThemeControlButtons extends StatelessWidget {
  const ThemeControlButtons({
    super.key,
    this.showColorButton = true,
    this.showBrightnessButton = true,
    this.spacing = 8.0,
    this.iconSize,
    this.buttonColor,
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Mostrar el botón de selección de color
  final bool showColorButton;

  /// Mostrar el botón de cambio de brillo
  final bool showBrightnessButton;

  /// Espacio entre botones
  final double spacing;

  /// Tamaño de los iconos
  final double? iconSize;

  /// Color personalizado para los iconos (por defecto usa el color primario del tema)
  final Color? buttonColor;

  /// Tamaño del Row que contiene los botones
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = buttonColor ?? theme.colorScheme.primary;

    return Consumer<ThemeDataAppProvider>(
      builder: (context, themeProvider, _) {
        List<Widget> buttons = [];

        // Botón de color del tema
        if (showColorButton) {
          buttons.add(
            ThemeColorButton(
              iconColor: iconColor,
              iconSize: iconSize,
            ),
          );
        }

        // Espaciado
        if (showColorButton && showBrightnessButton) {
          buttons.add(SizedBox(width: spacing));
        }

        return Row(
          mainAxisSize: mainAxisSize,
          children: buttons,
        );
      },
    );
  }
}

/// Botón individual para seleccionar el color del tema
class ThemeColorButton extends StatelessWidget {
  const ThemeColorButton({
    super.key,
    required this.iconColor,
    this.iconSize,
    this.tooltip = 'Cambiar color del tema',
  });

  final Color iconColor;
  final double? iconSize;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          Icons.palette,
          color: iconColor,
          size: iconSize,
        ),
        tooltip: tooltip,
        onPressed: () => ThemeColorSelectorDialog.show(context),
      ),
    );
  }
}

/// Botón individual para cambiar el brillo del tema
class ThemeBrightnessButton extends StatelessWidget {
  const ThemeBrightnessButton({
    super.key,
    required this.themeProvider,
    required this.iconColor,
    this.iconSize,
    this.tooltip,
  });

  final ThemeDataAppProvider themeProvider;
  final Color iconColor;
  final double? iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final defaultTooltip =
        isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro';

    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: iconColor,
          size: iconSize,
        ),
        tooltip: tooltip ?? defaultTooltip,
        onPressed: () => themeProvider.toggleTheme(),
      ),
    );
  }
}

/// Widget compacto que solo muestra el botón de color
class ThemeColorOnlyButton extends StatelessWidget {
  const ThemeColorOnlyButton({
    super.key,
    this.iconSize,
    this.buttonColor,
    this.tooltip = 'Cambiar color del tema',
  });

  final double? iconSize;
  final Color? buttonColor;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return ThemeControlButtons(
      showBrightnessButton: false,
      iconSize: iconSize,
      buttonColor: buttonColor,
    );
  }
}

/// Widget compacto que solo muestra el botón de brillo
class ThemeBrightnessOnlyButton extends StatelessWidget {
  const ThemeBrightnessOnlyButton({
    super.key,
    this.iconSize,
    this.buttonColor,
    this.tooltip,
  });

  final double? iconSize;
  final Color? buttonColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return ThemeControlButtons(
      showColorButton: false,
      iconSize: iconSize,
      buttonColor: buttonColor,
    );
  }
}
