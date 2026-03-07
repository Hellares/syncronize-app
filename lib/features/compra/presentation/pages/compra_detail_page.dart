import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';
import '../../../configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart';
import '../../domain/entities/compra.dart';
import '../../domain/usecases/get_compra_usecase.dart';
import '../../domain/usecases/confirmar_compra_usecase.dart';
import '../../domain/usecases/anular_compra_usecase.dart';
import '../../domain/usecases/eliminar_compra_usecase.dart';
import 'documento_compra_preview_page.dart';

class CompraDetailPage extends StatefulWidget {
  final String empresaId;
  final Compra compra;

  const CompraDetailPage({
    super.key,
    required this.empresaId,
    required this.compra,
  });

  @override
  State<CompraDetailPage> createState() => _CompraDetailPageState();
}

class _CompraDetailPageState extends State<CompraDetailPage> {
  late Compra _compra;
  bool _isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    _compra = widget.compra;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final result = await locator<GetCompraUseCase>()(
      empresaId: widget.empresaId,
      id: widget.compra.id,
    );

    if (!mounted) return;

    if (result is Success<Compra>) {
      setState(() {
        _compra = result.data;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
  }

  IconData _estadoIcon() {
    switch (_compra.estado) {
      case EstadoCompra.BORRADOR:
        return Icons.edit_note;
      case EstadoCompra.CONFIRMADA:
        return Icons.check_circle;
      case EstadoCompra.ANULADA:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_compra.codigo),
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _mostrarOpcionesPDF(),
            tooltip: 'Generar PDF',
          ),
          if (_compra.puedeConfirmar ||
              _compra.puedeAnular ||
              _compra.esBorrador)
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (context) => [
                if (_compra.puedeConfirmar)
                  const PopupMenuItem(
                    value: 'confirmar',
                    child: ListTile(
                      leading:
                          Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Confirmar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (_compra.puedeAnular)
                  const PopupMenuItem(
                    value: 'anular',
                    child: ListTile(
                      leading: Icon(Icons.cancel, color: Colors.red),
                      title: Text('Anular'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (_compra.esBorrador)
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildProveedorCard(),
                    const SizedBox(height: 12),
                    _buildInfoCard(),
                    const SizedBox(height: 12),
                    _buildMontosCard(),
                    const SizedBox(height: 12),
                    _buildDetallesSection(),
                    if (_compra.observaciones != null &&
                        _compra.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNotasCard(
                        'Observaciones',
                        _compra.observaciones!,
                        Icons.notes,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.blue1,
            AppColors.blue1.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              // Estado chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_estadoIcon(), size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _compra.estadoTexto,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Total
              Text(
                '${_compra.moneda} ${_compra.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Info chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildHeaderChip(
                    Icons.calendar_today,
                    DateFormatter.formatDate(_compra.fechaRecepcion),
                  ),
                  if (_compra.sedeNombre.isNotEmpty)
                    _buildHeaderChip(Icons.store, _compra.sedeNombre),
                  if (_compra.ordenCompraCodigo != null)
                    _buildHeaderChip(
                        Icons.receipt_long, 'OC: ${_compra.ordenCompraCodigo}'),
                  if (_compra.moneda != 'PEN')
                    _buildHeaderChip(Icons.currency_exchange, _compra.moneda),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorCard() {
    // Documento del proveedor (factura/boleta)
    String? docProveedor;
    if (_compra.tipoDocumentoProveedor != null) {
      final serie = _compra.serieDocumentoProveedor ?? '';
      final numero = _compra.numeroDocumentoProveedor ?? '';
      docProveedor =
          '${_compra.tipoDocumentoProveedor} $serie-$numero'.trim();
    }

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business,
                    size: 18, color: AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText('PROVEEDOR',
                        size: 10, color: AppColors.blueGrey),
                    const SizedBox(height: 2),
                    Text(
                      _compra.nombreProveedor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_compra.documentoProveedor != null || docProveedor != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_compra.documentoProveedor != null &&
                    _compra.documentoProveedor!.isNotEmpty)
                  _buildMiniInfo(
                      Icons.badge_outlined, _compra.documentoProveedor!),
                if (docProveedor != null)
                  _buildMiniInfo(Icons.description_outlined, docProveedor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.blueGrey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.blueGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'INFORMACION'),
          const SizedBox(height: 12),
          _buildInfoRow('Fecha Recepcion',
              DateFormatter.formatDate(_compra.fechaRecepcion)),
          _buildInfoRow('Moneda', _compra.moneda),
          if (_compra.sedeNombre.isNotEmpty)
            _buildInfoRow('Sede', _compra.sedeNombre),
          if (_compra.terminosPago != null &&
              _compra.terminosPago!.isNotEmpty)
            _buildInfoRow('Terminos de Pago', _compra.terminosPago!),
          if (_compra.diasCredito != null)
            _buildInfoRow('Dias Credito', '${_compra.diasCredito} dias'),
          if (_compra.fechaVencimientoPago != null)
            _buildInfoRow('Venc. Pago',
                DateFormatter.formatDate(_compra.fechaVencimientoPago!)),
          if (_compra.confirmadoEn != null)
            _buildInfoRow(
                'Confirmada', DateFormatter.formatDateTime(_compra.confirmadoEn!)),
        ],
      ),
    );
  }

  Widget _buildMontosCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.receipt_long, 'RESUMEN DE MONTOS'),
          const SizedBox(height: 12),
          _buildMontoRow('Subtotal',
              '${_compra.moneda} ${_compra.subtotal.toStringAsFixed(2)}'),
          if (_compra.descuento > 0)
            _buildMontoRow(
              'Descuento',
              '- ${_compra.moneda} ${_compra.descuento.toStringAsFixed(2)}',
              valueColor: Colors.red.shade600,
            ),
          _buildMontoRow('Impuestos (IGV)',
              '${_compra.moneda} ${_compra.impuestos.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
              Text(
                '${_compra.moneda} ${_compra.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesSection() {
    if (_isLoadingDetail) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final detalles = _compra.detalles;
    if (detalles == null || detalles.isEmpty) {
      return GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.inventory_2_outlined, 'PRODUCTOS'),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Sin productos',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.blue1),
              const SizedBox(width: 6),
              AppSubtitle('PRODUCTOS (${detalles.length})',
                  fontSize: 11, color: AppColors.blue3),
            ],
          ),
        ),
        ...detalles.map((d) => _buildProductoItem(d)),
      ],
    );
  }

  Widget _buildProductoItem(CompraDetalle d) {
    final loteCodigo = d.lote?['codigo'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blueborder.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y total
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.category_outlined,
                      size: 16, color: AppColors.blue1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.nombreProducto,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.cantidad} x ${_compra.moneda} ${d.precioUnitario.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_compra.moneda} ${d.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
            // Lote y descuento chips
            if (loteCodigo != null || d.descuento > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (loteCodigo != null)
                    InfoChip(
                      text: loteCodigo,
                      icon: Icons.layers_outlined,
                      textColor: AppColors.blue1,
                      backgroundColor: AppColors.bluechip,
                      borderRadius: 4,
                      fontSize: 10,
                    ),
                  if (d.descuento > 0)
                    InfoChip(
                      text:
                          'Desc: ${_compra.moneda} ${d.descuento.toStringAsFixed(2)}',
                      icon: Icons.discount_outlined,
                      textColor: Colors.red.shade600,
                      backgroundColor: Colors.red.shade50,
                      borderRadius: 4,
                      fontSize: 10,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotasCard(String title, String content, IconData icon) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.none,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon, title.toUpperCase()),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
                fontSize: 13, color: AppColors.blueGrey, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 6),
        AppSubtitle(title, fontSize: 11, color: AppColors.blue3),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- PDF ---

  void _mostrarOpcionesPDF() {
    FormatoPapel selectedFormato = FormatoPapel.A4;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Generar PDF',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato de papel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<FormatoPapel>(
                      segments: FormatoPapel.values
                          .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                          .toList(),
                      selected: {selectedFormato},
                      onSelectionChanged: (v) {
                        setModalState(() => selectedFormato = v.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generar documento'),
                subtitle: const Text('PDF con todos los detalles de la compra'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarDocumentoPDF(formato: selectedFormato);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarDocumentoPDF({FormatoPapel formato = FormatoPapel.A4}) async {
    final empresaState = context.read<EmpresaContextCubit>().state;

    if (empresaState is! EmpresaContextLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la empresa')),
      );
      return;
    }

    final empresa = empresaState.context.empresa;

    String nombreImpuesto = 'IGV';
    double porcentajeImpuesto = 18.0;
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      nombreImpuesto = configState.configuracion.nombreImpuesto;
      porcentajeImpuesto = configState.configuracion.impuestoDefaultPorcentaje;
    }

    ConfiguracionDocumentoCompleta? documentConfig;
    try {
      final result = await locator<GetConfiguracionCompletaUseCase>()(
        tipo: 'COMPRA',
        formato: formato.apiValue,
        sedeId: _compra.sedeId,
      );
      if (result is Success<ConfiguracionDocumentoCompleta>) {
        documentConfig = result.data;
      }
    } catch (_) {}

    Uint8List? logoBytes;
    final logoUrl = documentConfig?.configuracion.logoUrl ?? empresa.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentoCompraPreviewPage(
          compra: _compra,
          empresaNombre: empresa.nombre,
          empresaRuc: empresa.ruc,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
          documentConfig: documentConfig,
          formatoPapel: formato,
          logoEmpresa: logoBytes,
        ),
      ),
    );
  }

  // --- Acciones ---

  void _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'confirmar':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar compra'),
            content: const Text(
                'Al confirmar, se actualizara el stock y se crearan los lotes correspondientes. Continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<ConfirmarCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
          );
          if (result is Success<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra confirmada - Stock actualizado'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (result is Error<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'anular':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Anular compra'),
            content: const Text(
                'Se revertiran los cambios de stock y los lotes creados. Continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Si, anular'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<AnularCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
          );
          if (result is Success<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra anulada'),
                backgroundColor: Colors.orange,
              ),
            );
            context.pop(true);
          } else if (result is Error<Compra> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'eliminar':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar compra'),
            content: const Text(
                'Esta seguro de eliminar esta compra? Esta accion no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Si, eliminar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await locator<EliminarCompraUseCase>()(
            empresaId: widget.empresaId,
            id: _compra.id,
          );
          if (result is Success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compra eliminada'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (result is Error<void> && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }
}
