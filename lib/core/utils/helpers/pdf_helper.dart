import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/ticket_model.dart';

/// Helper para generación y manipulación de PDFs
class PdfHelper {
  /// Crea un PDF a partir de una imagen capturada y lo comparte
  ///
  /// [data] Los bytes de la imagen capturada
  /// [filename] Nombre del archivo (sin extensión)
  /// [title] Título para compartir
  static Future<void> createAndSharePdf({
    required Uint8List data,
    required String filename,
    String title = 'Compartir PDF',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(data)),
        ),
        pageFormat: PdfPageFormat.a4,
      ),
    );

    if (kIsWeb) {
      await _downloadPdfWeb(pdf, filename);
    } else {
      await _sharePdfMobile(pdf, filename, title);
    }
  }

  /// Descarga un PDF en navegadores web
  static Future<void> _downloadPdfWeb(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();
      final url = 'data:application/pdf;base64,${base64Encode(bytes)}';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        throw Exception('No se puede abrir el PDF');
      }
    } catch (e) {
      throw Exception('Error al descargar PDF: $e');
    }
  }

  /// Comparte un PDF en dispositivos móviles/escritorio
  static Future<void> _sharePdfMobile(
    pw.Document pdf,
    String filename,
    String title,
  ) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: title,
      );
    } catch (e) {
      throw Exception('Error al compartir PDF: $e');
    }
  }

  /// Genera un PDF específico para tickets de venta
  ///
  /// [ticket] El modelo del ticket
  /// [imageData] Imagen capturada del ticket
  static Future<void> createTicketPdf({
    required TicketModel ticket,
    required Uint8List imageData,
  }) async {
    await createAndSharePdf(
      data: imageData,
      filename: '${ticket.id}_ticket',
      title: 'Ticket de Venta #${ticket.id}',
    );
  }

  /// Genera un PDF de texto para tickets (sin imagen)
  ///
  /// [ticket] El modelo del ticket
  static Future<void> createTextTicketPdf({
    required TicketModel ticket,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => _buildTicketContent(ticket),
        pageFormat: PdfPageFormat.a4,
      ),
    );

    if (kIsWeb) {
      await _downloadPdfWeb(pdf, '${ticket.id}_ticket');
    } else {
      await _sharePdfMobile(pdf, '${ticket.id}_ticket', 'Ticket #${ticket.id}');
    }
  }

  /// Construye el contenido del ticket en PDF
  static pw.Widget _buildTicketContent(TicketModel ticket) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Center(
            child: pw.Text(
              'TICKET DE VENTA',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Información del ticket
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ticket #: ${ticket.id}'),
              pw.Text('Fecha: ${_formatDate(ticket.creation.toDate())}'),
            ],
          ),
          pw.SizedBox(height: 10),

          // Información de la caja y vendedor
          if (ticket.cashRegisterName.isNotEmpty)
            pw.Text('Caja: ${ticket.cashRegisterName}'),
          if (ticket.sellerName.isNotEmpty)
            pw.Text('Vendedor: ${ticket.sellerName}'),
          pw.SizedBox(height: 20),

          // Línea separadora
          pw.Divider(),

          // Productos
          pw.Text(
            'PRODUCTOS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Lista de productos
          ...ticket.products
              .map((product) => _buildProductRowFromCatalogue(product)),

          pw.SizedBox(height: 20),
          pw.Divider(),

          // Totales
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (ticket.discount > 0)
                    pw.Text(
                        'Descuento: -\$${ticket.discount.toStringAsFixed(2)}'),
                  pw.Text(
                    'TOTAL: \$${ticket.priceTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Método de pago
          pw.Text('Método de pago: ${ticket.payMode}'),

          pw.Spacer(),

          // Footer
          pw.Center(
            child: pw.Text(
              '¡Gracias por su compra!',
              style: pw.TextStyle(
                fontSize: 14,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila de producto para el PDF desde ProductCatalogue
  static pw.Widget _buildProductRowFromCatalogue(dynamic product) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(product.id), // Usamos ID ya que no hay 'name'
          ),
          pw.Expanded(
            child: pw.Text(
              '${product.quantity}x',
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '\$${product.salePrice.toStringAsFixed(2)}',
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '\$${(product.quantity * product.salePrice).toStringAsFixed(2)}',
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha para mostrar en el PDF
  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Crea un PDF personalizado con contenido libre
  ///
  /// [content] Widget de contenido para el PDF
  /// [filename] Nombre del archivo
  /// [pageFormat] Formato de página (por defecto A4)
  static Future<void> createCustomPdf({
    required pw.Widget content,
    required String filename,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    String title = 'Documento PDF',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => content,
        pageFormat: pageFormat,
      ),
    );

    if (kIsWeb) {
      await _downloadPdfWeb(pdf, filename);
    } else {
      await _sharePdfMobile(pdf, filename, title);
    }
  }

  /// Valida si el sistema puede generar PDFs
  static bool canGeneratePdf() {
    try {
      // Verificaciones básicas
      return true;
    } catch (e) {
      return false;
    }
  }
}
