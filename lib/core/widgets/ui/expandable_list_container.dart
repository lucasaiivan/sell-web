import 'package:flutter/material.dart';
import '../buttons/buttons.dart';
import '../component/dividers.dart';

/// Widget reutilizable para mostrar listas expandibles dentro de un contenedor estilizado.
///
/// Incluye ejemplos de uso con diferentes tipos de datos.
///
/// Características del widget principal:
/// - Contenedor con bordes redondeados y estilo Material Design 3
/// - Lista de elementos con separadores opcionales
/// - Funcionalidad de expandir/colapsar con límite configurable
/// - Diseño responsivo para móvil y desktop
/// - Título personalizable
/// - Soporte para widgets personalizados en cada elemento

// =============================================================================
// WIDGET PRINCIPAL: ExpandableListContainer
// =============================================================================

/// Widget reutilizable para mostrar listas expandibles dentro de un contenedor estilizado.
class ExpandableListContainer<T> extends StatefulWidget {
  /// Lista de elementos a mostrar
  final List<T> items;

  /// Función para construir cada elemento de la lista
  final Widget Function(BuildContext context, T item, int index, bool isLast)
      itemBuilder;

  /// Título de la sección (opcional)
  final String? title;

  /// Número máximo de elementos visibles inicialmente
  final int maxVisibleItems;

  /// Si es una vista móvil
  final bool isMobile;

  /// Tema de la aplicación
  final ThemeData theme;

  /// Texto para el botón "Ver más"
  final String? expandText;

  /// Texto para el botón "Ver menos"
  final String? collapseText;

  /// Si mostrar separadores entre elementos
  final bool showDividers;

  /// Color de fondo del contenedor (opcional, usa el por defecto si es null)
  final Color? backgroundColor;

  /// Color del borde (opcional, usa el por defecto si es null)
  final Color? borderColor;

  /// Radio de los bordes del contenedor
  final double borderRadius;

  const ExpandableListContainer({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isMobile,
    required this.theme,
    this.title,
    this.maxVisibleItems = 5,
    this.expandText,
    this.collapseText,
    this.showDividers = true,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
  });

  @override
  State<ExpandableListContainer<T>> createState() => _ExpandableListContainerState<T>();
}

class _ExpandableListContainerState<T> extends State<ExpandableListContainer<T>> {
  bool showAllItems = false;

  @override
  Widget build(BuildContext context) {
    final hasMoreItems = widget.items.length > widget.maxVisibleItems;
    final itemsToShow = showAllItems
        ? widget.items
        : widget.items.take(widget.maxVisibleItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección (si se proporciona)
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: (widget.isMobile
                    ? widget.theme.textTheme.bodyMedium
                    : widget.theme.textTheme.bodyLarge)
                ?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: widget.isMobile ? 8 : 12),
        ],

        // Contenedor estilizado con la lista
        Column(
          children: [
            // Items de la lista
            ...itemsToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == itemsToShow.length - 1;
        
              return widget.itemBuilder(context, item, index, isLast);
            }),
        
            // Botón "Ver más" si hay más elementos
            if (hasMoreItems && !showAllItems) ...[
              if (widget.showDividers) const AppDivider(),
              InkWell(
                onTap: () => setState(() => showAllItems = true),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 12 : 16,
                    vertical: widget.isMobile ? 8 : 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.expandText ?? 'Ver más',
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            color: widget.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.expand_more_rounded,
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        
            // Botón "Ver menos" si se están mostrando todos
            if (showAllItems && hasMoreItems) ...[
              if (widget.showDividers) const AppDivider(),
              InkWell(
                onTap: () => setState(() => showAllItems = false),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 12 : 16,
                    vertical: widget.isMobile ? 8 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      Text(
                        'Mostrando ${widget.items.length} elementos',
                        style: widget.theme.textTheme.titleSmall
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.expand_less_rounded,
                        color: widget.theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ), 
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// EJEMPLOS DE USO
// =============================================================================

/// Ejemplos de uso del widget ExpandableListContainer
class ExpandableListExamples {
  /// Ejemplo 1: Lista de transacciones
  static Widget buildTransactionsList({
    required List<Map<String, dynamic>> transactions,
    required bool isMobile,
    required ThemeData theme,
  }) {
    return ExpandableListContainer<Map<String, dynamic>>(
      items: transactions,
      isMobile: isMobile,
      theme: theme,
      title: 'Últimas transacciones',
      maxVisibleItems: 5,
      expandText: 'Ver más transacciones',
      collapseText: 'Mostrar menos',
      itemBuilder: (context, transaction, index, isLast) {
        return _buildTransactionTile(
            context, transaction, theme, isMobile, isLast);
      },
    );
  }

  /// Ejemplo 2: Lista de productos con diferentes configuraciones visuales
  static Widget buildProductsList({
    required List<Map<String, dynamic>> products,
    required bool isMobile,
    required ThemeData theme,
  }) {
    return ExpandableListContainer<Map<String, dynamic>>(
      items: products,
      isMobile: isMobile,
      theme: theme,
      title: 'Productos populares',
      maxVisibleItems: 3,
      backgroundColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      borderRadius: 16,
      showDividers: false,
      itemBuilder: (context, product, index, isLast) {
        return _buildProductTile(context, product, theme, isMobile, isLast);
      },
    );
  }

  /// Ejemplo 3: Lista de notificaciones sin título
  static Widget buildNotificationsList({
    required List<String> notifications,
    required bool isMobile,
    required ThemeData theme,
  }) {
    return ExpandableListContainer<String>(
      items: notifications,
      isMobile: isMobile,
      theme: theme,
      // Sin título en este ejemplo
      maxVisibleItems: 4,
      expandText: 'Ver todas las notificaciones',
      itemBuilder: (context, notification, index, isLast) {
        return _buildNotificationTile(
            context, notification, theme, isMobile, isLast);
      },
    );
  }

  /// Ejemplo 4: Lista de reportes con objetos personalizados
  static Widget buildReportsList({
    required List<ReportItem> reports,
    required bool isMobile,
    required ThemeData theme,
  }) {
    return ExpandableListContainer<ReportItem>(
      items: reports,
      isMobile: isMobile,
      theme: theme,
      title: 'Reportes recientes',
      maxVisibleItems: 6,
      backgroundColor:
          theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
      borderColor: theme.colorScheme.tertiary.withValues(alpha: 0.4),
      itemBuilder: (context, report, index, isLast) {
        return _buildReportTile(context, report, theme, isMobile, isLast);
      },
    );
  }

  // Métodos helper para construir los tiles específicos

  static Widget _buildTransactionTile(
    BuildContext context,
    Map<String, dynamic> transaction,
    ThemeData theme,
    bool isMobile,
    bool isLast,
  ) {
    final amount = transaction['amount'] as double;
    final description = transaction['description'] as String;
    final date = transaction['date'] as DateTime;
    final isPositive = amount >= 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.add_circle : Icons.remove_circle,
                color: isPositive ? Colors.green : Colors.red,
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}\$${amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const AppDivider(),
      ],
    );
  }

  static Widget _buildProductTile(
    BuildContext context,
    Map<String, dynamic> product,
    ThemeData theme,
    bool isMobile,
    bool isLast,
  ) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: isMobile ? 40 : 50,
                height: isMobile ? 40 : 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Stock: ${product['stock']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${(product['price'] as double).toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildNotificationTile(
    BuildContext context,
    String notification,
    ThemeData theme,
    bool isMobile,
    bool isLast,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: theme.colorScheme.primary,
                size: isMobile ? 16 : 20,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  notification,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const AppDivider(),
      ],
    );
  }

  static Widget _buildReportTile(
    BuildContext context,
    ReportItem report,
    ThemeData theme,
    bool isMobile,
    bool isLast,
  ) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: _getReportColor(report.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getReportIcon(report.type),
                  color: _getReportColor(report.type),
                  size: isMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      report.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${report.date.day}/${report.date.month}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const AppDivider(),
      ],
    );
  }

  static Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.sales:
        return Colors.green;
      case ReportType.inventory:
        return Colors.blue;
      case ReportType.financial:
        return Colors.orange;
      case ReportType.error:
        return Colors.red;
    }
  }

  static IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.sales:
        return Icons.trending_up;
      case ReportType.inventory:
        return Icons.inventory;
      case ReportType.financial:
        return Icons.account_balance;
      case ReportType.error:
        return Icons.error;
    }
  }
}

// Modelos de ejemplo para demostrar el uso con objetos personalizados

enum ReportType { sales, inventory, financial, error }

class ReportItem {
  final String title;
  final String description;
  final DateTime date;
  final ReportType type;

  ReportItem({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}
