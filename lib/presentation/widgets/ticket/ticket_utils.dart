import 'package:flutter/material.dart';

/// Clase de utilidades para el manejo de tickets
class TicketUtils {
  /// Obtiene el texto a mostrar para el método de pago
  static String getPaymentMethodDisplayText(String payMode) {
    switch (payMode) {
      case 'effective':
        return 'Efectivo';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'card':
        return 'Tarjeta';
      default:
        return 'Sin especificar';
    }
  }

  /// Obtiene el icono correspondiente al método de pago
  static IconData getPaymentMethodIcon(String payMode) {
    switch (payMode) {
      case 'effective':
        return Icons.payments_rounded;
      case 'mercadopago':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Obtiene la fecha y hora formateada para mostrar en la confirmación
  static String getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
