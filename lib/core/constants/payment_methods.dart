import 'package:flutter/material.dart';

/// Enum centralizado para métodos de pago
/// Define los códigos internos, nombres legibles, colores e iconos
enum PaymentMethod {
  cash('cash', 'Efectivo', Color(0xFF4CAF50), Icons.payments_rounded),
  transfer('transfer', 'Transferencia', Color(0xFF2196F3), Icons.account_balance_rounded),
  card('card', 'Tarjeta Déb/Créd', Color(0xFFFF9800), Icons.credit_card_rounded),
  qr('qr', 'QR', Color(0xFF9C27B0), Icons.qr_code_2_rounded),
  unspecified('', 'Sin Especificar', Color(0xFF9E9E9E), Icons.help_outline_rounded);

  final String code;
  final String displayName;
  final Color color;
  final IconData icon;

  const PaymentMethod(this.code, this.displayName, this.color, this.icon);

  /// Obtener PaymentMethod desde código string con soporte para códigos legacy
  /// Normaliza automáticamente códigos antiguos a nuevos
  static PaymentMethod fromCode(String code) {
    // Normalizar código legacy primero
    final normalizedCode = _normalizeLegacyCode(code);
    
    return PaymentMethod.values.firstWhere(
      (method) => method.code == normalizedCode,
      orElse: () => PaymentMethod.unspecified,
    );
  }

  /// Obtener solo los métodos de pago válidos (sin unspecified)
  static List<PaymentMethod> getValidMethods() {
    return [
      PaymentMethod.cash,
      PaymentMethod.transfer,
      PaymentMethod.card,
      PaymentMethod.qr,
    ];
  }

  /// Obtener lista de códigos válidos para validación
  static List<String> getValidCodes() {
    return getValidMethods().map((method) => method.code).toList()..add('');
  }

  /// Verificar si un código es válido (incluye códigos legacy)
  static bool isValidCode(String code) {
    final normalized = _normalizeLegacyCode(code);
    return getValidCodes().contains(normalized);
  }

  /// Normaliza códigos legacy a códigos nuevos
  /// Este método permite compatibilidad con tickets antiguos sin migración
  /// 
  /// Mapeo:
  /// - 'effective'/'efective'/'efectivo' → 'cash'
  /// - 'mercadopago'/'mercado pago'/'transferencia'/'transferencias' → 'transfer'
  /// - 'card'/'tarjeta' → 'card'
  /// - Cualquier otro código se mantiene igual
  static String _normalizeLegacyCode(String oldCode) {
    if (oldCode.isEmpty) return '';
    
    final normalized = oldCode.toLowerCase().trim();
    
    switch (normalized) {
      case 'effective':
      case 'efective':
      case 'efectivo':
        return PaymentMethod.cash.code;
      
      case 'mercadopago':
      case 'mercado pago':
      case 'transferencia':
      case 'transferencias':
        return PaymentMethod.transfer.code;
      
      case 'card':
      case 'tarjeta':
        return PaymentMethod.card.code;
      
      case 'cash':
      case 'transfer':
      case 'qr':
        return normalized;
      
      default:
        return oldCode;
    }
  }

  /// Migración explícita de código legacy a nuevo (para uso en guardar/actualizar)
  /// Útil cuando se quiere actualizar un ticket con código legacy a código nuevo
  static String migrateLegacyCode(String oldCode) {
    return _normalizeLegacyCode(oldCode);
  }
}
