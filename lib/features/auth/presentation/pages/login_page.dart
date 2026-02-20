import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';
import '../widgets/onboarding_introduction_app.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final double width = MediaQuery.of(context).size.width;

    Widget content;
    if (width < 600) {
      // Móvil: apilar verticalmente
      content = Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: LoginForm(authProvider: authProvider),
          ),
        ],
      );
    } else if (width < 1024) {
      // Tablet: proporción 2/3 y 1/3
      content = Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Expanded(
            flex: 1,
            child: LoginForm(authProvider: authProvider),
          ),
        ],
      );
    } else {
      // Desktop: proporción 3/4 y 1/4
      content = Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LoginForm(authProvider: authProvider),
            ),
          ),
        ],
      );
    }

    return Title(
      title: 'Punto de venta',
      color: Theme.of(context).colorScheme.primary,
      child: Scaffold(
        body: Stack(
          children: [
            content,
            // Botones de configuración del tema
            Positioned(
              top: 30,
              right: 20,
              child: ThemeControlButtons(
                spacing: 8,
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
