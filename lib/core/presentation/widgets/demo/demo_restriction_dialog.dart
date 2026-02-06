import 'package:flutter/material.dart';
import '../../../constants/demo_mode_icons.dart';
import '../../../constants/demo_messages.dart';

/// Diálogo reutilizable para mostrar restricciones de modo demo
///
/// Muestra un modal educativo cuando el usuario intenta acceder a
/// funcionalidades que requieren autenticación.
class DemoRestrictionDialog extends StatelessWidget {
  /// Nombre de la funcionalidad bloqueada
  final String feature;

  /// Lista de beneficios de registrarse (opcional)
  final List<String>? benefits;

  const DemoRestrictionDialog({
    super.key,
    required this.feature,
    this.benefits,
  });

  /// Muestra el diálogo de restricción
  ///
  /// [context]: BuildContext para mostrar el diálogo
  /// [feature]: Nombre de la funcionalidad bloqueada
  /// [benefits]: Lista opcional de beneficios personalizados
  static Future<void> show(
    BuildContext context, {
    required String feature,
    List<String>? benefits,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DemoRestrictionDialog(
        feature: feature,
        benefits: benefits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final benefitsList = benefits ?? DemoMessages.registrationBenefits;

    return AlertDialog(
      icon: Icon(
        DemoModeIcons.locked,
        size: 48,
        color: DemoModeColors.warning,
      ),
      title: Text(
        DemoMessages.restrictionDialogTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje principal
            Text(
              '$feature requiere una cuenta registrada.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Beneficios de registrarse
            Text(
              'Beneficios de registrarse:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de beneficios
            ...benefitsList.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: DemoModeColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          benefit,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
      actions: [
        // Botón: Continuar en demo
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(DemoMessages.continueInDemoButton),
        ),

        // Botón: Registrarse
        FilledButton.icon(
          icon: const Icon(DemoModeIcons.register),
          label: Text(DemoMessages.registerButton),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacementNamed('/');
          },
        ),
      ],
    );
  }
}
