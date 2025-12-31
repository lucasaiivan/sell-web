import 'package:flutter/material.dart';

/// Widget: Selector de moneda para cuentas comercio
///
/// **Opciones disponibles:**
/// - AR$ (Peso Argentino)
/// - US$ (Dólar Estadounidense)
///
/// **Ejemplo de uso:**
/// ```dart
/// CurrencySelector(
///   selectedCurrency: 'AR$',
///   onChanged: (currency) {
///     setState(() => _selectedCurrency = currency);
///   },
/// )
/// ```
class CurrencySelector extends StatelessWidget {
  final String selectedCurrency;
  final void Function(String?)? onChanged;
  final bool enabled;
  final String? label;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    this.onChanged,
    this.enabled = true,
    this.label,
  });

  static const List<Map<String, String>> currencies = [
    {'code': 'AR\$', 'name': 'Peso Argentino'},
    {'code': 'US\$', 'name': 'Dólar Estadounidense'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      initialValue: selectedCurrency.isNotEmpty ? selectedCurrency : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label ?? 'Moneda',
        prefixIcon: selectedCurrency.isEmpty 
            ? Icon(
                Icons.attach_money_rounded,
                color: theme.colorScheme.primary,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: enabled ? null : theme.colorScheme.surfaceContainerHighest,
      ),
      items: currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency['code'],
          child: Row(
            children: [
              Text(
                currency['code']!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currency['name']!,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona una moneda';
        }
        return null;
      },
    );
  }
}
