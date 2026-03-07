import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/compra.dart';
import '../../domain/entities/orden_compra.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';
import '../services/pdf_compra_generator.dart';

class DocumentoCompraPreviewPage extends StatefulWidget {
  final Compra? compra;
  final OrdenCompra? orden;
  final String empresaNombre;
  final String? empresaRuc;
  final String? empresaDireccion;
  final String? empresaTelefono;
  final Uint8List? logoEmpresa;
  final String nombreImpuesto;
  final double porcentajeImpuesto;
  final ConfiguracionDocumentoCompleta? documentConfig;
  final FormatoPapel formatoPapel;

  const DocumentoCompraPreviewPage({
    super.key,
    this.compra,
    this.orden,
    required this.empresaNombre,
    this.empresaRuc,
    this.empresaDireccion,
    this.empresaTelefono,
    this.logoEmpresa,
    this.nombreImpuesto = 'IGV',
    this.porcentajeImpuesto = 18.0,
    this.documentConfig,
    this.formatoPapel = FormatoPapel.A4,
  }) : assert(compra != null || orden != null);

  @override
  State<DocumentoCompraPreviewPage> createState() =>
      _DocumentoCompraPreviewPageState();
}

class _DocumentoCompraPreviewPageState
    extends State<DocumentoCompraPreviewPage> {
  bool _isGenerating = true;
  Uint8List? _pdfBytes;
  String? _error;

  bool get _isCompra => widget.compra != null;
  String get _codigo => _isCompra ? widget.compra!.codigo : widget.orden!.codigo;
  String get _tipoDoc => _isCompra ? 'Compra' : 'Orden de Compra';

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
      Uint8List pdfBytes;

      if (_isCompra) {
        pdfBytes = await PdfCompraGenerator.generarDocumentoCompra(
          compra: widget.compra!,
          empresaNombre: widget.empresaNombre,
          empresaRuc: widget.empresaRuc,
          empresaDireccion: widget.empresaDireccion,
          empresaTelefono: widget.empresaTelefono,
          logoEmpresa: widget.logoEmpresa,
          nombreImpuesto: widget.nombreImpuesto,
          porcentajeImpuesto: widget.porcentajeImpuesto,
          documentConfig: widget.documentConfig,
        );
      } else {
        pdfBytes = await PdfCompraGenerator.generarDocumentoOrdenCompra(
          orden: widget.orden!,
          empresaNombre: widget.empresaNombre,
          empresaRuc: widget.empresaRuc,
          empresaDireccion: widget.empresaDireccion,
          empresaTelefono: widget.empresaTelefono,
          logoEmpresa: widget.logoEmpresa,
          nombreImpuesto: widget.nombreImpuesto,
          porcentajeImpuesto: widget.porcentajeImpuesto,
          documentConfig: widget.documentConfig,
        );
      }

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
        title: '$_tipoDoc - $_codigo',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printDocument,
              tooltip: 'Imprimir',
            ),
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
            Text('Generando documento...', style: TextStyle(fontSize: 16)),
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
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

  String _getFileName() {
    final prefix = _isCompra ? 'Compra' : 'OrdenCompra';
    return '${prefix}_${_codigo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  Future<void> _shareDocument() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _getFileName());
    } catch (e) {
      if (mounted) _showError('Error al compartir: $e');
    }
  }

  Future<void> _printDocument() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _pdfBytes!,
        name: '$_tipoDoc $_codigo',
        format: widget.formatoPapel.pdfPageFormat,
      );
    } catch (e) {
      if (mounted) _showError('Error al imprimir: $e');
    }
  }

  Future<void> _saveDocument() async {
    if (_pdfBytes == null) return;
    try {
      final result = await Printing.sharePdf(bytes: _pdfBytes!, filename: _getFileName());
      if (mounted && result) {
        _showSuccess('Documento guardado correctamente');
      }
    } catch (e) {
      if (mounted) _showError('Error al guardar: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
