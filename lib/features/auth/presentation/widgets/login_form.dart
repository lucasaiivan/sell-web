import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sellweb/core/core.dart';
import '../providers/auth_provider.dart';

class LoginForm extends StatefulWidget {
  final AuthProvider authProvider;
  const LoginForm({required this.authProvider, super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _acceptPolicy = false;

  @override
  void initState() {
    super.initState();
    // Limpiar errores previos al inicializar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.authProvider.clearAuthError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Estilos responsivos para el texto
    final double baseFontSize = getResponsiveValue(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 13.0,
    );

    TextStyle aceptPolitikTextStyle = textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
          fontSize: baseFontSize * 0.95,
          height: 1.4,
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontSize: baseFontSize * 0.9,
          height: 1.4,
        );

    RichText text = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: aceptPolitikTextStyle,
        children: <TextSpan>[
          const TextSpan(
              text:
                  'Al iniciar en INICIAR SESIÓN, usted ha leído y acepta nuestros '),
          TextSpan(
              text: 'Términos y condiciones de uso',
              style: aceptPolitikTextStyle.copyWith(
                  decoration: TextDecoration.none, color: colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri url = Uri.parse(
                      'https://sites.google.com/view/sell-app/t%C3%A9rminos-y-condiciones-de-uso');
                  if (!await launchUrl(url)) throw 'Could not launch $url';
                }),
          const TextSpan(text: ' así también como la '),
          TextSpan(
              text: 'Política de privacidad',
              style: aceptPolitikTextStyle.copyWith(
                  decoration: TextDecoration.none, color: colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri url = Uri.parse(
                      'https://sites.google.com/view/sell-app/pol%C3%ADticas-de-privacidad');
                  if (!await launchUrl(url)) throw 'Could not launch $url';
                }),
        ],
      ),
    );

    return Center(
      child: AnimatedBuilder(
        animation: widget.authProvider,
        builder: (context, _) {
          // Si el usuario se autentica exitosamente, navegar de vuelta
          if (widget.authProvider.user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            return AuthFeedbackWidget(
              showLoading: true,
              loadingMessage: 'Configurando tu cuenta...',
            );
          }

          if (widget.authProvider.user == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Widget de feedback unificado para errores y estados
                AuthFeedbackWidget(
                  error: widget.authProvider.authError,
                  onDismissError: widget.authProvider.clearAuthError,
                ),

                // CheckboxListTile responsivo : aceptar términos y condiciones
                Container(
                  margin: getResponsivePadding(
                    context,
                    mobile:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    tablet:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    desktop: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _acceptPolicy
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _acceptPolicy
                        ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : colorScheme.surface,
                  ),
                  child: CheckboxListTile(
                    dense: isMobile(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    selectedTileColor: Colors.transparent,
                    tileColor: Colors.transparent,
                    checkColor: colorScheme.onPrimary,
                    activeColor: colorScheme.primary,
                    title: text,
                    value: _acceptPolicy,
                    onChanged: (value) {
                      setState(() {
                        _acceptPolicy = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: getResponsivePadding(
                      context,
                      mobile: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tablet: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      desktop: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ElevatedButton : Iniciar sesión con Google
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    backgroundColor: Colors.blue.shade700,
                    text: "CONTINUAR CON GOOGLE",
                    icon: const Icon(Icons.login_rounded, size: 20),
                    isLoading: widget.authProvider.isSigningInWithGoogle,
                    onPressed: (_acceptPolicy &&
                            !widget.authProvider.isSigningInWithGoogle &&
                            !widget.authProvider.isSigningInAsGuest)
                        ? () async {
                            await widget.authProvider.signInWithGoogle();
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // ElevatedButton : Iniciar como invitado
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 20),
                    backgroundColor: Colors.blueGrey,
                    text: "CONTINUAR COMO INVITADO",
                    isLoading: widget.authProvider.isSigningInAsGuest,
                    onPressed: (!widget.authProvider.isSigningInWithGoogle &&
                            !widget.authProvider.isSigningInAsGuest)
                        ? () async {
                            await widget.authProvider.signInAsGuest();
                          }
                        : null,
                  ),
                ),
              ],
            );
          }

          // Estado por defecto - no debería llegar aquí
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
