import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; 
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/cash_register_model.dart';
import '../../domain/entities/ticket_model.dart';

class Publications {


  static String generateUid() => DateFormat('ddMMyyyyHHmmss').format(Timestamp.now().toDate()).toString();
  // obtiene un double y devuelve un monto formateado
  static String getFormatoPrecio({String moneda = "\$", required double value, bool simplified = false }) {
    // var
    int decimalDigits = (value % 1) == 0 ? 0 : 2; // cantidad de decimales
    // formater : formato de moneda
    var formatter = NumberFormat.currency(
      locale: 'es_AR',
      name: moneda,
      customPattern: value >= 0 ? '\u00a4###,###,##0.0' : '-\u00a4###,###,##0.0',
      decimalDigits: decimalDigits,
    );
    if(simplified){
      /// Formatea un número entero a una cadena de texto con abreviaturas 'K' y 'M'.
      ///
      /// Si el número es menor que 10,000, se devuelve como está.
      /// Si el número es 10,000 o más, pero menos que 1,000,000, se divide por 1,000 y se agrega 'K' al final.
      /// Si el número es 1,000,000 o más, se divide por 1,000,000 y se agrega 'M' al final.
      ///
      /// [value] es el número entero que se va a formatear.
      /// 
      if (value < 10000) {
        // Si el número es menor que 10000, simplemente devuélvelo como una cadena.
        return formatter.format(value);
      } else if (value < 1000000) {
        // Si el número es 10000 o más, pero menos que 1000000, divídelo por 1000 y agrega 'K' al final.
        return '${formatter.format(value / 1000)}K';
      } else {
        // Si el número es 1000000 o más, divídelo por 1000000 y agrega 'M' al final.
        return '${formatter.format(value / 1000000)}M';
      }
    }

    return formatter.format(value.abs());
  }

  
  static String getFormatAmount({required int value}){
    final formatCurrency = NumberFormat('#,##0', 'es_ES');
    /// Formatea un número entero a una cadena de texto con abreviaturas 'K' y 'M'.
    ///
    /// Si el número es menor que 10,000, se devuelve como está.
    /// Si el número es 10,000 o más, pero menos que 1,000,000, se divide por 1,000 y se agrega 'K' al final.
    /// Si el número es 1,000,000 o más, se divide por 1,000,000 y se agrega 'M' al final.
    ///
    /// [value] es el número entero que se va a formatear.
    /// 
    if (value < 10000) {
      // Si el número es menor que 10000, simplemente devuélvelo como una cadena.
      return formatCurrency.format(value);
    } else if (value < 1000000) {
      // Si el número es 10000 o más, pero menos que 1000000, divídelo por 1000 y agrega 'K' al final.
      return '${formatCurrency.format(value / 1000)}K';
    } else {
      // Si el número es 1000000 o más, divídelo por 1000000 y agrega 'M' al final.
      return '${formatCurrency.format(value / 1000000)}M';
    }
  }

  // Recibe la fecha y la decha actual para devolver hace cuanto tiempo se publico
  static String getFechaPublicacionFormating({required DateTime dateTime}) => DateFormat('dd/MM/yyyy HH:mm','es').format(dateTime).toString();
  static String getFechaPublicacionSimple(DateTime postDate, DateTime currentDate) {
  /** 
    Obtiene la fecha de publicación en formato legible para el usuario.
    @param postDate La fecha de publicación del contenido.
    @param currentDate La fecha actual del sistema.
    @return La fecha en formato legible para el usuario.
  */
  if (postDate.year != currentDate.year) {
    // Si la publicación es de un año diferente, muestra la fecha completa
    return DateFormat('dd MMM. yyyy','es').format(postDate);
  } else if (postDate.month != currentDate.month || postDate.day != currentDate.day) {
    // Si la publicación no es del mismo día de hoy
    if (postDate.year == currentDate.year &&
        postDate.month == currentDate.month &&
        postDate.day == currentDate.day - 1) {
      // Si la publicación es del día anterior, muestra "Ayer"
      return 'Ayer';
    } else {
      // Si la publicación no es del día anterior, muestra la fecha sin el año
      return DateFormat('dd MMM.','es').format(postDate);
    }
  } else {
    // Si la publicación es del mismo día de hoy, muestra "Hoy"
    return 'Hoy';
  }
} 
  static String getFechaPublicacion({required DateTime fechaPublicacion, required DateTime fechaActual}) {
  /** 
    Obtiene la fecha de publicación en formato legible para el usuario.
    @param fechaPublicacion La fecha de publicación del contenido.
    @param fechaActual La fecha actual del sistema.
    @return La fecha en formato legible para el usuario.
  */ 
 

  // condition : si el año de la publicacion es diferente al año actual
  if (fechaPublicacion.year != fechaActual.year) {
    // Si la publicación es de un año diferente, muestra la fecha completa
    return DateFormat('dd MMM. yyyy','es').format(fechaPublicacion);
  } else if (fechaPublicacion.month != fechaActual.month || fechaPublicacion.day != fechaActual.day) {
    // Si la publicación no es del mismo día de hoy
    if (fechaPublicacion.year == fechaActual.year &&
        fechaPublicacion.month == fechaActual.month &&
        fechaPublicacion.day == fechaActual.day - 1) {
      // Si la publicación es del día anterior, muestra "Ayer"
      return 'Ayer ${DateFormat('HH:mm','es').format(fechaPublicacion)}';
    }else {
      // Si la publicación no es del día anterior, muestra la fecha sin el año
      return DateFormat('dd MMM.','es').format(fechaPublicacion);
    }
  } else {
    // Si la publicación es del mismo día de hoy
    Duration difference = fechaActual.difference(fechaPublicacion);
    if (difference.inMinutes < 30) {
      // Si la publicación fue hace menos de 30 minutos, muestra "Hace instantes"
      return 'Hace instantes';
    } else if (difference.inMinutes < 60) {
      // Si la publicación fue hace menos de una hora, muestra los minutos
      return 'Hace ${difference.inMinutes} min.';
    } else if (difference.inHours < 8) {
      // Si la publicación fue hace menos de 8 horas, muestra las horas
      return 'Hace ${difference.inHours} horas';
    } else {
      // Si la publicación fue hace 8 horas o más, muestra "Hoy"
      return 'Hoy';
    }
  }
}

 
}
class Utils {
  // Devuelve un color Random
  static MaterialColor getRandomColor() {
    List<MaterialColor> listaColor = [
      Colors.amber,
      Colors.blue,
      Colors.blueGrey,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.green,
      Colors.grey,
      Colors.indigo,
      Colors.red,
      Colors.lime,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.teal,
      Colors.yellow,
      Colors.deepPurple,
    ];

    return listaColor[Random().nextInt(listaColor.length)];
  }

  String capitalizeString(String input) {
    // description : capitaliza la primera letra de cada palabra
  if (input.isEmpty) {
    return input;
  }
  final words = input.split(' ');
  final capitalizedWords = words.map((word) {
    if (word.length > 1) {
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    } else {
      return word.toUpperCase();
    }
  });
  return capitalizedWords.join(' ');
}
  // normalizar texto : quitar espacios, acentos y convertir a minusculas 
  static String normalizeText(String text) {
    // description : normaliza el texto
    return text
        .replaceAll(' ', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .toLowerCase();
  }

  void getDetailArqueoScreenShot({required BuildContext context,required CashRegister cashRegister}) async {
    // widget : ticket
    //var myLongWidget = Builder(builder: (context) { return CashRegisterDetailView(cashRegister:cashRegister).body; });
    var myLongWidget = Builder(builder: (context) { return Center(child: Text('CashRegisterDetailView')); });
    // controller
    final ScreenshotController screenshotController = ScreenshotController(); 
    // captura de pantalla
    screenshotController.captureFromLongWidget(
          Material(child: SizedBox(width: 400,child: myLongWidget)),
          delay: const Duration(milliseconds: 100),
          pixelRatio: 2, 
          context:context,  
      ).then((capturedImage) async {
        // crear un pdf y compartirlo
        createPdfAndShare(data: capturedImage, id: cashRegister.id); 
      
  }); 
  } 
  void getTicketScreenShot({required TicketModel ticketModel,required BuildContext context }) async {

    // widget : ticket
    //var myLongWidget = Builder(builder: (context) {return TicketView(ticket: ticketModel).body(context: context);});
    var myLongWidget = Builder(builder: (context) {return Center(child: Text('TicketView'));});
    // controller
    final ScreenshotController screenshotController = ScreenshotController(); 
    
    screenshotController.captureFromLongWidget(
          Material(child: SizedBox(width: 400,child: myLongWidget)),
          delay: const Duration(milliseconds: 100),
          pixelRatio: 2, 
          context:context,  
      ).then((capturedImage) async {
        // crear un pdf y compartirlo
        createPdfAndShare(data: capturedImage, id: ticketModel.id);
        /* 
        final directory =  await getTemporaryDirectory(); // directorio temporal
        final imagePath = await File('${directory.path}/ticketTemporaryPrint.png').create(); // archivo variable
        await imagePath.writeAsBytes(capturedImage); // escribimos la captura de pantalla en el archivo

        /// Share Plugin : compartir la captura de pantalla
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Compartir Ticket'); 
       */
  }); 
  }    

  Future<void> createPdfAndShare({required Uint8List data, required String id}) async {
    // description : crea un pdf y lo comparte (soporta web y otras plataformas)
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(child: pw.Image(pw.MemoryImage(data))),
        pageFormat: PdfPageFormat.a4,
      ),
    );

    if (kIsWeb) {
      // Para web: descarga el PDF usando un enlace oculto
      final bytes = await pdf.save();
      final url = 'data:application/pdf;base64,${base64Encode(bytes)}';
      // ignore: undefined_prefixed_name
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = '${id}Ticket.pdf';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
    } else {
      // Para móvil/escritorio: guarda y comparte el PDF como antes
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/${id}Ticket.pdf");
      await file.writeAsBytes(await pdf.save());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Compartir Ticket'); 
    }
  }
}

// AppMoneyInputFormatter : Formateador de texto para campos de dinero
// Este formateador se encarga de formatear el texto de un campo de texto para que se vea como un monto de dinero
class AppMoneyInputFormatter extends TextInputFormatter {

  final String symbol; 
  AppMoneyInputFormatter({this.symbol = ''});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,TextEditingValue newValue) { 
    
    // Eliminar cualquier cosa que no sea un número o una coma
    var newText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    // elimina el 0 si es que esta al principioque existe de la primera posición
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
//  AppMoneyTextEditingController : Controlador de texto para campos de dinero
// Este controlador se encarga de manejar el valor de un campo de texto para que se vea como un monto de dinero
class AppMoneyTextEditingController extends TextEditingController {
  AppMoneyTextEditingController({String? value}) : super(text: value);

  // Método para obtener el valor como double
  double get doubleValue {
    String textWithoutCommas = text.replaceAll('.', '').replaceAll(',', '.').replaceAll('\$','');
    return double.tryParse(textWithoutCommas) ?? 0.0;
  }

  // Método para obtener el valor formateado como string
  String get formattedValue {
    return text;
  }
  // actualizar el valor del controlador
  void updateValue(double value) {
    // actualiza el nuevo valor teniendo en cuenta si tiene o no decimales
    text = Publications.getFormatoPrecio(value: value);
  }
}