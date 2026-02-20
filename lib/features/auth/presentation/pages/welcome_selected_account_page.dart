import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/presentation/views/account_business_view.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeSelectedAccountPage extends StatefulWidget {
  final Future<void> Function(AccountProfile) onSelectAccount;

  const WelcomeSelectedAccountPage({super.key, required this.onSelectAccount});

  @override
  State<WelcomeSelectedAccountPage> createState() => _WelcomeSelectedAccountPageState();
}

class _WelcomeSelectedAccountPageState extends State<WelcomeSelectedAccountPage> {
  // GlobalKeys para el showcase
  final GlobalKey _demoAccountKey = GlobalKey();
  final GlobalKey _createAccountKey = GlobalKey();
  final GlobalKey _themeButtonKey = GlobalKey();
  final GlobalKey _emailLogoutKey = GlobalKey();
  
  // Flag para evitar múltiples inicializaciones
  bool _showcaseInitialized = false;

  @override
  void initState() {
    super.initState();
    // El showcase se iniciará desde el builder después de construir el widget
  }

  /// Verifica y inicia el showcase si corresponde
  Future<void> _checkAndStartShowcase(BuildContext showcaseContext) async {
    // Evitar múltiples inicializaciones
    if (_showcaseInitialized) return;
    _showcaseInitialized = true;
    
    final shouldShow = await _shouldShowShowcase();
    if (!shouldShow) return;
    
    // Esperar a que el widget tree esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay adicional para asegurar que ShowCaseWidget esté listo
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _markShowcaseAsShown();
          _startShowcase(showcaseContext);
        }
      });
    });
  }

  /// Obtiene la ubicación prioritaria de la cuenta
  String _getAccountLocation(AccountProfile account) {
    if (account.town.isNotEmpty) return account.town;
    if (account.province.isNotEmpty) return account.province;
    if (account.country.isNotEmpty) return account.country;
    if (account.countrycode.isNotEmpty) return account.countrycode;
    return '';
  }

  /// Verifica si es la primera vez que se muestra el showcase
  Future<bool> _shouldShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('guest_mode_showcase_shown') ?? false);
  }

  /// Marca el showcase como mostrado
  Future<void> _markShowcaseAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode_showcase_shown', true);
  }

  /// Inicia el showcase
  void _startShowcase(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      _demoAccountKey,
      _createAccountKey,
      _themeButtonKey,
      _emailLogoutKey,
    ]);
  }

  /// Maneja la selección de cuenta
  Future<void> _handleAccountSelection(AccountProfile account) async {
    // Llamar al callback original
    await widget.onSelectAccount(account);
  }

  /// Construye una tarjeta de cuenta con avatar, nombre y ubicación mejorada
  Widget _buildAccountCard(BuildContext context, AccountProfile account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtener la ubicación con prioridad
    final location = _getAccountLocation(account);

    final card = InkWell(
      onTap: () async => await _handleAccountSelection(account),
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar mejorado con sombra sutil
            UserAvatar(
              imageUrl: account.image,
              text:
                  account.name.isNotEmpty ? account.name[0].toUpperCase() : '',
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre de la cuenta con mejor tipografía
                  Text(
                    account.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (account.id == 'demo') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MODO PRUEBA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Ubicación con icono y mejor estilo
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Icono de flecha para indicar acción
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );

    // Si es la cuenta demo, envolver con Showcase
    if (account.id == 'demo') {
      return Showcase(
        key: _demoAccountKey,
        title: '🎭 Cuenta de Prueba',
        description: 'Úsala para explorar la aplicación sin necesidad de registro. ¡Todos los datos son de ejemplo!',
        targetBorderRadius: BorderRadius.circular(12),
        targetPadding: const EdgeInsets.all(8),
        child: card,
      );
    }

    return card;
  }

  /// Construye el item para crear una nueva cuenta
  Widget _buildCreateAccountItem(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Showcase(
      key: _createAccountKey,
      title: 'Crea tu propia cuenta para tu Comercio',
      description: 'Configura tu propio negocio para gestionar inventarios, ventas y personal de forma profesional.',
      targetBorderRadius: BorderRadius.circular(12),
      targetPadding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () async {
          // Si es invitado, redirigir a cerrar sesión (login)
          if (authProvider.isGuest) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Iniciar sesión'),
                content: const Text(
                    'Para crear una cuenta debes iniciar sesión con un usuario real. ¿Deseas ir al login?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Ir al login'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await authProvider.signOut();
            }
            return;
          }

          // Para crear una cuenta necesitamos el ID del usuario actual
          final userId = authProvider.user?.uid;
          if (userId != null) {
            // Crear perfil admin temporal para la creación
            final tempAdmin = AdminProfile(
              id: userId,
              email: authProvider.user?.email ?? '',
              name: authProvider.user?.displayName ?? '',
              creation: DateTime.now(),
              lastUpdate: DateTime.now(),
            );
            
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccountBusinessView(
                  admin: tempAdmin,
                ),
              ),
            );
          }
        },
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                authProvider.isGuest ? Icons.login : Icons.add,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                authProvider.isGuest 
                    ? 'Iniciar sesión para crear una cuenta'
                    : 'Crear cuenta',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // providers
    final authProvider = Provider.of<AuthProvider>(context);
    List<AccountProfile> accounts = authProvider.accountsWithDemo;
    
    // Preparar items de la lista
    List<Widget> listItems = [];
    
    // Añadir cuentas existentes
    listItems.addAll(accounts.map((account) => _buildAccountCard(context, account)));
    
    // Añadir botón de crear cuenta si corresponde
    if (!authProvider.isLoadingAccounts && authProvider.user != null) {
      listItems.add(_buildCreateAccountItem(context, authProvider));
    }

    return ShowCaseWidget(
      builder: (context) => Builder(
        builder: (builderContext) {
          // Iniciar showcase automáticamente si es la primera vez
          _checkAndStartShowcase(builderContext);
          
          return Scaffold(
            body: Stack(
              children: [
                // view : body
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront,
                            size: 80, color: Colors.blueGrey),
                        const SizedBox(height: 12),
                        const Text('¡Bienvenido!',
                            style:
                                TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 50),
                        if (accounts.isNotEmpty)
                          const Text(
                            'Selecciona una cuenta para continuar',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 24),
                        // view notification : si no hay cuentas disponibles, muestra un mensaje informativo
                        if (authProvider.isLoadingAccounts)
                          const Center(child: CircularProgressIndicator()),
                        if (accounts.isEmpty &&
                            authProvider.isLoadingAccounts == false)
                          // Si no hay cuentas disponibles, muestra un mensaje informativo
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blueGrey, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blueGrey, size: 18),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'No tienes cuentas disponibles',
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // view : lista de cuentas y acciones
                        if (listItems.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: DialogComponents.itemList(
                              padding: const EdgeInsets.all(0),
                              context: context,
                              items: listItems,
                              showDividers: true,
                              maxVisibleItems: 4,
                              expandText: 'Ver más opciones',
                              collapseText: 'Ver menos',
                              borderRadius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        const SizedBox(height:20),
                        // text : Mostrar el correo electrónico del usuario
                        authProvider.isLoadingAccounts
                            ? Container()
                            : Column(
                              children: [
                                Text(
                                  authProvider.user?.email ?? 'Invitado',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                // button : Cerrar sesión de Firebase Auth
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirmar'),
                                        content: const Text(
                                            '¿Seguro que deseas cerrar sesión?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Cerrar sesión'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await authProvider.signOut();
                                    }
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Cerrar sesión'),
                                ),
                              ],
                            )
                      ],
                    ),
                  ),
                ),
                // button : cambiar el brillo de tema de la aplicación
                Positioned(
                  top: 20,
                  right: 20,
                  child: Consumer<ThemeDataAppProvider>(
                    builder: (context, themeProvider, _) => Showcase(
                      key: _themeButtonKey,
                      title: '🎨 Cambiar Tema',
                      description: 'Cambia entre modo claro y oscuro según tu preferencia para una mejor experiencia visual',
                      targetBorderRadius: BorderRadius.circular(50),
                      targetPadding: const EdgeInsets.all(8),
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Cambiar brillo',
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
