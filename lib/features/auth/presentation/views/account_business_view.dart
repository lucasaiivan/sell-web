import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/inputs/currency_selector.dart';
import 'package:sellweb/core/constants/location_data.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/success/creation_success_view.dart';


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

    try {
      final authProvider = context.read<AuthProvider>();
      
      bool success = false;
      String accountName = _nameController.text.trim();

      if (_isEditing) {
        // --- MODO EDICIÓN ---
        setState(() => _isLoading = true);
        
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

        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pop();
          _showSuccess('Cuenta actualizada exitosamente');
        } else {
          _showError('Error al procesar la solicitud');
        }
      } else {
        // --- MODO CREACIÓN ---
        setState(() => _isLoading = true);

        // Crear la cuenta
        final newAccount = AccountProfile(
          name: accountName,
          currencySign: _selectedCurrency,
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          town: _townController.text.trim(),
          ownerId: widget.admin.id,
          creation: DateTime.now(),
          trialStart: DateTime.now(),
          trialEnd: DateTime.now().add(const Duration(days: 30)),
        );

        success = await authProvider.createBusinessAccount(newAccount);

        if (!mounted) return;
        
        setState(() => _isLoading = false);

        if (success) {
          // Obtener la cuenta recién creada de la lista actualizada
          final createdAccount = authProvider.accountsAssociateds.last;
          
          // Guardar como cuenta seleccionada e inicializar el estado global
          if (mounted) {
            await context.read<SalesProvider>().initAccount(
              account: createdAccount,
              context: context,
            );
          }

          if (!mounted) return;

          // Navegar a la vista de éxito REEMPLAZANDO la vista actual
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CreationSuccessView(
                loadingText: 'Finalizando...',
                successTitle: '¡Cuenta creada!',
                successSubtitle: accountName,
                finalText: 'Redirigiendo...',
                loadingDuration: 500, // Breve pausa inicial
                successDuration: 2000,
                onComplete: () {
                   Navigator.of(context).pop(); 
                },
              ),
            ),
          );
        } else {
           _showError('Error al crear la cuenta: ${authProvider.authError ?? "Intente nuevamente"}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error inesperado: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
