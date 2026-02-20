import 'package:flutter/services.dart';
import 'package:sellweb/core/utils/helpers/unit_helper.dart';

/// Formateador de texto para campos de cantidad (stock, ventas, etc.)
/// 
/// Soporta:
/// - Separadores de miles (puntos)
/// - Separador decimal (coma)
/// - Hasta 3 decimales para unidades fraccionarias
/// - Solo enteros para unidades discretas
/// - Símbolo de unidad opcional al final
class AppQuantityInputFormatter extends TextInputFormatter {
  final String unit;
  final bool showSymbol;

  AppQuantityInputFormatter({
    required this.unit,
    this.showSymbol = false,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final isFractional = UnitHelper.isFractionalUnit(unit);
    final symbol = UnitHelper.getUnitSymbol(unit);

    // Limpiar el texto de entrada (quitar todo excepto números y coma/punto)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9,\.]'), '');
    
    // Normalizar punto a coma para el procesamiento
    cleanText = cleanText.replaceAll('.', ',');

    // Si no es fraccional, quitar comas
    if (!isFractional) {
      cleanText = cleanText.replaceAll(',', '');
    }

    // Manejar múltiples comas (solo dejar la primera)
    if (cleanText.contains(',')) {
      final parts = cleanText.split(',');
      cleanText = '${parts[0]},${parts.sublist(1).join('')}';
    }

    // Separar parte entera y decimal
    final parts = cleanText.split(',');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Limitar decimales a 3
    if (decimalPart.length > 3) {
      decimalPart = decimalPart.substring(0, 3);
    }

    // Quitar ceros a la izquierda de la parte entera (a menos que sea solo "0")
    if (integerPart.length > 1 && integerPart.startsWith('0')) {
      integerPart = integerPart.replaceFirst(RegExp(r'^0+'), '');
      if (integerPart.isEmpty) integerPart = '0';
    } else if (integerPart.isEmpty && decimalPart.isNotEmpty) {
      integerPart = '0';
    }

    // Formatear parte entera con puntos de miles
    final buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    String formattedText = buffer.toString();
    
    // Añadir parte decimal si existe
    if (cleanText.contains(',')) {
      formattedText += ',$decimalPart';
    }

    // Añadir símbolo si se solicita
    if (showSymbol && symbol.isNotEmpty) {
      formattedText += ' $symbol';
    }

    // Calcular nueva posición del cursor
    // Por simplicidad, lo ponemos al final del número (antes del símbolo si existe)
    int selectionIndex = formattedText.length;
    if (showSymbol && symbol.isNotEmpty && formattedText.endsWith(' $symbol')) {
      selectionIndex = formattedText.length - (symbol.length + 1);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
