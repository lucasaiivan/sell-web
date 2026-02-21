import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/core/services/external/ticket_share_service.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Diálogo MD3 dedicado para compartir un ticket de venta por múltiples medios.
///
/// ## Funcionalidades:
/// - Vista previa del ticket como texto monoespacio
/// - Copiar al portapapeles (siempre disponible)
/// - Descargar/Compartir PDF
/// - Compartir como texto (Web Share API o fallback al portapapeles)
/// - Abrir WhatsApp con el texto del ticket pre-cargado
class ShareTicketDialog extends StatefulWidget {
  const ShareTicketDialog({
    super.key,
    required this.ticket,
    required this.businessName,
  });

  final TicketModel ticket;
  final String businessName;

  @override
  State<ShareTicketDialog> createState() => _ShareTicketDialogState();
}

class _ShareTicketDialogState extends State<ShareTicketDialog> {
  final _shareService = getIt<TicketShareService>();

  bool _isGeneratingPdf = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: 'Compartir Ticket',
      icon: Icons.share_rounded,
      width: 500,
      maxHeight: 700,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vista previa del ticket
          _buildTicketPreview(theme),


          // Sección de acciones
          _buildShareActionsGrid(theme),

          // Feedback (éxito o error) y carga
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                SizeTransition(sizeFactor: anim, child: child),
            child: _feedbackMessage != null
                ? Padding(
                    key: const ValueKey('feedback'),
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildFeedbackBanner(theme),
                  )
                : _isGeneratingPdf
                    ? Padding(
                        key: const ValueKey('loading'),
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildLoadingBanner(theme),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),

          // Espacio inferior para los botones flotantes del BaseDialog
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ── Vista previa del ticket ───────────────────────────────────────────────

  Widget _buildTicketPreview(ThemeData theme) {
    final ticketText = _shareService.generateTicketText(
      ticket: widget.ticket,
      businessName: widget.businessName,
    );

    return DialogComponents.infoSection(
      context: context,
      title: 'Vista Previa',
      icon: Icons.receipt_long_rounded,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: SingleChildScrollView(
          child: Text(
            ticketText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid de acciones de compartir ────────────────────────────────────────

  Widget _buildShareActionsGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Copiar texto
          _buildActionCard(
            theme: theme,
            icon: Icons.content_copy_rounded,
            label: 'Copiar\nTexto',
            color: theme.colorScheme.primary,
            onTap: _onCopyToClipboard,
          ),

          // 2. Descargar / Compartir PDF
          _buildActionCard(
            theme: theme,
            icon: kIsWeb ? Icons.download_rounded : Icons.picture_as_pdf_rounded,
            label: kIsWeb ? 'Descargar\nPDF' : 'Compartir\nPDF',
            color: const Color(0xFFE53935),
            isLoading: _isGeneratingPdf,
            onTap: _isGeneratingPdf ? null : _onSharePdf,
          ),

          // 3. Compartir texto
          _buildActionCard(
            theme: theme,
            icon: Icons.ios_share_rounded,
            label: 'Compartir\nTexto',
            color: const Color(0xFF1E88E5),
            onTap: _onShareText,
          ),

          // 4. WhatsApp
          _buildActionCard(
            theme: theme,
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: _onShareWhatsApp,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isEnabled = onTap != null;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _PressableCard(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1, // Cuadrado perfecto (simétrico)
            child: Container(
              decoration: BoxDecoration(
                color: isEnabled
                    ? theme.colorScheme.surfaceContainerLow
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: isLoading
                        ? CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: color,
                          )
                        : Icon(
                            icon,
                            color: isEnabled ? color : theme.colorScheme.outline,
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoading ? 'Cargando' : label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isEnabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Banners de feedback ──────────────────────────────────────────────────

  Widget _buildFeedbackBanner(ThemeData theme) {
    final isError = _feedbackIsError;
    final bgColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final fgColor = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: fgColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Generando PDF...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Manejadores de acciones ──────────────────────────────────────────────

  Future<void> _onCopyToClipboard() async {
    final result = await _shareService.copyToClipboard(
      ticket: widget.ticket,
      businessName: widget.businessName,
    );
    _showFeedback(
      success: result.success,
      successMsg: '✅ Texto copiado al portapapeles',
      errorMsg: result.message ?? 'Error al copiar',
    );
  }

  Future<void> _onSharePdf() async {
    setState(() {
      _isGeneratingPdf = true;
      _feedbackMessage = null;
    });

    final result = await _shareService.shareAsPdf(
      ticket: widget.ticket,
      businessName: widget.businessName,
    );

    if (mounted) {
      setState(() => _isGeneratingPdf = false);
      _showFeedback(
        success: result.success,
        successMsg: '✅ PDF generado correctamente',
        errorMsg: result.message ?? 'Error al generar el PDF',
      );
    }
  }

  Future<void> _onShareText() async {
    final result = await _shareService.shareAsText(
      ticket: widget.ticket,
      businessName: widget.businessName,
    );

    // Solo mostramos feedback si el método fue portapapeles (fallback)
    // o si hubo error
    if (result.method == TicketShareMethod.clipboard) {
      _showFeedback(
        success: true,
        successMsg: '✅ Texto copiado (Web Share no disponible)',
      );
    } else if (!result.success) {
      _showFeedback(
        success: false,
        errorMsg: result.message ?? 'Error al compartir',
      );
    }
  }

  Future<void> _onShareWhatsApp() async {
    try {
      final text = _shareService.generateTicketText(
        ticket: widget.ticket,
        businessName: widget.businessName,
      );
      final encoded = Uri.encodeComponent(text);
      final whatsappUrl = 'https://wa.me/?text=$encoded';

      if (kIsWeb) {
        // En Web: usar url_launcher para abrir en nueva pestaña
        final uri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showFeedback(
            success: false,
            errorMsg: 'No se pudo abrir WhatsApp',
          );
          return;
        }
      } else {
        // En móvil: delegar al servicio (usa share_plus)
        final result = await _shareService.shareViaWhatsApp(
          ticket: widget.ticket,
          businessName: widget.businessName,
        );
        if (!result.success) {
          _showFeedback(
            success: false,
            errorMsg: result.message ?? 'Error al abrir WhatsApp',
          );
        }
      }
    } catch (e) {
      _showFeedback(
        success: false,
        errorMsg: 'Error: $e',
      );
    }
  }

  void _showFeedback({
    required bool success,
    String? successMsg,
    String? errorMsg,
  }) {
    if (!mounted) return;
    setState(() {
      _feedbackIsError = !success;
      _feedbackMessage = success ? successMsg : errorMsg;
    });

    // Auto-ocultar el feedback luego de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }
}

// ── Widget de presión con animación de escala ─────────────────────────────

class _PressableCard extends StatefulWidget {
  const _PressableCard({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.94).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _ctrl.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Helper para mostrar el diálogo de compartir ticket.
///
/// Ejemplo de uso:
/// ```dart
/// await showShareTicketDialog(
///   context: context,
///   ticket: ticket,
///   businessName: 'Mi Negocio',
/// );
/// ```
Future<void> showShareTicketDialog({
  required BuildContext context,
  required TicketModel ticket,
  required String businessName,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ShareTicketDialog(
      ticket: ticket,
      businessName: businessName,
    ),
  );
}
