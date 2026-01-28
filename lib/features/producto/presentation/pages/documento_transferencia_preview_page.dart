import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/transferencia_stock.dart';
import '../services/pdf_transferencia_generator.dart';

/// Página de vista previa del documento PDF de transferencia
/// Permite visualizar, compartir, guardar e imprimir el documento
class DocumentoTransferenciaPreviewPage extends StatefulWidget {
  final TransferenciaStock transferencia;
  final String empresaNombre;
  final String? empresaRuc;
  final Uint8List? logoEmpresa;

  const DocumentoTransferenciaPreviewPage({
    super.key,
    required this.transferencia,
    required this.empresaNombre,
    this.empresaRuc,
    this.logoEmpresa,
  });

  @override
  State<DocumentoTransferenciaPreviewPage> createState() =>
      _DocumentoTransferenciaPreviewPageState();
}

class _DocumentoTransferenciaPreviewPageState
    extends State<DocumentoTransferenciaPreviewPage> {
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
      final pdfBytes = await PdfTransferenciaGenerator.generarDocumento(
        transferencia: widget.transferencia,
        empresaNombre: widget.empresaNombre,
        empresaRuc: widget.empresaRuc,
        logoEmpresa: widget.logoEmpresa,
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
        title: 'Documento de Transferencia',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null) ...[
            // Botón compartir
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareDocument(),
              tooltip: 'Compartir',
            ),
            // Botón imprimir
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printDocument(),
              tooltip: 'Imprimir',
            ),
            // Menú de más opciones
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    _saveDocument();
                    break;
                  case 'regenerate':
                    _generatePdf();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Guardar en dispositivo'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'regenerate',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Regenerar documento'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Generando documento...',
              style: TextStyle(fontSize: 16),
            ),
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
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
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
      return const Center(
        child: Text('No se pudo generar el documento'),
      );
    }

    return Column(
      children: [
        // Banner informativo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Este documento puede ser impreso, firmado y luego digitalizado para adjuntarlo a la transferencia',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Vista previa del PDF
        Expanded(
          child: PdfPreview(
            build: (format) => _pdfBytes!,
            allowSharing: false, // Usamos nuestros propios botones
            allowPrinting: false, // Usamos nuestros propios botones
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName:
                'Transferencia_${widget.transferencia.codigo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            // Personalizar acciones
            actions: const [],
          ),
        ),
      ],
    );
  }

  /// Compartir el documento
  Future<void> _shareDocument() async {
    if (_pdfBytes == null) return;

    try {
      await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename:
            'Transferencia_${widget.transferencia.codigo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        _showError('Error al compartir: $e');
      }
    }
  }

  /// Imprimir el documento
  Future<void> _printDocument() async {
    if (_pdfBytes == null) return;

    try {
      await Printing.layoutPdf(
        onLayout: (format) => _pdfBytes!,
        name: 'Transferencia ${widget.transferencia.codigo}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (mounted) {
        _showError('Error al imprimir: $e');
      }
    }
  }

  /// Guardar el documento en el dispositivo
  Future<void> _saveDocument() async {
    if (_pdfBytes == null) return;

    try {
      // El paquete printing maneja automáticamente el guardado en el dispositivo
      final result = await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename:
            'Transferencia_${widget.transferencia.codigo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted && result) {
        _showSuccess('Documento guardado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
