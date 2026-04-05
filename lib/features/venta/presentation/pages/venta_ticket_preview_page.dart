import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/venta_remote_datasource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart';
import '../../domain/entities/venta.dart';
import '../../domain/usecases/get_venta_usecase.dart';
import '../services/pdf_venta_generator.dart';
import '../../../servicio/presentation/widgets/bluetooth_printer_sheet.dart';
import '../services/ticket_venta_esc_pos_generator.dart';

class VentaTicketPreviewPage extends StatefulWidget {
  final String ventaId;

  const VentaTicketPreviewPage({super.key, required this.ventaId});

  @override
  State<VentaTicketPreviewPage> createState() => _VentaTicketPreviewPageState();
}

class _VentaTicketPreviewPageState extends State<VentaTicketPreviewPage> {
  Venta? _venta;
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

    final result = await locator<GetVentaUseCase>()(ventaId: widget.ventaId);
    if (result is! Success<Venta>) {
      if (!mounted) return;
      setState(() {
        _error = (result as Error).message;
        _loading = false;
      });
      return;
    }

    final venta = result.data;

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

    String nombreImpuesto = 'IGV';
    double porcentajeImpuesto = 18.0;
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      nombreImpuesto = configState.configuracion.nombreImpuesto;
      porcentajeImpuesto =
          configState.configuracion.impuestoDefaultPorcentaje;
    }

    // Cargar configuración de documentos (colores, logo, márgenes, etc.)
    ConfiguracionDocumentoCompleta? documentConfig;
    try {
      final configResult = await locator<GetConfiguracionCompletaUseCase>()(
        tipo: 'TICKET_VENTA',
        formato: 'TICKET_80MM',
        sedeId: venta.sedeId,
      );
      if (configResult is Success<ConfiguracionDocumentoCompleta>) {
        documentConfig = configResult.data;
      }
    } catch (_) {}

    // Cargar config efectiva de facturación (sede > empresa)
    String? resolucionSunat;
    String? rucEfectivo;
    String? razonSocialEfectiva;
    String? nombreComercialEfectivo;
    String? direccionFiscalEfectiva;
    try {
      final datasource = locator<VentaRemoteDataSource>();
      // Usar sede del comprobante (emisor) si existe, sino sede de la venta
      final config = await datasource.getConfiguracionSunat(sedeId: venta.comprobanteSedeId ?? venta.sedeId);
      resolucionSunat = config['resolucionSunat'] as String?;
      rucEfectivo = config['ruc'] as String?;
      razonSocialEfectiva = config['razonSocial'] as String?;
      nombreComercialEfectivo = config['nombreComercial'] as String?;
      direccionFiscalEfectiva = config['direccionFiscal'] as String?;
    } catch (_) {}

    // Logo: prioridad configuración de documentos > logo de empresa
    Uint8List? logoBytes;
    final logoUrl = documentConfig?.configuracion.logoUrl ?? empresa.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) logoBytes = response.bodyBytes;
      } catch (_) {}
    }

    // Cargar firma del cliente si existe
    Uint8List? firmaBytes;
    try {
      final storageService = locator<StorageService>();
      final archivos = await storageService.getFilesByEntity(
        entidadTipo: 'VENTA',
        entidadId: venta.id,
        empresaId: venta.empresaId,
      );
      final firmaArchivo = archivos.where((a) => a.categoria == 'FIRMA').firstOrNull;
      if (firmaArchivo != null) {
        final response = await http.get(Uri.parse(firmaArchivo.url));
        if (response.statusCode == 200) firmaBytes = response.bodyBytes;
      }
    } catch (_) {}

    try {
      final pdf = await PdfVentaGenerator.generarTicket(
        venta: venta,
        empresaNombre: empresa.nombre,
        empresaRuc: rucEfectivo ?? empresa.ruc,
        razonSocial: razonSocialEfectiva,
        nombreComercial: nombreComercialEfectivo,
        direccionFiscal: direccionFiscalEfectiva,
        logoEmpresa: logoBytes,
        nombreImpuesto: nombreImpuesto,
        porcentajeImpuesto: porcentajeImpuesto,
        documentConfig: documentConfig,
        firmaCliente: firmaBytes,
        resolucionSunat: resolucionSunat,
      );

      if (!mounted) return;
      setState(() {
        _venta = venta;
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
          title: 'Ticket de Venta',
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
                onPressed: _printBluetooth,
                tooltip: 'Imprimir Bluetooth',
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
        // Previsualización del PDF
        Expanded(
          child: PdfPreview(
            build: (format) => _pdfBytes!,
            allowSharing: false,
            allowPrinting: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'ticket_${_venta?.codigo ?? 'venta'}.pdf',
            actions: const [],
          ),
        ),

        // Botones de acción
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printBluetooth,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        '${tempDir.path}/ticket_${_venta?.codigo ?? 'venta'}.pdf');
    await file.writeAsBytes(_pdfBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ticket de venta ${_venta?.codigo}',
    );
  }

  Future<void> _printBluetooth() async {
    if (_venta == null) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresa = empresaState.context.empresa;

    String nombreImpuesto = 'IGV';
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      nombreImpuesto = configState.configuracion.nombreImpuesto;
    }

    final bytes = await TicketVentaEscPosGenerator.generate(
      venta: _venta!,
      empresaNombre: empresa.nombre,
      empresaRuc: empresa.ruc,
      empresaDireccion: empresa.direccionFiscal,
      empresaTelefono: empresa.telefono,
      nombreImpuesto: nombreImpuesto,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BluetoothPrinterSheet(ticketBytes: bytes),
    );
  }
}
