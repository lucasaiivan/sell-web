import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sellweb/core/core.dart';

/// Widget: Checkbox de aceptación de términos y condiciones
///
/// **Responsabilidad:**
/// - Mostrar checkbox para aceptar términos y política de privacidad
/// - Manejar enlaces a documentos legales
/// - Proporcionar feedback visual responsivo
///
/// **Características:**
/// - Diseño responsivo para mobile/tablet/desktop
/// - Enlaces clickeables a términos y política
/// - Animación continua de pulso cuando no está seleccionado
/// - Soporte para tema claro/oscuro
class TermsCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Iniciar animación si no está seleccionado
    if (!widget.value) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TermsCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Controlar animación basado en el estado
    if (widget.value && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.value = 0;
    } else if (!widget.value && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Tamaño de fuente responsivo
    final double baseFontSize = getResponsiveValue(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 13.0,
    );

    // Estilo base del texto
    final TextStyle baseTextStyle = textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
          fontSize: baseFontSize,
          height: 1.5,
          letterSpacing: 0.1,
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontSize: baseFontSize,
          height: 1.5,
          letterSpacing: 0.1,
        );

    // Estilo para enlaces
    final TextStyle linkStyle = baseTextStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.value ? 1.0 : _scaleAnimation.value,
          child: Opacity(
            opacity: widget.value ? 1.0 : _opacityAnimation.value,
            child: Container(
              margin: getResponsivePadding(
                context,
                mobile: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                tablet: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                desktop:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.value
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : colorScheme.primary.withValues(alpha: 0.3),
                  width: widget.value ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                gradient: widget.value
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.primaryContainer.withValues(
                            alpha: 0.05 + (0.1 * _opacityAnimation.value),
                          ),
                        ],
                      ),
                color: widget.value
                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : null,
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: colorScheme.primary.withValues(
                            alpha: 0.05 + (0.05 * _opacityAnimation.value),
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: CheckboxListTile(
                dense: isMobile(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                selectedTileColor: Colors.transparent,
                tileColor: Colors.transparent,
                checkColor: colorScheme.onPrimary,
                activeColor: colorScheme.primary,
                title: _buildTermsText(context, baseTextStyle, linkStyle),
                value: widget.value,
                onChanged: (newValue) => widget.onChanged(newValue ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: getResponsivePadding(
                  context,
                  mobile:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tablet:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  desktop:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye el texto con enlaces clickeables
  Widget _buildTermsText(
    BuildContext context,
    TextStyle baseStyle,
    TextStyle linkStyle,
  ) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: baseStyle,
        children: <TextSpan>[
          const TextSpan(
            text: 'Al hacer clic en ',
          ),
          TextSpan(
            text: 'INICIAR SESIÓN',
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(
            text: ', usted ha leído y acepta nuestros ',
          ),
          TextSpan(
            text: 'Términos y condiciones de uso',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(
                    'https://sites.google.com/view/sell-app/t%C3%A9rminos-y-condiciones-de-uso',
                  ),
          ),
          const TextSpan(
            text: ' así como también nuestra ',
          ),
          TextSpan(
            text: 'Política de privacidad',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(
                    'https://sites.google.com/view/sell-app/pol%C3%ADticas-de-privacidad',
                  ),
          ),
          const TextSpan(
            text: '.',
          ),
        ],
      ),
    );
  }

  /// Abre URL en el navegador
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir la URL: $url');
    }
  }
}
