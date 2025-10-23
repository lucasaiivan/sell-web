import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'currency_formatter.dart';

/// Formateador de texto para campos de dinero
///
/// Este formateador se encarga de formatear el texto de un campo de texto
/// para que se vea como un monto de dinero
class AppMoneyInputFormatter extends TextInputFormatter {
  final String symbol;

  AppMoneyInputFormatter({this.symbol = ''});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Eliminar cualquier cosa que no sea un número o una coma
    var newText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');

    // Elimina el 0 si existe al principio de la primera posición
    if (newText.length > 1 && newText[0] == '0') {
      newText = newText.substring(1);
    }

    // Separar la parte entera y la parte decimal
    var parts = newText.split(',');
    var integerPart = parts[0];
    var decimalPart = parts.length > 1 ? parts[1] : '';

    // Limitar a 2 decimales
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Formatear la parte entera con puntos de miles
    var buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    // Construir el texto formateado
    var formattedText = buffer.toString();
    if (newText.contains(',')) {
      formattedText += ',$decimalPart';
    }

    // Añadir el signo de dólar al principio
    formattedText = '$symbol$formattedText';

    // Mantener la posición del cursor
    var selectionIndex = formattedText.length;
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Controlador de texto para campos de dinero
///
/// Este controlador se encarga de manejar el valor de un campo de texto
/// para que se vea como un monto de dinero
class AppMoneyTextEditingController extends TextEditingController {
  AppMoneyTextEditingController({String? value}) : super(text: value);

  /// Método para obtener el valor como double
  double get doubleValue {
    String textWithoutCommas =
        text.replaceAll('.', '').replaceAll(',', '.').replaceAll('\$', '');
    return double.tryParse(textWithoutCommas) ?? 0.0;
  }

  /// Método para obtener el valor formateado como string
  String get formattedValue {
    return text;
  }

  /// Actualiza el valor del controlador
  ///
  /// [value] - Nuevo valor a establecer
  void updateValue(double value) {
    // Actualiza el nuevo valor teniendo en cuenta si tiene o no decimales
    text = CurrencyFormatter.formatPrice(value: value, moneda: '');
  }
}
