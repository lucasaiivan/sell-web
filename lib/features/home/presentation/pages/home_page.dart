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
import 'package:sellweb/core/presentation/widgets/widgets.dart';

/// Página principal que gestiona la navegación entre las pantallas principales
/// Controla el flujo entre: selección de cuenta, ventas y catálogo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _accessCheckTimer;
  String? _lastCheckedAdminId;
  UserAccessResult? _currentAccessResult;

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
  void _checkUserAccess() {
    if (!mounted) return;

    final sellProvider = context.read<SalesProvider>();
    final adminProfile = sellProvider.currentAdminProfile;

    // Si no hay AdminProfile o es cuenta demo, no verificar
    if (adminProfile == null ||
        sellProvider.profileAccountSelected.id == 'demo') {
      if (_currentAccessResult != null) {
        setState(() {
          _currentAccessResult = null;
        });
      }
      return;
    }

    // Validar acceso
    final accessResult = UserAccessValidator.validateAccess(adminProfile);

    // Actualizar estado si cambia el resultado
    if (_currentAccessResult?.hasAccess != accessResult.hasAccess ||
        _currentAccessResult?.reason != accessResult.reason) {
      setState(() {
        _currentAccessResult = accessResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener SalesProvider de forma segura
    final sellProvider = context.watch<SalesProvider>();
    final currentAdminId = sellProvider.currentAdminProfile?.id;
    final accountId = sellProvider.profileAccountSelected.id;

    // Verificar acceso cuando cambia el AdminProfile o cuando se selecciona una cuenta
    if (currentAdminId != null && currentAdminId != _lastCheckedAdminId) {
      _lastCheckedAdminId = currentAdminId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkUserAccess();
      });
    }

    // Si no hay cuenta seleccionada, mostrar la pantalla de bienvenida
    if (accountId.isEmpty) {
      return _buildWelcomeScreen(context, sellProvider);
    }

    // IMPORTANTE: Verificar acceso inmediatamente si hay AdminProfile pero aún no se ha verificado
    if (currentAdminId != null && _currentAccessResult == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkUserAccess();
      });
    }

    // Si el usuario NO tiene acceso, mostrar pantalla de bloqueo
    if (_currentAccessResult != null && !_currentAccessResult!.hasAccess) {
      return _buildBlockedScreen(context, sellProvider);
    }

    // Si hay cuenta seleccionada y tiene acceso, mostrar la navegación principal
    return _buildMainNavigation(context, sellProvider);
  }

  /// Construye la pantalla de bienvenida para seleccionar cuenta
  Widget _buildWelcomeScreen(BuildContext context, SalesProvider sellProvider) {
    return WelcomeSelectedAccountPage(
      onSelectAccount: (account) async {
        // Limpiar estado de verificación anterior
        setState(() {
          _currentAccessResult = null;
          _lastCheckedAdminId = null;
        });

        // Selecciona la cuenta y recarga el catálogo
        await sellProvider.initAccount(account: account, context: context);

        if (!context.mounted) {
          return;
        }

        // Reinicia la navegación principal para comenzar en la pestaña de ventas
        context.read<HomeProvider>().reset();

        // Forzar verificación inmediata después de seleccionar cuenta
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkUserAccess();
        });
      },
    );
  }

  /// Construye la pantalla de bloqueo cuando el usuario no tiene acceso
  Widget _buildBlockedScreen(BuildContext context, SalesProvider sellProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminProfile = sellProvider.currentAdminProfile;
    final accountProfile = sellProvider.profileAccountSelected;

    // Configuración visual según el tipo de restricción
    final blockConfig = _getBlockConfiguration(colorScheme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de bloqueo
                Icon(
                  blockConfig.icon,
                  size: 72,
                  color: blockConfig.iconColor,
                ),
                const SizedBox(height: 24),

                // Título
                Text(
                  _currentAccessResult!.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: blockConfig.titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Información de la cuenta
                Text(
                  accountProfile.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Información específica según el tipo de restricción
                if ((_currentAccessResult!.reason ==
                            UserAccessDeniedReason.outsideAllowedHours ||
                        _currentAccessResult!.reason ==
                            UserAccessDeniedReason.dayNotAllowed) &&
                    adminProfile != null) ...[
                  _buildAvailabilityInfo(context, adminProfile, blockConfig),
                  const SizedBox(height: 24),
                ],

                // Nota personalizada de bloqueo (si está disponible)
                if (_currentAccessResult!.reason ==
                        UserAccessDeniedReason.userBlocked &&
                    adminProfile?.inactivateNote.isNotEmpty == true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      adminProfile!.inactivateNote,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Información adicional
                Text(
                  _getInfoMessage(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Botones de acción
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          // Limpiar todo el estado de verificación
                          setState(() {
                            _currentAccessResult = null;
                            _lastCheckedAdminId = null;
                          });
                          // Limpiar datos del provider
                          sellProvider.cleanData();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: blockConfig.buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cambiar de Cuenta'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          await authProvider.signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la navegación principal manteniendo ambas pantallas montadas
  Widget _buildMainNavigation(
      BuildContext context, SalesProvider sellProvider) {
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
        // Banner de conectividad (muestra cuando está offline)
        const ConnectivityBanner(),
        Expanded(
          child: IndexedStack(
            index: homeProvider.currentPageIndex,
            children: const [
              SalesPage(), // 0: Ventas
              AnalyticsPage(), // 1: Analíticas
              CataloguePage(), // 2: Catálogo
              MultiUserPage(), // 3: Usuarios
              HistoryCashRegisterPage(), // 4: Historial de Caja
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

  /// Obtiene la configuración visual según el tipo de bloqueo
  _BlockConfiguration _getBlockConfiguration(ColorScheme colorScheme) {
    switch (_currentAccessResult!.reason) {
      case UserAccessDeniedReason.userBlocked:
        return _BlockConfiguration(
          icon: Icons.lock_rounded,
          iconColor: colorScheme.error,
          backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
          titleColor: colorScheme.error,
          infoBackgroundColor: colorScheme.errorContainer.withOpacity(0.2),
          infoTextColor: colorScheme.onErrorContainer,
          buttonColor: colorScheme.error,
        );
      case UserAccessDeniedReason.outsideAllowedHours:
        return _BlockConfiguration(
          icon: Icons.schedule_rounded,
          iconColor: Colors.orange.shade700,
          backgroundColor: Colors.orange.shade100.withOpacity(0.5),
          titleColor: Colors.orange.shade800,
          infoBackgroundColor: Colors.orange.shade50,
          infoTextColor: Colors.orange.shade900,
          buttonColor: Colors.orange.shade700,
        );
      case UserAccessDeniedReason.dayNotAllowed:
        return _BlockConfiguration(
          icon: Icons.event_busy_rounded,
          iconColor: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade100.withOpacity(0.5),
          titleColor: Colors.blue.shade800,
          infoBackgroundColor: Colors.blue.shade50,
          infoTextColor: Colors.blue.shade900,
          buttonColor: Colors.blue.shade700,
        );
      default:
        return _BlockConfiguration(
          icon: Icons.lock_rounded,
          iconColor: colorScheme.error,
          backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
          titleColor: colorScheme.error,
          infoBackgroundColor:
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
          infoTextColor: colorScheme.onSurfaceVariant,
          buttonColor: colorScheme.error,
        );
    }
  }

  /// Construye la información completa de disponibilidad (horario + días)
  Widget _buildAvailabilityInfo(
    BuildContext context,
    dynamic adminProfile,
    _BlockConfiguration config,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtener texto de horario
    String scheduleText = '';
    try {
      scheduleText = adminProfile.accessTimeFormat ?? '';
      if (scheduleText.isEmpty) {
        scheduleText = 'No configurado';
      }
    } catch (e) {
      scheduleText = 'No configurado';
    }

    // Obtener días en español
    List<String> daysInSpanish = [];
    try {
      daysInSpanish = adminProfile.daysOfWeekInSpanish ?? [];
      if (daysInSpanish.isEmpty) {
        daysInSpanish = [];
      }
    } catch (e) {
      daysInSpanish = [];
    }

    return Column(
      children: [
        // Horario
        if (scheduleText != 'No configurado') ...[
          Text(
            'Horario disponible',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scheduleText,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: config.iconColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],

        // Separador si hay ambos
        if (scheduleText != 'No configurado' && daysInSpanish.isNotEmpty) ...[
          const SizedBox(height: 20),
        ],

        // Días
        if (daysInSpanish.isNotEmpty) ...[
          Text(
            'Días disponibles',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: daysInSpanish.map((day) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: config.iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Obtiene el mensaje de información según el tipo de restricción
  String _getInfoMessage() {
    switch (_currentAccessResult!.reason) {
      case UserAccessDeniedReason.userBlocked:
        return 'Contacta con el administrador de la cuenta para más información.';
      case UserAccessDeniedReason.outsideAllowedHours:
        return 'Tu acceso está restringido a horarios específicos. Intenta nuevamente en el horario permitido.';
      case UserAccessDeniedReason.dayNotAllowed:
        return 'Tu acceso está restringido a días específicos. Intenta nuevamente en un día permitido.';
      default:
        return 'Contacta con el administrador para más información.';
    }
  }
}

/// Configuración visual para diferentes tipos de bloqueo
class _BlockConfiguration {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color titleColor;
  final Color infoBackgroundColor;
  final Color infoTextColor;
  final Color buttonColor;

  const _BlockConfiguration({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.titleColor,
    required this.infoBackgroundColor,
    required this.infoTextColor,
    required this.buttonColor,
  });
}
