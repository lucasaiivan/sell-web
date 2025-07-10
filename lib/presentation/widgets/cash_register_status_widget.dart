import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/cash_register_provider.dart';
import '../../presentation/providers/sell_provider.dart';
import '../../core/widgets/buttons/app_bar_button.dart';

/// Widget que muestra un botón para ver el estado de la caja registradora.
/// Al tocarlo, abre un diálogo con los detalles.
class CashRegisterStatusWidget extends StatefulWidget {
  const CashRegisterStatusWidget({super.key});

  @override
  State<CashRegisterStatusWidget> createState() =>
      _CashRegisterStatusWidgetState();
}

class _CashRegisterStatusWidgetState extends State<CashRegisterStatusWidget> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales sin esperar al build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sellProvider = context.read<SellProvider>();
      final accountId = sellProvider.profileAccountSelected.id;
      if (accountId.isNotEmpty) {
        context.read<CashRegisterProvider>().loadActiveCashRegisters(accountId);
      }
    });
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        // Provee el CashRegisterProvider existente al diálogo.
        return ChangeNotifierProvider.value(
          value: context.read<CashRegisterProvider>(),
          child: const _CashRegisterStatusDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        final bool isActive = provider.hasActiveCashRegister;
        return AppBarButtonCircle(
          icon: Icons.point_of_sale_outlined,
          tooltip: isActive ? 'Caja abierta' : 'Caja cerrada',
          onPressed: () => _showStatusDialog(context),
          backgroundColor:
              isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          iconColor: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          text: isActive ? 'Abierta' : 'Abrir Caja',
        );
      },
    );
  }
}

/// Diálogo que muestra el estado detallado de la caja registradora.
class _CashRegisterStatusDialog extends StatelessWidget {
  const _CashRegisterStatusDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      title: Row(
        children: [
          const Icon(Icons.point_of_sale, size: 28),
          const SizedBox(width: 8),
          Text(
            'Estado de Caja',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Consumer<CashRegisterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingActive) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SizedBox(
            width: 400, // Ancho fijo para el diálogo
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.hasActiveCashRegister)
                    _buildActiveCashRegisterInfo(context, provider)
                  else
                    _buildNoCashRegisterInfo(context, provider),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveCashRegisterInfo(
      BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caja "${cashRegister.description}" abierta',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        // Aquí iría el resto de la información de la caja activa.
        // Por simplicidad, solo se muestra un botón para cerrar.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: const Text('Cerrar Caja'),
            onPressed: () {
              // Lógica para cerrar caja
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCashRegisterInfo(
      BuildContext context, CashRegisterProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No hay ninguna caja abierta.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Abrir Caja'),
            onPressed: () {
              // Lógica para abrir caja
            },
          ),
        ),
      ],
    );
  }
}
