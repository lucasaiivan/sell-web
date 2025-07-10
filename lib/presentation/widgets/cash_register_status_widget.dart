import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cash_register_provider.dart';
import '../providers/sell_provider.dart';
import '../dialogs/cash_register_management_dialog.dart';
import '../../core/widgets/buttons/app_bar_button.dart';

/// Widget que muestra un botón para ver el estado de la caja registradora.
/// Al tocarlo, abre un diálogo con los detalles.
class CashRegisterStatusWidget extends StatefulWidget {
  const CashRegisterStatusWidget({super.key});

  @override
  State<CashRegisterStatusWidget> createState() => _CashRegisterStatusWidgetState();
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
    // Capturar todos los providers necesarios antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const CashRegisterManagementDialog(),
      ),
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
