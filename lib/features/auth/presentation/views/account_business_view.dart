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
        // Usar el método del provider para construir la cuenta con valores por defecto
        final newAccount = authProvider.buildNewAccount(
          name: accountName,
          currencySign: _selectedCurrency,
          ownerId: widget.admin.id,
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          town: _townController.text.trim(),
        );

        success = await authProvider.createBusinessAccount(newAccount);

        if (!mounted) return;

        if (success) {
          // Obtener la cuenta recién creada desde el provider
          final createdAccount = authProvider.getLatestCreatedAccount();
          
          if (createdAccount == null) {
            if (mounted) {
              context.showErrorSnackBar('Error: No se pudo obtener la cuenta creada');
            }
            return;
          }
          
          // Inicializar el estado global con la nueva cuenta
          if (mounted) {
            await context.read<SalesProvider>().initAccount(
              account: createdAccount,
              context: context,
            );
          }

          if (!mounted) return;

          // Navegar a la vista de éxito
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProcessSuccessView(
                loadingText: 'Finalizando...',
                successTitle: '¡Cuenta creada!',
                successSubtitle: accountName,
                finalText: 'Redirigiendo...',
                loadingDuration: 500,
                successDuration: 2000,
                onComplete: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        } else {
          if (mounted) {
            context.showErrorSnackBar(authProvider.authError ?? 'Error al crear la cuenta');
          }
        }
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
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar negocio?'),
        icon: Icon(Icons.warning_amber_rounded,
            color: theme.colorScheme.error, size: 48),
        content: Text(
            'Estás a punto de eliminar "$accountName".\n\nEsta acción es IRREVERSIBLE. Se perderán todos los datos:\n• Catálogo de productos\n• Historial de ventas\n• Registros de caja\n• Accesos de usuarios'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, eliminar permanentemente')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _handleDeleteBusiness(accountName);
  }

  void _handleDeleteBusiness(String accountName) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: 'Eliminando cuenta...',
          successTitle: '¡Cuenta eliminada!',
          successSubtitle: accountName,
          finalText: 'Redirigiendo...',
          loadingDuration: 1500,
          successDuration: 2000,
          playSound: false,
          onComplete: () async {
            final authProvider = context.read<AuthProvider>();
            final salesProvider = context.read<SalesProvider>();
            
            final success = await authProvider.deleteBusinessAccount(widget.account!.id);

            if (!context.mounted) return;

            if (success) {
              salesProvider.cleanData();
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pop();
              if (context.mounted) {
                context.showErrorSnackBar(authProvider.authError ?? 'Error al eliminar negocio');
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_forever_rounded, color: errorColor),
      ),
      title: Text(
        'Eliminar este negocio',
        style: TextStyle(
            color: errorColor, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        'Borra permanentemente este negocio y sus datos.',
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
