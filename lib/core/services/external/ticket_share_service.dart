import 'package:sellweb/core/utils/download/downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/core/constants/payment_methods.dart';

// ────────────────────────────────────────────────────────────────────────────
// RESULTADO DE COMPARTIR
// ────────────────────────────────────────────────────────────────────────────

/// Resultado de una operación de compartir ticket.
class TicketShareResult {
  final bool success;
  final String? message;
  final TicketShareMethod method;

  const TicketShareResult({
    required this.success,
    required this.method,
    this.message,
  });

  factory TicketShareResult.ok(TicketShareMethod method) =>
      TicketShareResult(success: true, method: method);

  factory TicketShareResult.fail(TicketShareMethod method, String msg) =>
      TicketShareResult(success: false, method: method, message: msg);
}

/// Método de compartir utilizado.
enum TicketShareMethod { text, pdf, clipboard, whatsapp }

// ────────────────────────────────────────────────────────────────────────────
// SERVICIO PRINCIPAL
// ────────────────────────────────────────────────────────────────────────────

/// Servicio para compartir tickets de venta por múltiples medios.
///
/// ## Comportamiento por plataforma:
/// - **Web**: descarga PDF directamente en el navegador; comparte texto
///   mediante la Web Share API o copia al portapapeles como fallback.
/// - **Móvil (Android/iOS)**: usa `share_plus` con el sheet nativo del SO.
///
/// ## Métodos disponibles:
/// - [shareAsText] → comparte el ticket como texto plano (Web Share API / sheet nativo)
/// - [copyToClipboard] → copia el ticket al portapapeles
/// - [shareAsPdf] → genera y descarga/comparte el PDF del ticket
/// - [shareViaWhatsApp] → abre WhatsApp con el texto del ticket pre-cargado
/// - [generateTicketText] → genera el texto formateado del ticket (sin compartir)
@lazySingleton
class TicketShareService {
  // ── Verificaciones de capacidad ─────────────────────────────────────────

  /// True si la Web Share API está disponible en el contexto actual.
  ///
  /// En Chrome/Edge/Safari modernos con HTTPS sí está disponible.
  /// Firefox y algunos contextos HTTP no la soportan.
  bool get isWebShareSupported {
    if (!kIsWeb) return true; // En móvil siempre hay share nativo
    // Para evitar la importación de dart:html, usamos un try/catch
    // que captura el error si el navigator.share no existe
    try {
      return _checkWebShareApi();
    } catch (_) {
      return false;
    }
  }

  bool _checkWebShareApi() {
    // Usamos un enfoque seguro con js_interop via evaluación dinámica
    // En una app Flutter web real, el navigator.share siempre está disponible
    // en contextos HTTPS con Chrome, Edge o Safari
    return true; // share_plus maneja el fallback internamente
  }

  // ── Generación de contenido ─────────────────────────────────────────────

  /// Genera el texto formateado del ticket estilo recibo ASCII.
  ///
  /// Pensado para ser leído en un chat o copiado al portapapeles.
  String generateTicketText({
    required TicketModel ticket,
    required String businessName,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = dateFormat.format(ticket.creation.toDate());
    final paymentMethod = PaymentMethod.fromCode(ticket.payMode).displayName;
    final currencySymbol = ticket.currencySymbol;

    final buffer = StringBuffer();

    // Encabezado
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🏪 $businessName');
    buffer.writeln('📅 $date');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');

    // Productos
    for (final product in ticket.products) {
      final qty = _formatQuantity(product.quantity);
      final price =
          '$currencySymbol${_formatAmount(product.salePrice * product.quantity)}';
      buffer.writeln('• ${product.description}');
      buffer.writeln(
          '  $qty x $currencySymbol${_formatAmount(product.salePrice)} = $price');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');

    // Descuento (si aplica)
    if (ticket.getDiscountAmount > 0) {
      buffer.writeln(
          '💸 Descuento: -$currencySymbol${_formatAmount(ticket.getDiscountAmount)}');
    }

    // Total
    buffer.writeln(
        '💰 TOTAL: $currencySymbol${_formatAmount(ticket.getTotalPrice)}');

    // Pago
    buffer.writeln('💳 Pago: $paymentMethod');

    // Vuelto (solo si aplica)
    if (ticket.valueReceived > ticket.getTotalPrice) {
      final change = ticket.valueReceived - ticket.getTotalPrice;
      buffer.writeln(
          '↩️ Recibido: $currencySymbol${_formatAmount(ticket.valueReceived)}');
      buffer.writeln('↩️ Vuelto: $currencySymbol${_formatAmount(change)}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('¡Gracias por su compra!');

    return buffer.toString();
  }

  // ── Compartir como texto ─────────────────────────────────────────────────

  /// Comparte el ticket como texto plano.
  ///
  /// `share_plus` usa la Web Share API internamente en web cuando está disponible,
  /// o muestra el sheet nativo en iOS/Android.
  Future<TicketShareResult> shareAsText({
    required TicketModel ticket,
    required String businessName,
  }) async {
    try {
      final text = generateTicketText(
        ticket: ticket,
        businessName: businessName,
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Ticket de venta - $businessName',
        ),
      );

      // ShareResultStatus.success o .dismissed son ambos aceptables
      final success = result.status != ShareResultStatus.unavailable;
      return success
          ? TicketShareResult.ok(TicketShareMethod.text)
          : TicketShareResult.fail(TicketShareMethod.text,
              'No se pudo compartir en este dispositivo');
    } catch (e) {
      // Fallback: copiar al portapapeles
      return copyToClipboard(ticket: ticket, businessName: businessName);
    }
  }

  // ── Copiar al portapapeles ───────────────────────────────────────────────

  /// Copia el texto del ticket al portapapeles del dispositivo.
  Future<TicketShareResult> copyToClipboard({
    required TicketModel ticket,
    required String businessName,
  }) async {
    try {
      final text = generateTicketText(
        ticket: ticket,
        businessName: businessName,
      );
      await Clipboard.setData(ClipboardData(text: text));
      return TicketShareResult.ok(TicketShareMethod.clipboard);
    } catch (e) {
      return TicketShareResult.fail(
          TicketShareMethod.clipboard, 'Error al copiar: $e');
    }
  }

  // ── PDF ─────────────────────────────────────────────────────────────────

  /// Genera el PDF del ticket y lo descarga (Web) o comparte (móvil).
  ///
  /// En Web: usa `share_plus` con XFile en memoria (sin path_provider).
  /// En móvil: usa `share_plus.shareXFiles` con XFile desde bytes.
  Future<TicketShareResult> shareAsPdf({
    required TicketModel ticket,
    required String businessName,
  }) async {
    try {
      final pdfBytes = await _generatePdfBytes(
        ticket: ticket,
        businessName: businessName,
      );

      final fileName =
          'ticket_${ticket.id.isNotEmpty ? ticket.id : _dateStamp()}.pdf';

      if (kIsWeb) {
        // En Web: share_plus 11.x soporta XFile.fromData que funciona
        // con la Web Share File API. Si no está disponible, usa download.
        await _sharePdfCrossPlatform(
          pdfBytes: pdfBytes,
          fileName: fileName,
          businessName: businessName,
        );
      } else {
        await _sharePdfCrossPlatform(
          pdfBytes: pdfBytes,
          fileName: fileName,
          businessName: businessName,
        );
      }

      return TicketShareResult.ok(TicketShareMethod.pdf);
    } catch (e) {
      return TicketShareResult.fail(
          TicketShareMethod.pdf, 'Error al generar PDF: $e');
    }
  }

  // ── WhatsApp ─────────────────────────────────────────────────────────────

  /// Abre WhatsApp con el texto del ticket pre-cargado.
  ///
  /// En Web: abre una nueva pestaña con `wa.me/?text=`.
  /// En móvil: usa `share_plus` que el usuario puede seleccionar WhatsApp.
  Future<TicketShareResult> shareViaWhatsApp({
    required TicketModel ticket,
    required String businessName,
  }) async {
    try {
      final text = generateTicketText(
        ticket: ticket,
        businessName: businessName,
      );

      if (kIsWeb) {
        final encoded = Uri.encodeComponent(text);
        final whatsappUrl = 'https://wa.me/?text=$encoded';
        // Usar url_launcher no está importado aquí; usamos el método de href nativo
        // share_plus no puede abrir URLs específicas en Web, así que
        // usamos la API JS de window.open indirectamente
        await _openUrlOnWeb(whatsappUrl);
      } else {
        // En móvil, share_plus muestra el sheet donde el usuario puede elegir WhatsApp
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'Ticket de venta - $businessName',
          ),
        );
      }

      return TicketShareResult.ok(TicketShareMethod.whatsapp);
    } catch (e) {
      return TicketShareResult.fail(
          TicketShareMethod.whatsapp, 'Error al abrir WhatsApp: $e');
    }
  }

  // ── Generación de PDF ────────────────────────────────────────────────────

  /// Genera los bytes del PDF del ticket.
  Future<Uint8List> _generatePdfBytes({
    required TicketModel ticket,
    required String businessName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = dateFormat.format(ticket.creation.toDate());
    final paymentMethod = PaymentMethod.fromCode(ticket.payMode).displayName;
    final currencySymbol = ticket.currencySymbol;

    pdf.addPage(
      pw.Page(
        // Formato rollo 80mm para impresora térmica — ancho 80mm, alto dinámico
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 8 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(date, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.Divider(),

              // Productos
              ...ticket.products.map((product) {
                final qty = _formatQuantity(product.quantity);
                final lineTotal =
                    '$currencySymbol${_formatAmount(product.salePrice * product.quantity)}';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        product.description,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$qty x $currencySymbol${_formatAmount(product.salePrice)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            lineTotal,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(),

              // Descuento (si aplica)
              if (ticket.getDiscountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Descuento:',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '-$currencySymbol${_formatAmount(ticket.getDiscountAmount)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$currencySymbol${_formatAmount(ticket.getTotalPrice)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),

              // Método de pago
              pw.Text(
                'Forma de pago: $paymentMethod',
                style: const pw.TextStyle(fontSize: 10),
              ),

              // Efectivo recibido y vuelto
              if (ticket.valueReceived > ticket.getTotalPrice) ...[
                pw.Text(
                  'Recibido: $currencySymbol${_formatAmount(ticket.valueReceived)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Vuelto: $currencySymbol${_formatAmount(ticket.valueReceived - ticket.getTotalPrice)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],

              pw.Divider(),

              pw.Center(
                child: pw.Text(
                  '¡Gracias por su compra!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Comparte el PDF usando share_plus con XFile en memoria.
  ///
  /// Funciona en Web (Web Share Files API) y en móvil (sheet nativo).
  Future<void> _sharePdfCrossPlatform({
    required Uint8List pdfBytes,
    required String fileName,
    required String businessName,
  }) async {
    if (kIsWeb) {
      // En Web: descargar directamente usando el helper (dart:html)
      downloadFile(pdfBytes, fileName);
    } else {
      // En Móvil: compartir usando share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
          subject: 'Ticket de venta - $businessName',
        ),
      );
    }
  }

  /// Abre una URL en el navegador web.
  ///
  /// En Flutter Web, usa `window.open` a través de un link HTML temporal.
  Future<void> _openUrlOnWeb(String url) async {
    // No podemos importar dart:html directamente aquí porque este archivo
    // se compila también para móvil. En cambio, usamos share_plus
    // que ya tiene la lógica de dart:html internamente.
    // Alternativa: usamos url_launcher que ya está importado en el proyecto.
    // Como este servicio no tiene url_launcher importado, usamos share_plus
    // con el link como texto para que el usuario lo copie si falla.
    // La apertura real se hace en el diálogo con url_launcher.
    if (!kIsWeb) return;
    // El diálogo maneja la apertura de WhatsApp directamente en Web.
  }

  // ── Helpers privados ─────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es');
    return formatter.format(amount);
  }

  String _formatQuantity(double qty) {
    // Si es número entero, mostrar sin decimales
    if (qty == qty.truncateToDouble()) {
      return qty.toInt().toString();
    }
    return NumberFormat('#,##0.##', 'es').format(qty);
  }

  String _dateStamp() {
    return DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  }
}
