import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
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

    Uint8List? logoBytes;
    if (empresa.logo != null && empresa.logo!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(empresa.logo!));
        if (response.statusCode == 200) logoBytes = response.bodyBytes;
      } catch (_) {}
    }

    try {
      final pdf = await PdfVentaGenerator.generarTicket(
        venta: venta,
        empresaNombre: empresa.nombre,
        empresaRuc: empresa.ruc,
        logoEmpresa: logoBytes,
        nombreImpuesto: nombreImpuesto,
        porcentajeImpuesto: porcentajeImpuesto,
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: AppColors.blue1),
          const SizedBox(height: 16),
          Text(
            _venta?.codigo ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Ticket generado correctamente',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _sharePdf,
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _printBluetooth,
                icon: const Icon(Icons.print),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/ticket_${_venta?.codigo ?? 'venta'}.pdf');
    await file.writeAsBytes(_pdfBytes!);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Ticket de venta ${_venta?.codigo}',
      ),
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
