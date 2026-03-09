import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/bluetooth_printer_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/orden_servicio.dart';
import '../services/pdf_orden_servicio_generator.dart';
import '../services/ticket_esc_pos_generator.dart';
import '../widgets/bluetooth_printer_sheet.dart';

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
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
              tooltip: 'Compartir',
            ),
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
              CustomButton(
                text: 'Reintentar',
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                backgroundColor: AppColors.blue1,
                height: 40,
                borderRadius: 8,
                onPressed: _generatePdf,
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
      padding: const EdgeInsets.all(12),
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primera fila: Compartir + WhatsApp
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Compartir',
                    icon: const Icon(Icons.share, size: 14, color: AppColors.blue1),
                    isOutlined: true,
                    borderColor: AppColors.blue1,
                    textColor: AppColors.blue1,
                    enableShadows: false,
                    height: 38,
                    borderRadius: 8,
                    onPressed: _shareDocument,
                  ),
                ),
                if (hasPhone) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'WhatsApp',
                      icon: const Icon(Icons.chat, size: 14, color: Colors.white),
                      backgroundColor: const Color(0xFF25D366),
                      height: 38,
                      borderRadius: 8,
                      onPressed: _shareToWhatsApp,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Segunda fila: Imprimir BT
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Imprimir Bluetooth',
                icon: const Icon(Icons.bluetooth, size: 16, color: Colors.white),
                backgroundColor: AppColors.blue1,
                height: 42,
                borderRadius: 8,
                onPressed: _printBluetooth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──

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

    try {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _getFileName());

      final mensaje = Uri.encodeComponent(
        'Hola ${widget.orden.cliente?.nombre ?? ""}! '
        'Le compartimos el ticket de su orden de servicio '
        '*${widget.orden.codigo}*. '
        'Estado actual: *${_estadoLabel(widget.orden.estado)}*. '
        'Gracias por su confianza.',
      );

      var phone = telefono.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phone.startsWith('+')) {
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

  Future<void> _printBluetooth() async {
    try {
      final paperSize = await BluetoothPrinterService.getPaperSize();

      final ticketBytes = await TicketEscPosGenerator.generarTicket(
        orden: widget.orden,
        empresaNombre: widget.empresaNombre,
        empresaRuc: widget.empresaRuc,
        empresaDireccion: widget.empresaDireccion,
        empresaTelefono: widget.empresaTelefono,
        sedeNombre: widget.sedeNombre,
        logoEmpresa: widget.logoEmpresa,
        paperWidth: paperSize,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BluetoothPrinterSheet(ticketBytes: ticketBytes),
      );
    } catch (e) {
      if (mounted) _showError('Error al generar ticket: $e');
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
