import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import '../providers/auth_provider.dart';
import 'terms_checkbox.dart';

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

                // Checkbox de términos y condiciones
                TermsCheckbox(
                  value: _acceptPolicy,
                  onChanged: (value) {
                    setState(() {
                      _acceptPolicy = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // ElevatedButton : Iniciar sesión con Google
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final isDisabled = !_acceptPolicy ||
                          widget.authProvider.isSigningInWithGoogle ||
                          widget.authProvider.isSigningInAsGuest;
                      
                      return Opacity(
                        opacity: isDisabled ? 0.5 : 1.0,
                        child: AppButton(
                          borderRadius: 8,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          backgroundColor: isDisabled
                              ? Colors.grey.shade400
                              : (isDark ? Colors.white : const Color(0xFF1976D2)),
                          foregroundColor: isDisabled
                              ? Colors.grey.shade700
                              : (isDark ? const Color(0xFF1976D2) : Colors.white),
                          elevation: isDisabled ? 0 : 3,
                          text: "CONTINUAR CON GOOGLE",
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.login_rounded,
                                size: 20,
                                color: isDisabled
                                    ? Colors.grey.shade700
                                    : (isDark ? const Color(0xFF1976D2) : Colors.white)),
                          ),
                          isLoading: widget.authProvider.isSigningInWithGoogle,
                          onPressed: isDisabled
                              ? null
                              : () async {
                                  await widget.authProvider.signInWithGoogle();
                                },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // ElevatedButton : Iniciar como invitado
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    borderRadius: 8,
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
