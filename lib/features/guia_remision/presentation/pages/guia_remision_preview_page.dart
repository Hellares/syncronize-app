import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/guia_remision.dart';
import '../../data/datasources/guia_remision_remote_datasource.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import '../services/pdf_guia_remision_generator.dart';

class GuiaRemisionPreviewPage extends StatefulWidget {
  final String guiaId;

  const GuiaRemisionPreviewPage({super.key, required this.guiaId});

  @override
  State<GuiaRemisionPreviewPage> createState() =>
      _GuiaRemisionPreviewPageState();
}

class _GuiaRemisionPreviewPageState extends State<GuiaRemisionPreviewPage> {
  GuiaRemision? _guia;
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Load guia from repository
    final result =
        await locator<GuiaRemisionRepository>().obtener(widget.guiaId);
    if (result is! Success<GuiaRemision>) {
      if (!mounted) return;
      setState(() {
        _error = (result as Error).message;
        _loading = false;
      });
      return;
    }

    final guia = result.data;

    if (!mounted) return;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) {
      setState(() {
        _error = 'No se pudo obtener la empresa';
        _loading = false;
      });
      return;
    }

    final empresa = empresaState.context.empresa;
    final empresaRuc = empresa.ruc;
    final razonSocial = empresa.razonSocial;
    final direccionFiscal = empresa.direccionFiscal;

    // Load logo
    Uint8List? logoBytes;
    if (empresa.logo != null && empresa.logo!.isNotEmpty) {
      try {
        final logoResponse = await http.get(Uri.parse(empresa.logo!));
        if (logoResponse.statusCode == 200) {
          logoBytes = logoResponse.bodyBytes;
        }
      } catch (_) {}
    }

    // Cargar ubigeos para resolver nombres en el PDF
    List<Map<String, dynamic>>? ubigeos;
    try {
      ubigeos = await locator<GuiaRemisionRemoteDatasource>().getUbigeos();
    } catch (_) {}

    try {
      final pdf = await PdfGuiaRemisionGenerator.generar(
        guia: guia,
        empresaNombre: empresa.nombre,
        empresaRuc: empresaRuc,
        razonSocial: razonSocial,
        direccionFiscal: direccionFiscal,
        logoEmpresa: logoBytes,
        ubigeos: ubigeos,
      );

      if (!mounted) return;
      setState(() {
        _guia = guia;
        _pdfBytes = pdf;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error generando PDF: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Guía de Remisión',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            if (_pdfBytes != null) ...[
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _sharePdf,
                tooltip: 'Compartir PDF',
              ),
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _printPdf,
                tooltip: 'Imprimir',
              ),
            ],
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadAndGenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_pdfBytes == null) return const SizedBox.shrink();

    return Column(
      children: [
        // PDF preview
        Expanded(
          child: PdfPreview(
            build: (format) => _pdfBytes!,
            allowSharing: false,
            allowPrinting: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName:
                'guia_remision_${_guia?.codigoGenerado ?? 'guia'}.pdf',
            actions: const [],
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printPdf,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/guia_remision_${_guia?.codigoGenerado ?? 'guia'}.pdf');
    await file.writeAsBytes(_pdfBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Guía de Remisión ${_guia?.codigoGenerado}',
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) => _pdfBytes!);
  }
}
