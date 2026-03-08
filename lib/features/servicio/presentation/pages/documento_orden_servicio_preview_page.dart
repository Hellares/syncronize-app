import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/orden_servicio.dart';
import '../services/pdf_orden_servicio_generator.dart';

class DocumentoOrdenServicioPreviewPage extends StatefulWidget {
  final OrdenServicio orden;
  final String empresaNombre;
  final String? empresaRuc;
  final String? empresaDireccion;
  final String? empresaTelefono;
  final String? sedeNombre;
  final Uint8List? logoEmpresa;
  final String? colorPrimario;

  const DocumentoOrdenServicioPreviewPage({
    super.key,
    required this.orden,
    required this.empresaNombre,
    this.empresaRuc,
    this.empresaDireccion,
    this.empresaTelefono,
    this.sedeNombre,
    this.logoEmpresa,
    this.colorPrimario,
  });

  @override
  State<DocumentoOrdenServicioPreviewPage> createState() =>
      _DocumentoOrdenServicioPreviewPageState();
}

class _DocumentoOrdenServicioPreviewPageState
    extends State<DocumentoOrdenServicioPreviewPage> {
  bool _isGenerating = true;
  Uint8List? _pdfBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Load firma if available
      Uint8List? firmaBytes;
      try {
        final storageService = locator<StorageService>();
        final archivos = await storageService.getFilesByEntity(
          entidadTipo: 'ORDEN_SERVICIO',
          entidadId: widget.orden.id,
          empresaId: widget.orden.empresaId,
        );
        final firmaArchivo = archivos.where((a) => a.categoria == 'FIRMA').firstOrNull;
        if (firmaArchivo != null) {
          final response = await http.get(Uri.parse(firmaArchivo.url));
          if (response.statusCode == 200) {
            firmaBytes = response.bodyBytes;
          }
        }
      } catch (_) {}

      final pdfBytes = await PdfOrdenServicioGenerator.generarTicket(
        orden: widget.orden,
        empresaNombre: widget.empresaNombre,
        empresaRuc: widget.empresaRuc,
        empresaDireccion: widget.empresaDireccion,
        empresaTelefono: widget.empresaTelefono,
        sedeNombre: widget.sedeNombre,
        logoEmpresa: widget.logoEmpresa,
        colorPrimario: widget.colorPrimario,
        firmaCliente: firmaBytes,
      );

      if (mounted) {
        setState(() {
          _pdfBytes = pdfBytes;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al generar el documento: $e';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Ticket - ${widget.orden.codigo}',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null) ...[
            // Share via native share sheet
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
              tooltip: 'Compartir',
            ),
            // Direct WhatsApp share
            if (widget.orden.cliente?.telefono != null)
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: _shareToWhatsApp,
                tooltip: 'Enviar por WhatsApp',
              ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printDocument,
              tooltip: 'Imprimir',
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _pdfBytes != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.blue1),
            SizedBox(height: 16),
            Text('Generando ticket...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(child: Text('No se pudo generar el documento'));
    }

    return PdfPreview(
      build: (format) => _pdfBytes!,
      allowSharing: false,
      allowPrinting: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      pdfFileName: _getFileName(),
      actions: const [],
    );
  }

  Widget _buildBottomBar() {
    final hasPhone = widget.orden.cliente?.telefono != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Share general
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareDocument,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Compartir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue1,
                side: const BorderSide(color: AppColors.blue1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (hasPhone) ...[
            const SizedBox(width: 12),
            // WhatsApp button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareToWhatsApp,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFileName() {
    return 'Orden_${widget.orden.codigo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  Future<void> _shareDocument() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _getFileName());
    } catch (e) {
      if (mounted) _showError('Error al compartir: $e');
    }
  }

  Future<void> _shareToWhatsApp() async {
    if (_pdfBytes == null) return;

    final telefono = widget.orden.cliente?.telefono;
    if (telefono == null) return;

    // First share the PDF (user picks WhatsApp from share sheet)
    // Then open WhatsApp chat with the client's number
    try {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _getFileName());

      // Build WhatsApp message
      final mensaje = Uri.encodeComponent(
        'Hola ${widget.orden.cliente?.nombre ?? ""}! '
        'Le compartimos el ticket de su orden de servicio '
        '*${widget.orden.codigo}*. '
        'Estado actual: *${_estadoLabel(widget.orden.estado)}*. '
        'Gracias por su confianza.',
      );

      // Normalize phone number (remove spaces, dashes)
      var phone = telefono.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phone.startsWith('+')) {
        // Default to Peru country code if no prefix
        if (phone.startsWith('9') && phone.length == 9) {
          phone = '51$phone';
        }
      } else {
        phone = phone.substring(1);
      }

      final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$mensaje');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  Future<void> _printDocument() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _pdfBytes!,
        name: 'Orden ${widget.orden.codigo}',
      );
    } catch (e) {
      if (mounted) _showError('Error al imprimir: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _estadoLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'En Diagnostico',
      'ESPERANDO_APROBACION': 'Esperando Aprobacion',
      'EN_REPARACION': 'En Reparacion',
      'PENDIENTE_PIEZAS': 'Pendiente Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Listo para Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }
}
