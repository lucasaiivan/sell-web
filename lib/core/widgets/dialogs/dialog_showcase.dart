import 'package:flutter/material.dart';
import 'dialogs.dart';

/// Widget de demostración que muestra todos los componentes de diálogo
/// implementados según Material Design 3
/// 
/// Útil para testing, desarrollo y como referencia visual
class DialogShowcase extends StatelessWidget {
  const DialogShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialog Showcase - Material Design 3'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Diálogos Estándar',
                'Componentes predefinidos para casos comunes',
                [
                  _buildDialogButton(
                    context,
                    'Confirmación',
                    Icons.help_outline_rounded,
                    () => showConfirmationDialog(
                      context: context,
                      title: 'Confirmar Acción',
                      message: '¿Estás seguro de que deseas continuar con esta acción?',
                      confirmText: 'Sí, continuar',
                      cancelText: 'Cancelar',
                    ),
                  ),
                  _buildDialogButton(
                    context,
                    'Confirmación Destructiva',
                    Icons.warning_amber_rounded,
                    () => showConfirmationDialog(
                      context: context,
                      title: 'Eliminar Elemento',
                      message: 'Esta acción no se puede deshacer. ¿Continuar?',
                      isDestructive: true,
                      confirmText: 'Eliminar',
                      cancelText: 'Cancelar',
                    ),
                  ),
                  _buildDialogButton(
                    context,
                    'Información',
                    Icons.info_outline_rounded,
                    () => showInfoDialog(
                      context: context,
                      title: 'Operación Exitosa',
                      message: 'Los cambios se han guardado correctamente en el sistema.',
                      buttonText: 'Entendido',
                    ),
                  ),
                  _buildDialogButton(
                    context,
                    'Error',
                    Icons.error_outline_rounded,
                    () => showErrorDialog(
                      context: context,
                      title: 'Error de Conexión',
                      message: 'No se pudo conectar con el servidor. Verifica tu conexión a internet.',
                      details: 'HTTP 500 - Internal Server Error\nEndpoint: /api/products\nTimestamp: ${DateTime.now()}',
                    ),
                  ),
                  _buildDialogButton(
                    context,
                    'Carga con Progreso',
                    Icons.hourglass_empty_rounded,
                    () => _showLoadingExample(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              _buildSection(
                context,
                'Diálogos Complejos',
                'Ejemplos usando BaseDialog y DialogComponents',
                [
                  _buildDialogButton(
                    context,
                    'Ejemplo Moderno',
                    Icons.star_rounded,
                    () => showExampleModernDialog(
                      context: context,
                      productName: 'Producto Demo',
                      currentPrice: 25.99,
                    ),
                  ),
                  _buildDialogButton(
                    context,
                    'Detalles de Venta',
                    Icons.point_of_sale_rounded,
                    () => _showSaleDetailsDialog(context),
                  ),
                  _buildDialogButton(
                    context,
                    'Configuración',
                    Icons.settings_rounded,
                    () => _showConfigDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              _buildSection(
                context,
                'Componentes Individuales',
                'Elementos UI que se pueden combinar',
                [
                  _buildDialogButton(
                    context,
                    'Showcase de Componentes',
                    Icons.widgets_rounded,
                    () => _showComponentsDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<Widget> buttons,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: buttons,
        ),
      ],
    );
  }

  Widget _buildDialogButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _showLoadingExample(BuildContext context) async {
    showLoadingDialog(
      context: context,
      message: 'Procesando información...',
      progress: null,
    );

    // Simular progreso
    await Future.delayed(const Duration(seconds: 3));
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar loading
      showInfoDialog(
        context: context,
        title: 'Completado',
        message: 'El proceso ha finalizado exitosamente.',
      );
    }
  }

  Future<void> _showSaleDetailsDialog(BuildContext context) {
    return showBaseDialog(
      context: context,
      title: 'Detalles de Venta',
      icon: Icons.receipt_long_rounded,
      width: 450,
      content: Column(
        children: [
          DialogComponents.infoSection(
            context: context,
            title: 'Información del Cliente',
            icon: Icons.person_outline,
            content: Column(
              children: [
                DialogComponents.infoRow(
                  context: context,
                  label: 'Nombre',
                  value: 'Juan Pérez González',
                ),
                DialogComponents.minSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'Teléfono',
                  value: '+52 555 123 4567',
                ),
                DialogComponents.minSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'Email',
                  value: 'juan.perez@email.com',
                ),
              ],
            ),
          ),
          
          DialogComponents.sectionSpacing,
          
          DialogComponents.itemList(
            context: context,
            items: [
              DialogComponents.infoRow(
                context: context,
                label: 'Producto Premium',
                value: '\$45.00',
                icon: Icons.star_outline,
              ),
              DialogComponents.infoRow(
                context: context,
                label: 'Producto Estándar x2',
                value: '\$30.00',
                icon: Icons.inventory_2_outlined,
              ),
              DialogComponents.infoRow(
                context: context,
                label: 'Descuento aplicado',
                value: '-\$5.00',
                icon: Icons.discount_outlined,
              ),
            ],
          ),
          
          DialogComponents.sectionSpacing,
          
          Row(
            children: [
              Expanded(
                child: DialogComponents.infoBadge(
                  context: context,
                  text: 'Efectivo',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DialogComponents.infoBadge(
                  context: context,
                  text: 'Completada',
                  icon: Icons.check_circle_outline,
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  textColor: Colors.green[700],
                ),
              ),
            ],
          ),
          
          DialogComponents.sectionSpacing,
          
          DialogComponents.summaryContainer(
            context: context,
            label: 'Total Final',
            value: '\$70.00',
            icon: Icons.monetization_on_outlined,
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Imprimir Ticket',
          icon: Icons.print_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            showInfoDialog(
              context: context,
              title: 'Imprimiendo',
              message: 'El ticket se está enviando a la impresora...',
            );
          },
        ),
      ],
    );
  }

  Future<void> _showConfigDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'Mi Negocio');
    final addressController = TextEditingController(text: 'Calle Principal 123');
    
    return showBaseDialog(
      context: context,
      title: 'Configuración del Negocio',
      icon: Icons.business_rounded,
      width: 500,
      content: Column(
        children: [
          DialogComponents.textField(
            context: context,
            controller: nameController,
            label: 'Nombre del Negocio',
            prefixIcon: Icons.business_outlined,
          ),
          
          DialogComponents.itemSpacing,
          
          DialogComponents.textField(
            context: context,
            controller: addressController,
            label: 'Dirección',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          
          DialogComponents.sectionSpacing,
          
          DialogComponents.infoSection(
            context: context,
            title: 'Configuración de Impresión',
            icon: Icons.print_outlined,
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DialogComponents.infoBadge(
                        context: context,
                        text: 'USB Conectada',
                        icon: Icons.usb_rounded,
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        textColor: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DialogComponents.infoBadge(
                        context: context,
                        text: 'Papel: 80mm',
                        icon: Icons.description_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Guardar Cambios',
          icon: Icons.save_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            showInfoDialog(
              context: context,
              title: 'Configuración Guardada',
              message: 'Los cambios se han aplicado correctamente.',
            );
          },
        ),
      ],
    );
  }

  Future<void> _showComponentsDialog(BuildContext context) {
    return showBaseDialog(
      context: context,
      title: 'Showcase de Componentes',
      icon: Icons.palette_rounded,
      width: 550,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Secciones de Información',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          DialogComponents.itemSpacing,
          
          DialogComponents.infoSection(
            context: context,
            title: 'Sección Ejemplo',
            icon: Icons.info_outline,
            content: const Text(
              'Esta es una sección de información estilizada con Material Design 3.',
            ),
          ),
          
          DialogComponents.sectionSpacing,
          
          Text(
            'Listas de Elementos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          DialogComponents.itemSpacing,
          
          DialogComponents.itemList(
            context: context,
            items: [
              DialogComponents.infoRow(
                context: context,
                label: 'Elemento 1',
                value: 'Valor 1',
                icon: Icons.circle_outlined,
              ),
              DialogComponents.infoRow(
                context: context,
                label: 'Elemento 2',
                value: 'Valor 2',
                icon: Icons.square_outlined,
              ),
            ],
          ),
          
          DialogComponents.sectionSpacing,
          
          Text(
            'Badges y Contenedores',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          DialogComponents.itemSpacing,
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DialogComponents.infoBadge(
                context: context,
                text: 'Activo',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                textColor: Colors.green[700],
              ),
              DialogComponents.infoBadge(
                context: context,
                text: 'Pendiente',
                icon: Icons.schedule_outlined,
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                textColor: Colors.orange[700],
              ),
              DialogComponents.infoBadge(
                context: context,
                text: 'Error',
                icon: Icons.error_outline,
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                textColor: Colors.red[700],
              ),
            ],
          ),
          
          DialogComponents.sectionSpacing,
          
          DialogComponents.summaryContainer(
            context: context,
            label: 'Contenedor de Resumen',
            value: 'Valor Destacado',
            icon: Icons.star_rounded,
          ),
        ],
      ),
      actions: [
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Cerrar',
          icon: Icons.close_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
