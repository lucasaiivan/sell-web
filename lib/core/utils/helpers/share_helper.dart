import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../domain/entities/ticket_model.dart';
import 'pdf_helper.dart';

/// Helper para funcionalidades de compartir contenido
class ShareHelper {
  /// Captura un widget como imagen y la comparte
  ///
  /// [widget] El widget a capturar
  /// [filename] Nombre del archivo temporal
  /// [text] Texto adicional para compartir
  /// [pixelRatio] Ratio de píxeles para la captura (por defecto 2.0)
  static Future<void> shareWidgetAsImage({
    required Widget widget,
    required String filename,
    String text = 'Compartir imagen',
    double pixelRatio = 2.0,
    BuildContext? context,
  }) async {
    try {
      final screenshotController = ScreenshotController();
      
      // Capturar el widget
      final imageBytes = await screenshotController.captureFromWidget(
        Material(
          child: SizedBox(
            width: 400,
            child: widget,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: pixelRatio,
        context: context,
      );

      // Compartir la imagen
      await _shareImageBytes(
        imageBytes: imageBytes,
        filename: filename,
        text: text,
      );
    } catch (e) {
      throw Exception('Error al capturar y compartir widget: $e');
    }
  }

  /// Comparte bytes de imagen como archivo temporal
  static Future<void> _shareImageBytes({
    required Uint8List imageBytes,
    required String filename,
    required String text,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/$filename.png');
      
      // Escribir la imagen al archivo temporal
      await imagePath.writeAsBytes(imageBytes);
      
      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: text,
      );
    } catch (e) {
      throw Exception('Error al compartir imagen: $e');
    }
  }

  /// Captura un ticket como imagen y lo comparte
  ///
  /// [ticketWidget] Widget del ticket a capturar
  /// [ticketModel] Modelo del ticket (para metadatos)
  static Future<void> shareTicketAsImage({
    required Widget ticketWidget,
    required TicketModel ticketModel,
    BuildContext? context,
  }) async {
    await shareWidgetAsImage(
      widget: ticketWidget,
      filename: '${ticketModel.id}_ticket_image',
      text: 'Ticket de Venta #${ticketModel.id}',
      context: context,
    );
  }

  /// Captura un ticket como imagen y genera un PDF
  ///
  /// [ticketWidget] Widget del ticket a capturar
  /// [ticketModel] Modelo del ticket
  static Future<void> shareTicketAsPdf({
    required Widget ticketWidget,
    required TicketModel ticketModel,
    BuildContext? context,
  }) async {
    try {
      final screenshotController = ScreenshotController();
      
      // Capturar el widget
      final imageBytes = await screenshotController.captureFromWidget(
        Material(
          child: SizedBox(
            width: 400,
            child: ticketWidget,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
        context: context,
      );

      // Crear y compartir PDF
      await PdfHelper.createTicketPdf(
        ticket: ticketModel,
        imageData: imageBytes,
      );
    } catch (e) {
      throw Exception('Error al crear PDF del ticket: $e');
    }
  }

  /// Comparte texto plano
  ///
  /// [text] Texto a compartir
  /// [subject] Asunto (opcional)
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
    } catch (e) {
      throw Exception('Error al compartir texto: $e');
    }
  }

  /// Comparte múltiples archivos
  ///
  /// [filePaths] Lista de rutas de archivos
  /// [text] Texto adicional
  /// [subject] Asunto (opcional)
  static Future<void> shareFiles({
    required List<String> filePaths,
    String text = '',
    String? subject,
  }) async {
    try {
      final xFiles = filePaths.map((path) => XFile(path)).toList();
      
      await Share.shareXFiles(
        xFiles,
        text: text,
        subject: subject,
      );
    } catch (e) {
      throw Exception('Error al compartir archivos: $e');
    }
  }

  /// Comparte información del ticket como texto
  ///
  /// [ticket] Modelo del ticket
  static Future<void> shareTicketAsText({
    required TicketModel ticket,
  }) async {
    final textContent = _buildTicketText(ticket);
    
    await shareText(
      text: textContent,
      subject: 'Ticket de Venta #${ticket.id}',
    );
  }

  /// Construye el contenido de texto para un ticket
  static String _buildTicketText(TicketModel ticket) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== TICKET DE VENTA ===');
    buffer.writeln('Ticket #: ${ticket.id}');
    buffer.writeln('Fecha: ${_formatDate(ticket.creation.toDate())}');
    
    if (ticket.cashRegisterName.isNotEmpty) {
      buffer.writeln('Caja: ${ticket.cashRegisterName}');
    }
    
    if (ticket.sellerName.isNotEmpty) {
      buffer.writeln('Vendedor: ${ticket.sellerName}');
    }
    
    buffer.writeln('');
    buffer.writeln('=== PRODUCTOS ===');
    
    for (final product in ticket.products) {
      final quantity = product.quantity;
      final price = product.salePrice;
      final total = quantity * price;
      
      buffer.writeln('${product.id}'); // Usamos el ID ya que no vi el campo 'name'
      buffer.writeln('  ${quantity}x \$${price.toStringAsFixed(2)} = \$${total.toStringAsFixed(2)}');
    }
    
    buffer.writeln('');
    buffer.writeln('=== TOTALES ===');
    
    if (ticket.discount > 0) {
      buffer.writeln('Descuento: -\$${ticket.discount.toStringAsFixed(2)}');
    }
    
    buffer.writeln('TOTAL: \$${ticket.priceTotal.toStringAsFixed(2)}');
    buffer.writeln('Método de pago: ${ticket.payMode}');
    
    if (ticket.valueReceived > 0) {
      final change = ticket.valueReceived - ticket.priceTotal;
      buffer.writeln('Recibido: \$${ticket.valueReceived.toStringAsFixed(2)}');
      if (change > 0) {
        buffer.writeln('Cambio: \$${change.toStringAsFixed(2)}');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('¡Gracias por su compra!');
    
    return buffer.toString();
  }

  /// Formatea una fecha para texto
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Comparte un widget con opciones múltiples
  ///
  /// [widget] Widget a compartir
  /// [options] Opciones de compartir ('image', 'pdf', 'text')
  /// [filename] Nombre base del archivo
  /// [context] Contexto para mostrar diálogo de opciones
  static Future<void> shareWidgetWithOptions({
    required Widget widget,
    required List<String> options,
    required String filename,
    String text = 'Compartir',
    BuildContext? context,
  }) async {
    if (context != null && options.length > 1) {
      // Mostrar diálogo de opciones
      await _showShareOptionsDialog(
        context: context,
        widget: widget,
        filename: filename,
        options: options,
        text: text,
      );
    } else if (options.isNotEmpty) {
      // Compartir directamente con la primera opción
      await _shareWithOption(
        option: options.first,
        widget: widget,
        filename: filename,
        text: text,
        context: context,
      );
    }
  }

  /// Muestra diálogo con opciones de compartir
  static Future<void> _showShareOptionsDialog({
    required BuildContext context,
    required Widget widget,
    required String filename,
    required List<String> options,
    required String text,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir como'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(_getOptionTitle(option)),
              leading: Icon(_getOptionIcon(option)),
              onTap: () async {
                Navigator.of(context).pop();
                await _shareWithOption(
                  option: option,
                  widget: widget,
                  filename: filename,
                  text: text,
                  context: context,
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Comparte según la opción seleccionada
  static Future<void> _shareWithOption({
    required String option,
    required Widget widget,
    required String filename,
    required String text,
    BuildContext? context,
  }) async {
    switch (option) {
      case 'image':
        await shareWidgetAsImage(
          widget: widget,
          filename: filename,
          text: text,
          context: context,
        );
        break;
      case 'pdf':
        final screenshotController = ScreenshotController();
        final imageBytes = await screenshotController.captureFromWidget(
          Material(child: SizedBox(width: 400, child: widget)),
          delay: const Duration(milliseconds: 100),
          pixelRatio: 2.0,
          context: context,
        );
        await PdfHelper.createAndSharePdf(
          data: imageBytes,
          filename: filename,
          title: text,
        );
        break;
      case 'text':
        await shareText(text: text);
        break;
    }
  }

  /// Obtiene el título para cada opción
  static String _getOptionTitle(String option) {
    switch (option) {
      case 'image':
        return 'Como Imagen';
      case 'pdf':
        return 'Como PDF';
      case 'text':
        return 'Como Texto';
      default:
        return option;
    }
  }

  /// Obtiene el ícono para cada opción
  static IconData _getOptionIcon(String option) {
    switch (option) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.share;
    }
  }
}
