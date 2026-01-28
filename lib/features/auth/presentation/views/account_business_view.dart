import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/inputs/currency_selector.dart';
import 'package:sellweb/core/constants/location_data.dart';
import 'package:sellweb/core/presentation/helpers/snackbar_helper.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';


class AccountBusinessView extends StatefulWidget {
  final AdminProfile admin;
  final AccountProfile? account;

  const AccountBusinessView({
    super.key,
    required this.admin,
    this.account,
  });

  @override
  State<AccountBusinessView> createState() => _AccountBusinessViewState();
}

class _AccountBusinessViewState extends State<AccountBusinessView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _townController;

  late String _selectedCurrency;
  
  // State
  bool _isLoading = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;

    _nameController = TextEditingController(text: account?.name);
    _countryController = TextEditingController(text: account?.country);
    _provinceController = TextEditingController(text: account?.province);
    _townController = TextEditingController(text: account?.town);
    
    _selectedCurrency = (account?.currencySign.isNotEmpty ?? false) 
        ? account!.currencySign 
        : 'AR\$';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _townController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final accountName = _nameController.text.trim();

      bool success = false;

      if (_isEditing) {
        // --- MODO EDICIÓN ---
        final updatedAccount = widget.account!.copyWith(
          name: accountName,
          currencySign: _selectedCurrency,
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          town: _townController.text.trim(),
        );

        success = await authProvider.updateBusinessAccount(
          updatedAccount,
          widget.admin,
        );

        if (!mounted) return;

        if (success) {
          Navigator.of(context).pop();
          if (mounted) {
            context.showSuccessSnackBar('Cuenta actualizada exitosamente');
          }
        } else {
          if (mounted) {
            context.showErrorSnackBar(authProvider.authError ?? 'Error al procesar la solicitud');
          }
        }
      } else {
        // --- MODO CREACIÓN ---
        // Navegar inmediatamente a la vista de proceso
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProcessSuccessView(
              loadingText: 'Creando cuenta...',
              successTitle: '¡Cuenta creada exitosamente!',
              successSubtitle: accountName,
              finalText: 'Redirigiendo...', 
              popCount: 1, // Hacer pop automáticamente después del éxito
              action: () async {
                // Ejecutar la lógica de creación dentro del callback
                final authProvider = context.read<AuthProvider>();
                
                // Construir la cuenta con valores por defecto
                final newAccount = authProvider.buildNewAccount(
                  name: accountName,
                  currencySign: _selectedCurrency,
                  ownerId: widget.admin.id,
                  country: _countryController.text.trim(),
                  province: _provinceController.text.trim(),
                  town: _townController.text.trim(),
                );

                final success = await authProvider.createBusinessAccount(newAccount);

                if (!context.mounted) {
                  throw Exception('Widget no está montado');
                }

                if (!success) {
                  throw Exception(authProvider.authError ?? 'Error al crear la cuenta');
                }

                // Obtener la cuenta recién creada desde el provider
                final createdAccount = authProvider.getLatestCreatedAccount();
                
                if (createdAccount == null) {
                  throw Exception('No se pudo obtener la cuenta creada');
                }
                
                // Inicializar el estado global con la nueva cuenta
                if (context.mounted) {
                  await context.read<SalesProvider>().initAccount(
                    account: createdAccount,
                    context: context,
                  );
                } else {
                  throw Exception('Widget no está montado');
                }
              },
              onError: (error) {
                // Manejar errores cerrando la vista y mostrando mensaje
                Navigator.of(context).pop();
                if (context.mounted) {
                  context.showErrorSnackBar(error.toString().replaceFirst('Exception: ', ''));
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error inesperado: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final headerColor = color ?? theme.colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: headerColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: headerColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteBusiness() async {
    final theme = Theme.of(context);
    final accountName = widget.account?.name ?? 'Cuenta de negocio';
    final isOwner = widget.admin.superAdmin;
    
    // Configurar textos según rol (Dueño vs Empleado)
    final title = isOwner ? '¿Eliminar negocio?' : '¿Salir del negocio?';
    final content = isOwner 
        ? 'Estás a punto de eliminar "$accountName".\n\nEsta acción es IRREVERSIBLE. Se perderán todos los datos:\n• Catálogo de productos\n• Historial de ventas\n• Registros de caja\n• Accesos de usuarios'
        : 'Estás a punto de salir de "$accountName".\n\nPerderás el acceso a sus datos, pero tu usuario personal seguirá activo en otros comercios.';
    
    final confirmBtnText = isOwner ? 'Sí, eliminar permanentemente' : 'Sí, salir del negocio';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        icon: Icon(Icons.warning_amber_rounded,
            color: theme.colorScheme.error, size: 48),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmBtnText)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _handleDeleteBusiness(accountName, isOwner);
  }

  void _handleDeleteBusiness(String accountName, bool isOwner) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: isOwner ? 'Eliminando cuenta...' : 'Saliendo del negocio...',
          successTitle: isOwner ? '¡Cuenta eliminada!' : '¡Salida exitosa!',
          successSubtitle: accountName,
          finalText: 'Redirigiendo...',
          loadingDuration: 1500,
          successDuration: 2000,
          playSound: false,
          onComplete: () async {
            final authProvider = context.read<AuthProvider>();
            final salesProvider = context.read<SalesProvider>();
            
            // Usar el método unificado que discierne entre eliminar o salir según el rol
            final success = await authProvider.deleteAdminAccess(
                widget.account!.id, 
                widget.admin
            );

            if (!context.mounted) return;

            if (success) {
              salesProvider.cleanData();
              
              // Navegar al root para que updatee la UI de HomePage
              // Esto sacará la visa de ProcessView, luego la vista de AccountBusinessView
              // Y finalmente volverá a la pantalla de selección si es necesario
               Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).pop();
              if (context.mounted) {
                context.showErrorSnackBar(authProvider.authError ?? 'Error al procesar la solicitud');
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    final isOwner = widget.admin.superAdmin;
    final title = isOwner ? 'Eliminar este negocio' : 'Salir de este negocio';
    final subtitle = isOwner 
        ? 'Borra permanentemente la cuenta y todos sus datos'
        : 'Remueve tu acceso a este negocio';

    return ListTile(
      contentPadding: EdgeInsets.zero, 
      title: Text(
        title,
        style: TextStyle(
            color: errorColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
      ),
      onTap: _isLoading ? null : _confirmDeleteBusiness,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cuenta' : 'Crear Cuenta'),
        centerTitle: false,
      ), 
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleSave, 
        label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección: Información del Negocio
                  _buildSectionHeader(
                    context: context,
                    title: 'Información del Negocio',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  
                  // Username (REMOVED)

                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Negocio',
                      hintText: 'ej: Mi Tienda Online',
                      prefixIcon: const Icon(Icons.storefront_sharp),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del negocio es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Moneda
                  CurrencySelector(
                    selectedCurrency: _selectedCurrency,
                    onChanged: (currency) {
                      if (currency != null) {
                        setState(() => _selectedCurrency = currency);
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Sección: Ubicación
                  _buildSectionHeader(
                    context: context,
                    title: 'Ubicación${_isEditing ? '' : ' (Opcional)'}',
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 16),

                  // País
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        controller: _countryController,
                        width: constraints.maxWidth,
                        label: const Text('País'),
                        initialSelection: _countryController.text.isNotEmpty 
                            ? _countryController.text 
                            : 'Argentina', 
                        leadingIcon: const Icon(Icons.emoji_flags_sharp),
                        requestFocusOnTap: false,
                        enableFilter: false,
                        dropdownMenuEntries: LocationData.countries.map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  // Provincia
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                         controller: _provinceController,
                         width: constraints.maxWidth,
                         label: const Text('Provincia/Estado'),
                         initialSelection: _provinceController.text,
                         leadingIcon: const Icon(Icons.map_rounded),
                         requestFocusOnTap: false,
                         enableFilter: false,
                         dropdownMenuEntries: LocationData.provincesArgentina.map<DropdownMenuEntry<String>>((String value) {
                           return DropdownMenuEntry<String>(value: value, label: value);
                         }).toList(),
                         inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  // Ciudad
                  TextFormField(
                    controller: _townController,
                    decoration: InputDecoration(
                      labelText: 'Ciudad',
                      hintText: 'ej: La Plata',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  
                  const SizedBox(height: 60),

                  // ZONA DE PELIGRO
                  if (_isEditing) ...[
                    const Divider(height:50),  
                    _buildDangerZone(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
