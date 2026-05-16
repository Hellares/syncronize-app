import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';
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

  // Logo de la empresa ya descargado para reusar en impresión Bluetooth
  // (manual y auto). Cargado una sola vez en _loadAndGenerate; sin esto
  // el ticket ESC-POS salía sin logo aunque la empresa tenga uno.
  Uint8List? _logoBytes;

  // Identidad efectiva (sede override > empresa) para reusar en _printBluetooth.
  // Sin esto, el ticket Bluetooth caía a empresa.direccionFiscal aunque la
  // sede tuviera direccionFiscalSede propia.
  String? _rucEfectivo;
  String? _razonSocialEfectiva;
  String? _direccionFiscalEfectiva;
  String? _nombreComercialEfectivo;
  String? _telefonoEfectivo;

  /// Polling para esperar la respuesta de SUNAT cuando el comprobante
  /// es electrónico (BOLETA/FACTURA) y aún no llegó el hash. El envío
  /// SUNAT es async (lo dispara el backend tras el cobro), así que el
  /// primer fetch puede llegar sin hash. Reintenta hasta el límite,
  /// luego muestra el ticket sin hash con un botón refresh manual.
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  bool _esperandoSunat = false;
  static const int _maxPollingAttempts = 8; // ~16s en total
  static const Duration _pollingInterval = Duration(seconds: 2);

  /// Bandera para que la auto-impresión sólo se dispare en la PRIMERA
  /// carga (el polling SUNAT re-llama _loadAndGenerate y no queremos
  /// imprimir varias copias en cada intento).
  bool _autoPrintIntentado = false;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Indica si la venta espera respuesta SUNAT (comprobante electrónico
  /// sin ninguna seña de respuesta del proveedor y sin estado terminal).
  /// Cualquiera de estos campos ya implica respuesta recibida (algunos
  /// proveedores entregan URL antes que hash):
  ///  - `comprobanteSunatHash`
  ///  - `comprobanteSunatXmlUrl`
  ///  - `comprobanteEnlaceProveedor`
  /// Estados terminales también detienen el polling (ACEPTADO/RECHAZADO/ANULADO).
  bool _esperaSunat(Venta v) {
    final esElectronico =
        v.tipoComprobante == 'BOLETA' || v.tipoComprobante == 'FACTURA';
    if (!esElectronico) return false;
    final hash = v.comprobanteSunatHash;
    if (hash != null && hash.isNotEmpty) return false;
    final xmlUrl = v.comprobanteSunatXmlUrl;
    if (xmlUrl != null && xmlUrl.isNotEmpty) return false;
    final enlace = v.comprobanteEnlaceProveedor;
    if (enlace != null && enlace.isNotEmpty) return false;
    final estado = v.comprobanteEstado;
    if (estado == 'ACEPTADO' || estado == 'RECHAZADO' || estado == 'ANULADO') {
      return false;
    }
    return true;
  }

  Future<void> _refrescarManual() async {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;
    await _loadAndGenerate();
  }

  Future<void> _loadAndGenerate() async {
    // En polling subsecuente no resetear `_loading` para no parpadear el UI.
    final esPolling = _pollingAttempts > 0;
    if (!esPolling) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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
    String? telefonoEfectivo;
    try {
      final datasource = locator<VentaRemoteDataSource>();
      // Usar sede del comprobante (emisor) si existe, sino sede de la venta
      final config = await datasource.getConfiguracionSunat(sedeId: venta.comprobanteSedeId ?? venta.sedeId);
      resolucionSunat = config['resolucionSunat'] as String?;
      rucEfectivo = config['ruc'] as String?;
      razonSocialEfectiva = config['razonSocial'] as String?;
      nombreComercialEfectivo = config['nombreComercial'] as String?;
      direccionFiscalEfectiva = config['direccionFiscal'] as String?;
      telefonoEfectivo = config['telefono'] as String?;
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
      final esperando = _esperaSunat(venta);
      setState(() {
        _venta = venta;
        _pdfBytes = pdf;
        _logoBytes = logoBytes;
        _loading = false;
        _esperandoSunat = esperando;
        _rucEfectivo = rucEfectivo;
        _razonSocialEfectiva = razonSocialEfectiva;
        _direccionFiscalEfectiva = direccionFiscalEfectiva;
        _nombreComercialEfectivo = nombreComercialEfectivo;
        _telefonoEfectivo = telefonoEfectivo;
      });

      // Programar siguiente intento si todavía no llegó la respuesta SUNAT.
      // Cuando llega (o estado terminal), cancelamos el timer.
      if (esperando && _pollingAttempts < _maxPollingAttempts) {
        _pollingAttempts++;
        _pollingTimer?.cancel();
        _pollingTimer = Timer(_pollingInterval, () {
          if (mounted) _loadAndGenerate();
        });
      } else {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }

      // Auto-impresión: solo en la primera carga (no en polling SUNAT).
      // No bloquea el flujo: corre en background y si falla muestra
      // snackbar discreto sin afectar la pantalla del ticket.
      if (!esPolling && !_autoPrintIntentado) {
        _autoPrintIntentado = true;
        unawaited(_intentarAutoImprimir(
          empresaNombre: nombreComercialEfectivo ?? empresa.nombre,
          empresaRazonSocial: razonSocialEfectiva,
          empresaRuc: rucEfectivo ?? empresa.ruc,
          empresaDireccion: direccionFiscalEfectiva ?? empresa.direccionFiscal,
          empresaTelefono: telefonoEfectivo ?? empresa.telefono,
          sedeNombre: venta.sedeNombre,
          nombreImpuesto: nombreImpuesto,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error generando PDF: $e';
        _loading = false;
        _esperandoSunat = false;
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
            // Refresh manual: re-consulta la venta y regenera el PDF.
            // Útil cuando el polling expiró sin recibir hash (corte de red,
            // SUNAT lento) o el cajero quiere forzar update.
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _refrescarManual,
              tooltip: 'Refrescar',
            ),
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
        body: Column(
          children: [
            if (_esperandoSunat) _buildBannerEsperandoSunat(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  /// Banner naranja discreto mientras se hace polling esperando que el
  /// proveedor (Syncrofact/Nubefact) entregue la respuesta SUNAT con el
  /// hash y la URL de consulta. Se oculta automáticamente cuando llega.
  Widget _buildBannerEsperandoSunat() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esperando confirmación SUNAT (hash + URL de consulta)...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  /// Si hay impresora principal configurada con autoImprimirVentaRapida=true,
  /// genera los bytes ESC-POS y los manda silenciosamente. UI muestra
  /// snackbar discreto al resultado sin bloquear nada.
  Future<void> _intentarAutoImprimir({
    required String empresaNombre,
    required String? empresaRazonSocial,
    required String? empresaRuc,
    required String? empresaDireccion,
    required String? empresaTelefono,
    required String? sedeNombre,
    required String nombreImpuesto,
  }) async {
    if (_venta == null) return;
    try {
      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (principal == null || !principal.autoImprimirVentaRapida) return;

      final bytes = await TicketVentaEscPosGenerator.generate(
        venta: _venta!,
        empresaNombre: empresaNombre,
        empresaRazonSocial: empresaRazonSocial,
        empresaRuc: empresaRuc,
        empresaDireccion: empresaDireccion,
        empresaTelefono: empresaTelefono,
        sedeNombre: sedeNombre,
        logoEmpresa: _logoBytes,
        // CRÍTICO: respetar ancho real configurado en la impresora.
        // Si default 80 va a una térmica de 58mm, las columnas calculadas
        // (12*ratio sobre 48 chars) no caben y se aplastan a la derecha.
        paperWidth: principal.anchoPapel.mm,
        nombreImpuesto: nombreImpuesto,
      );

      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket impreso en ${principal.nombre}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo imprimir automáticamente en ${principal.nombre}. '
              'Usa el botón de imprimir si la impresora está disponible.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      // Silencioso: la auto-impresión nunca debe romper el flujo de la venta.
    }
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

    // Respetar el ancho de papel de la impresora principal configurada
    // (sino el ESC-POS sale para 80mm aunque la térmica sea de 58mm
    // y las columnas se aplastan a la derecha).
    final principal = await locator<ImpresorasManager>().getPrincipal();
    final paperWidth = principal?.anchoPapel.mm ?? 80;

    final bytes = await TicketVentaEscPosGenerator.generate(
      venta: _venta!,
      // Identidad efectiva: sede > empresa. La sede puede tener
      // direccionFiscalSede/rucSede/razonSocialSede y debe ganar sobre empresa.
      empresaNombre: _nombreComercialEfectivo ?? empresa.nombre,
      empresaRazonSocial: _razonSocialEfectiva,
      empresaRuc: _rucEfectivo ?? empresa.ruc,
      empresaDireccion: _direccionFiscalEfectiva ?? empresa.direccionFiscal,
      empresaTelefono: _telefonoEfectivo ?? empresa.telefono,
      sedeNombre: _venta?.sedeNombre,
      logoEmpresa: _logoBytes,
      paperWidth: paperWidth,
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
