import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/auth/presentation/pages/welcome_selected_account_page.dart';
import 'package:sellweb/features/sales/presentation/pages/sales_page.dart';
import 'package:sellweb/features/catalogue/presentation/pages/catalogue_page.dart';
import 'package:sellweb/features/analytics/presentation/pages/analytics_page.dart';
import 'package:sellweb/features/cash_register/presentation/pages/history_cash_register_page.dart';
import 'package:sellweb/features/multiuser/presentation/pages/multi_user_page.dart';
import 'package:sellweb/core/utils/helpers/user_access_validator.dart';
import 'package:sellweb/features/auth/presentation/dialogs/access_denied_dialog.dart';

/// Página principal que gestiona la navegación entre las pantallas principales
/// Controla el flujo entre: selección de cuenta, ventas y catálogo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _accessCheckTimer;
  bool _isShowingAccessDeniedDialog = false;

  @override
  void initState() {
    super.initState();
    // Verificar acceso al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAccess();
    });
    
    // Configurar verificación periódica cada minuto
    _accessCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkUserAccess(),
    );
  }

  @override
  void dispose() {
    _accessCheckTimer?.cancel();
    super.dispose();
  }

  /// Verifica si el usuario actual tiene acceso permitido
  Future<void> _checkUserAccess() async {
    if (!mounted || _isShowingAccessDeniedDialog) return;

    final sellProvider = context.read<SalesProvider>();
    final adminProfile = sellProvider.currentAdminProfile;

    // Si no hay AdminProfile o es cuenta demo, no verificar
    if (adminProfile == null || 
        sellProvider.profileAccountSelected.id == 'demo') {
      return;
    }

    // Validar acceso
    final accessResult = UserAccessValidator.validateAccess(adminProfile);

    // Si no tiene acceso, mostrar diálogo
    if (!accessResult.hasAccess && mounted) {
      _isShowingAccessDeniedDialog = true;
      await AccessDeniedDialog.show(
        context: context,
        accessResult: accessResult,
        onSignOut: () async {
          Navigator.of(context).pop(); // Cerrar diálogo
          final authProvider = context.read<AuthProvider>();
          await authProvider.signOut();
          _isShowingAccessDeniedDialog = false;
        },
        onChangeAccount: () async {
          Navigator.of(context).pop(); // Cerrar diálogo
          final sellProvider = context.read<SalesProvider>();
          sellProvider.cleanData();
          _isShowingAccessDeniedDialog = false;
        },
      );
      _isShowingAccessDeniedDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener SalesProvider de forma segura
    final sellProvider = context.watch<SalesProvider>();

    // Verificar acceso cuando cambia el AdminProfile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAccess();
    });

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
              AnalyticsPage(),
              HistoryCashRegisterPage(),
              MultiUserPage(),
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
