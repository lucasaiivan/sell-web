import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/presentation/widgets/inputs/currency_selector.dart';
import 'package:sellweb/core/presentation/widgets/inputs/username_text_field.dart';
import 'package:sellweb/core/constants/location_data.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/domain/usecases/check_username_availability_usecase.dart';
import 'package:sellweb/features/auth/domain/usecases/validate_username_usecase.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';

/// Diálogo unificado para Crear o Editar una cuenta comercio
///
/// Si [account] es null, se asume modo CREACIÓN.
/// Si [account] no es null, se asume modo EDICIÓN.
///
/// ## Ejemplo de uso:
/// ```dart
/// // Crear
/// showAccountBusinessDialog(
///   context: context,
///   currentAdmin: adminProfile,
/// );
///
/// // Editar
/// showAccountBusinessDialog(
///   context: context,
///   currentAdmin: adminProfile,
///   account: accountToEdit,
/// );
/// ```
Future<void> showAccountBusinessDialog({
  required BuildContext context,
  required AdminProfile currentAdmin,
  AccountProfile? account,
}) {
  final isEditing = account != null;
  
  // Si estamos creando (no editando), verificar restricción de 30 días
  if (!isEditing && !currentAdmin.canCreateAccount()) {
    final days = currentAdmin.daysUntilCanCreateAccount();
    final message = days == 1
        ? 'Solo puedes crear una cuenta cada 30 días.\nPodrás crear otra cuenta en 1 día.'
        : 'Solo puedes crear una cuenta cada 30 días.\nPodrás crear otra cuenta en $days días.';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restricción de Creación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  final contentKey = GlobalKey<_AccountBusinessContentState>();

  return showBaseDialog(
    context: context,
    title: isEditing ? 'Editar Cuenta' : 'Crear Cuenta',
    width: 600,
    content: _AccountBusinessContent(
      key: contentKey,
      admin: currentAdmin,
      account: account,
    ),
    actions: [
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
      DialogComponents.primaryActionButton(
        context: context,
        text: isEditing ? 'Guardar Cambios' : 'Crear Cuenta', 
        onPressed: () => contentKey.currentState?._handleSave(),
      ),
    ],
  );
}

class _AccountBusinessContent extends StatefulWidget {
  final AdminProfile admin;
  final AccountProfile? account;

  const _AccountBusinessContent({
    super.key,
    required this.admin,
    this.account,
  });

  @override
  State<_AccountBusinessContent> createState() => _AccountBusinessContentState();
}

class _AccountBusinessContentState extends State<_AccountBusinessContent> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _townController;

  late String _selectedCurrency;
  
  // State
  bool _isUsernameValid = false;
  String? _validatedUsername;
  bool _isLoading = false;
  bool _isUsernameFieldEnabled = false; // Nuevo estado para controlar habilitación
  String? _usernameRestrictionMessage; // Mensaje de feedback

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;

    // Habilitar campo si es creación (account == null), deshabilitar si es edición
    _isUsernameFieldEnabled = !_isEditing;

    _usernameController = TextEditingController(text: account?.username);
    _nameController = TextEditingController(text: account?.name);
    _countryController = TextEditingController(text: account?.country);
    _provinceController = TextEditingController(text: account?.province);
    _townController = TextEditingController(text: account?.town);
    
    _selectedCurrency = (account?.currencySign.isNotEmpty ?? false) 
        ? account!.currencySign 
        : 'AR\$';

    // En edición, el username ya es válido inicialmente
    if (_isEditing) {
      _isUsernameValid = true;
      _validatedUsername = account!.username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
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

    // Validaciones de username: Validar si estamos creando O si se habilitó la edición
    if ((!_isEditing || _isUsernameFieldEnabled) && (!_isUsernameValid || _validatedUsername == null)) {
      _showError('Por favor verifica que el nombre de usuario sea válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      bool success = false;

      if (_isEditing) {
        // --- MODO EDICIÓN ---
        // Determinar el username final
        // Si no se puede actualizar o no cambió, se mantiene el original
        final finalUsername = (widget.account!.canUpdateUsername() && _validatedUsername != null)
            ? _validatedUsername!
            : widget.account!.username;

        // Verificar si el username cambió realmente
        final usernameChanged = finalUsername != widget.account!.username;

        final updatedAccount = widget.account!.copyWith(
          username: finalUsername,
          name: _nameController.text.trim(),
          currencySign: _selectedCurrency,
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          town: _townController.text.trim(),
          // Si el username cambió, actualizamos la fecha de última actualización
          lastUsernameUpdate: usernameChanged ? DateTime.now() : widget.account!.lastUsernameUpdate,
        );

        success = await authProvider.updateBusinessAccount(
          updatedAccount,
          widget.admin,
        );
      } else {
        // --- MODO CREACIÓN ---
        final newAccount = AccountProfile(
          username: _validatedUsername!, // En creación es obligatorio
          name: _nameController.text.trim(),
          currencySign: _selectedCurrency,
          country: _countryController.text.trim(),
          province: _provinceController.text.trim(),
          town: _townController.text.trim(),
          ownerId: widget.admin.id,
          creation: DateTime.now(),
          trialStart: DateTime.now(),
          trialEnd: DateTime.now().add(const Duration(days: 30)),
          // En creación, lastUsernameUpdate puede ser null o la fecha actual si queremos contar desde el inicio
          // Generalmente null hasta el primer cambio explícito, o now. Lo dejaremos null o now según preferencia.
          // Si queremos que cuente como "primer cambio", lo dejamos null.
          lastUsernameUpdate: DateTime.now(), 
        );

        success = await authProvider.createBusinessAccount(newAccount);
        
        // Si se creó exitosamente, actualizar lastAccountCreation del admin
        if (success) {
          await _updateAdminLastAccountCreation(authProvider);
        }
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        _showSuccess(_isEditing 
            ? 'Cuenta actualizada exitosamente' 
            : 'Cuenta creada exitosamente');
      } else {
        _showError('Error al procesar la solicitud');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error inesperado: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Actualiza el timestamp de última creación de cuenta del administrador
  Future<void> _updateAdminLastAccountCreation(AuthProvider authProvider) async {
    try {
      final user = authProvider.user;
      if (user == null || user.email == null || user.email!.isEmpty) {
        debugPrint('⚠️ No se puede actualizar lastAccountCreation: usuario no disponible');
        return;
      }

      // Actualizar en Firestore: /USERS/{email}/ACCOUNTS/{accountId}
      final firestore = FirebaseFirestore.instance;
      final accountId = widget.admin.account;
      
      if (accountId.isEmpty) {
        debugPrint('⚠️ No se puede actualizar lastAccountCreation: accountId vacío');
        return;
      }

      await firestore
          .doc(FirestorePaths.userManagedAccount(user.email!, accountId))
          .update({'lastAccountCreation': Timestamp.fromDate(DateTime.now())});
      
      debugPrint('✅ lastAccountCreation actualizado para ${user.email}');
    } catch (e) {
      debugPrint('❌ Error al actualizar lastAccountCreation: $e');
      // No mostrar error al usuario, es una operación secundaria
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sección: Información del Negocio (Unificada)
          DialogComponents.infoSection(
            context: context,
            title: 'Información del Negocio',
            icon: Icons.business_rounded,
            content: Column(
              children: [
                // Username (Editable o Read-only)
                _buildUsernameSection(context, authProvider),
                
                DialogComponents.itemSpacing,
                
                // Nombre y Moneda siempre en el mismo grupo
                _buildBusinessInfoFields(context),
              ],
            ),
          ),

          DialogComponents.sectionSpacing,

          // Sección: Ubicación
          DialogComponents.infoSection(
            context: context,
            title: 'Ubicación${_isEditing ? '' : ' (Opcional)'}',
            icon: Icons.location_on_rounded,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // País Dropdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<String>(
                      controller: _countryController,
                      width: constraints.maxWidth,
                      label: const Text('País'),
                      initialSelection: _countryController.text.isNotEmpty 
                          ? _countryController.text 
                          : 'Argentina', // Default
                      leadingIcon: const Icon(Icons.emoji_flags_sharp),
                      requestFocusOnTap: false, // Evitar teclado
                      enableFilter: false, // Evitar edición de texto
                      dropdownMenuEntries: LocationData.countries.map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(value: value, label: value);
                      }).toList(),
                      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                ),
                
                DialogComponents.itemSpacing,
                
                // Provincia Dropdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<String>(
                      controller: _provinceController,
                      width: constraints.maxWidth,
                      label: const Text('Provincia/Estado'),
                      initialSelection: _provinceController.text,
                      leadingIcon: const Icon(Icons.map_rounded),
                      requestFocusOnTap: false, // Evitar teclado
                      enableFilter: false, // Evitar edición de texto
                      dropdownMenuEntries: LocationData.provincesArgentina.map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(value: value, label: value);
                      }).toList(),
                      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                ),
                
                DialogComponents.itemSpacing,
                
                DialogComponents.textField(
                  context: context,
                  controller: _townController,
                  label: 'Ciudad',
                  hint: 'ej: La Plata',
                  prefixIcon: Icons.location_city_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            UsernameTextField(
              controller: _usernameController,
              enabled: _isUsernameFieldEnabled,
              validateUseCase: ValidateUsernameUseCase(),
              checkAvailabilityUseCase: CheckUsernameAvailabilityUseCase(
                authProvider.authRepository,
              ),
              onUsernameValidated: (isValid, username) {
                if (!mounted) return;
                if (_isUsernameValid != isValid || _validatedUsername != username) {
                   setState(() {
                    _isUsernameValid = isValid;
                    _validatedUsername = username;
                  });
                }
              },
              autofocus: !_isEditing, 
              // Si estamos editando y el campo no está habilitado, mostrar el username original como hint no es necesario pq el controller tiene el texto
            ),
            
            // Botón Editar (Solo visible en modo edición y si el campo está deshabilitado)
            if (_isEditing && !_isUsernameFieldEnabled)
              Positioned(
                right: 8,
                child: TextButton(
                  onPressed: () {
                    // Verificar si puede actualizar
                    if (widget.account!.canUpdateUsername()) {
                      setState(() {
                        _isUsernameFieldEnabled = true;
                        _usernameRestrictionMessage = null;
                      });
                    } else {
                       setState(() {
                        final days = widget.account!.daysUntilUsernameUpdate();
                        _usernameRestrictionMessage = 'Solo se puede actualizar 1 vez cada 30 días. Podrás hacerlo en $days días.';
                      });
                    }
                  },
                  child: const Text('Editar'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ),
        
        // Feedback message (Error/Info) sobre restricción de 30 días
        if (_usernameRestrictionMessage != null)
           Padding(
             padding: const EdgeInsets.only(top: 8, left: 12),
             child: Text(
               _usernameRestrictionMessage!,
               style: TextStyle(
                 color: Theme.of(context).colorScheme.error,
                 fontSize: 12,
               ),
             ),
           ),
      ],
    );
  }

  Widget _buildBusinessInfoFields(BuildContext context) {
    return Column(
      children: [
         DialogComponents.textField(
            context: context,
            controller: _nameController,
            label: 'Nombre del Negocio',
            hint: 'ej: Mi Tienda Online',
            prefixIcon: Icons.storefront_sharp,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre del negocio es requerido';
              }
              return null;
            },
          ),
          DialogComponents.itemSpacing,
          CurrencySelector(
            selectedCurrency: _selectedCurrency,
            onChanged: (currency) {
              if (currency != null) {
                setState(() => _selectedCurrency = currency);
              }
            },
          ),
      ],
    );
  }
}
