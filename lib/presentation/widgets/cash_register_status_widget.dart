import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/cash_register_provider.dart';
import '../../presentation/providers/sell_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../core/utils/fuctions.dart';
import '../../core/widgets/buttons/app_bar_button.dart';

/// Widget que muestra el estado actual de la caja registradora
/// 
/// Incluye:
/// - Información de la caja activa
/// - Botones de apertura/cierre
/// - Resumen de movimientos
class CashRegisterStatusWidget extends StatefulWidget {
  const CashRegisterStatusWidget({super.key});

  @override
  State<CashRegisterStatusWidget> createState() => _CashRegisterStatusWidgetState();
}

class _CashRegisterStatusWidgetState extends State<CashRegisterStatusWidget> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CashRegisterProvider>();
      final sellProvider = context.read<SellProvider>();
      final accountId = sellProvider.profileAccountSelected.id;
      
      if (accountId.isNotEmpty) {
        provider.loadActiveCashRegisters(accountId);
        provider.loadFixedDescriptions(accountId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con botón de estado
                Row(
                  children: [
                    const Icon(Icons.point_of_sale, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Estado de Caja',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    // Botón dinámico de estado de caja
                    _buildCashRegisterButton(context, provider),
                  ],
                ),
                const SizedBox(height: 16),

                // Estado de carga
                if (provider.isLoadingActive)
                  const Center(child: CircularProgressIndicator())
                else if (provider.hasActiveCashRegister)
                  _buildActiveCashRegisterInfo(context, provider)
                else
                  _buildNoCashRegisterInfo(context, provider),

                // Mensaje de error
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: provider.clearError,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveCashRegisterInfo(BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado activo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                'CAJA ABIERTA',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Información básica
        Text(
          cashRegister.description,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        Text(
          'Abierta: ${_formatDateTime(cashRegister.opening)}',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Métricas en grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard(
              'Monto Inicial',
              Publications.getFormatoPrecio(value: cashRegister.initialCash),
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            _buildMetricCard(
              'Ventas',
              '${cashRegister.sales} items',
              Icons.shopping_cart,
              Colors.orange,
            ),
            _buildMetricCard(
              'Facturación',
              Publications.getFormatoPrecio(value: cashRegister.billing),
              Icons.attach_money,
              Colors.green,
            ),
            _buildMetricCard(
              'Balance Esperado',
              Publications.getFormatoPrecio(value: cashRegister.getExpectedBalance),
              Icons.calculate,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCashMovementDialog(context, provider, true),
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text('Ingreso'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.green,
                  backgroundColor: Colors.green.shade50,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCashMovementDialog(context, provider, false),
                icon: const Icon(Icons.remove, color: Colors.red),
                label: const Text('Egreso'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCloseCashRegisterDialog(context, provider),
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoCashRegisterInfo(BuildContext context, CashRegisterProvider provider) {
    return Column(
      children: [
        Icon(
          Icons.point_of_sale_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No hay caja registradora abierta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para comenzar a vender, primero debes abrir una caja',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showOpenCashRegisterDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Abrir Caja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenCashRegisterDialog(BuildContext context, CashRegisterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caja Registradora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: provider.openDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Caja Principal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: provider.initialCashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Inicial',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: provider.isProcessing
                ? null
                : () async {
                    final sellProvider = context.read<SellProvider>();
                    final authProvider = context.read<AuthProvider>();
                    final accountId = sellProvider.profileAccountSelected.id;
                    final userId = authProvider.user?.uid ?? '';
                    
                    final success = await provider.openCashRegister(
                      accountId,
                      userId,
                    );
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: provider.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Abrir Caja'),
          ),
        ],
      ),
    );
  }

  void _showCloseCashRegisterDialog(BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Caja Registradora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Esperado: ${Publications.getFormatoPrecio(value: cashRegister.getExpectedBalance)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: provider.finalBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Balance Real',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: provider.isProcessing
                ? null
                : () async {
                    final sellProvider = context.read<SellProvider>();
                    final accountId = sellProvider.profileAccountSelected.id;
                    
                    final success = await provider.closeCashRegister(
                      accountId,
                      cashRegister.id,
                    );
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: provider.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }

  void _showCashMovementDialog(BuildContext context, CashRegisterProvider provider, bool isInflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isInflow ? 'Ingreso de Caja' : 'Egreso de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Descripciones fijas
            if (provider.fixedDescriptions.isNotEmpty) ...[
              const Text('Descripciones frecuentes:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: provider.fixedDescriptions.map((desc) {
                  return ActionChip(
                    label: Text(desc),
                    onPressed: () => provider.setMovementDescription(desc),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: provider.movementDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Pago de servicios',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: provider.movementAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: provider.isProcessing
                ? null
                : () async {
                    final sellProvider = context.read<SellProvider>();
                    final authProvider = context.read<AuthProvider>();
                    final accountId = sellProvider.profileAccountSelected.id;
                    final userId = authProvider.user?.uid ?? '';
                    
                    final success = isInflow
                        ? await provider.addCashInflow(
                            accountId,
                            provider.currentActiveCashRegister!.id,
                            userId,
                          )
                        : await provider.addCashOutflow(
                            accountId,
                            provider.currentActiveCashRegister!.id,
                            userId,
                          );
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isInflow ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: provider.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isInflow ? 'Registrar Ingreso' : 'Registrar Egreso'),
          ),
        ],
      ),
    );
  }

  /// Construye el botón dinámico de estado de caja usando AppBarButton
  Widget _buildCashRegisterButton(BuildContext context, CashRegisterProvider provider) {
    final bool hasCashRegister = provider.hasActiveCashRegister;
    final String buttonText = hasCashRegister 
        ? provider.currentActiveCashRegister!.description
        : 'Iniciar caja';
    
    final IconData buttonIcon = hasCashRegister 
        ? Icons.check_circle 
        : Icons.add_circle_outline;
    
    final Color? buttonColor = hasCashRegister 
        ? Colors.green.shade600 
        : null; // Usa el color por defecto del tema
    
    return AppBarButton(
      text: buttonText,
      iconLeading: buttonIcon,
      colorBackground: buttonColor,
      onTap: hasCashRegister 
          ? () => _showCashRegisterDetailsDialog(context, provider)
          : () => _showOpenCashRegisterDialog(context, provider),
    );
  }

  /// Muestra un diálogo con los detalles de la caja activa
  void _showCashRegisterDetailsDialog(BuildContext context, CashRegisterProvider provider) {
    final cashRegister = provider.currentActiveCashRegister!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Detalles de Caja'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cashRegister.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Abierta:', _formatDateTime(cashRegister.opening)),
            _buildDetailRow('Monto Inicial:', Publications.getFormatoPrecio(value: cashRegister.initialCash)),
            _buildDetailRow('Ventas:', '${cashRegister.sales} items'),
            _buildDetailRow('Facturación:', Publications.getFormatoPrecio(value: cashRegister.billing)),
            _buildDetailRow('Balance Esperado:', Publications.getFormatoPrecio(value: cashRegister.getExpectedBalance)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showCloseCashRegisterDialog(context, provider);
            },
            icon: const Icon(Icons.lock),
            label: const Text('Cerrar Caja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper para mostrar filas de detalles
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
