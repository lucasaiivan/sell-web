import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';

/// Widget: Tarjeta de Cajas Registradoras Activas
///
/// **Responsabilidad:**
/// - Mostrar lista de cajas registradoras activas
/// - Mostrar nombre, balance y total de transacciones de cada caja
/// - Diseño minimalista consistente con otras tarjetas de analytics
class ActiveCashRegistersCard extends StatelessWidget {
  final List<CashRegister> activeCashRegisters;

  const ActiveCashRegistersCard({
    super.key,
    required this.activeCashRegisters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color principal de la tarjeta
    final color = theme.colorScheme.tertiary;
    final containerColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.08);
    final iconContainerColor = color.withValues(alpha: 0.2);

    return Card(
      elevation: 0,
      color: containerColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconContainerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cajas Activas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${activeCashRegisters.length} ${activeCashRegisters.length == 1 ? 'caja abierta' : 'cajas abiertas'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Lista de cajas
              Column(
                children: activeCashRegisters.map((cashRegister) {
                  final isLast = activeCashRegisters.indexOf(cashRegister) == 
                                 activeCashRegisters.length - 1;
                  
                  return Column(
                    children: [
                      _buildCashRegisterItem(context, cashRegister),
                      if (!isLast) ...[
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: color.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashRegisterItem(BuildContext context, CashRegister cashRegister) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Indicador visual de caja activa
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        
        // Información de la caja
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cashRegister.description.isNotEmpty 
                    ? cashRegister.description 
                    : 'Caja sin nombre',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      cashRegister.nameUser.isNotEmpty 
                          ? cashRegister.nameUser 
                          : 'Sin operador',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Métricas (Balance y Transacciones)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.formatCurrency(cashRegister.getExpectedBalance),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${cashRegister.getEffectiveSales} ${cashRegister.getEffectiveSales == 1 ? 'venta' : 'ventas'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
