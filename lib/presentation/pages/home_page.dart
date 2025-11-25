import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import '../../features/catalogue/presentation/providers/catalogue_provider.dart';
import 'welcome_selected_account_page.dart';
import 'package:sellweb/features/sales/presentation/pages/sales_page.dart';
import '../../features/catalogue/presentation/pages/catalogue_page.dart';

/// Página principal que gestiona la navegación entre las pantallas principales
/// Controla el flujo entre: selección de cuenta, ventas y catálogo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Obtener SalesProvider de forma segura
    final sellProvider = context.watch<SalesProvider>();

    // Si no hay cuenta seleccionada, mostrar la pantalla de bienvenida
    if (sellProvider.profileAccountSelected.id.isEmpty) {
      return _buildWelcomeScreen(context, sellProvider);
    }

    // Si hay cuenta seleccionada, mostrar la navegación principal
    return _buildMainNavigation(context, sellProvider);
  }

  /// Construye la pantalla de bienvenida para seleccionar cuenta
  Widget _buildWelcomeScreen(BuildContext context, SalesProvider sellProvider) {
    return WelcomeSelectedAccountPage(
      onSelectAccount: (account) async {
        // Selecciona la cuenta y recarga el catálogo
        await sellProvider.initAccount(account: account, context: context);

        if (!context.mounted) {
          return;
        }

        // Reinicia la navegación principal para comenzar en la pestaña de ventas
        context.read<HomeProvider>().reset();
      },
    );
  }

  /// Construye la navegación principal manteniendo ambas pantallas montadas
  Widget _buildMainNavigation(BuildContext context, SalesProvider sellProvider) {
    // Manejar productos demo si aplica
    _handleDemoProducts(context, sellProvider);

    final homeProvider = context.watch<HomeProvider>();
    final isDemo = sellProvider.profileAccountSelected.id == 'demo';

    return Column(
      children: [
        if (isDemo)
          Container(
            width: double.infinity,
            color: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: const Text(
              'MODO INVITADO - Los datos no se guardarán',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: homeProvider.currentPageIndex,
            children: const [
              SalesPage(),
              CataloguePage(),
            ],
          ),
        ),
      ],
    );
  }

  /// Maneja la carga de productos demo si corresponde
  void _handleDemoProducts(BuildContext context, SalesProvider sellProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    if (sellProvider.profileAccountSelected.id == 'demo' &&
        authProvider.user?.isAnonymous == true &&
        catalogueProvider.products.isEmpty) {
      final demoProducts =
          authProvider.getUserAccountsUseCase.getDemoProducts();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        catalogueProvider.loadDemoProducts(demoProducts);
      });
    }
  }
}
