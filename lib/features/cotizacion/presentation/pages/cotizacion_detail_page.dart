import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';
import '../../../configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/usecases/get_cotizacion_usecase.dart';
import '../bloc/cotizacion_form/cotizacion_form_cubit.dart';
import '../bloc/cotizacion_form/cotizacion_form_state.dart';
import '../widgets/cotizacion_estado_chip.dart';
import 'documento_cotizacion_preview_page.dart';

class CotizacionDetailPage extends StatefulWidget {
  final String cotizacionId;

  const CotizacionDetailPage({
    super.key,
    required this.cotizacionId,
  });

  @override
  State<CotizacionDetailPage> createState() => _CotizacionDetailPageState();
}

class _CotizacionDetailPageState extends State<CotizacionDetailPage> {
  Cotizacion? _cotizacion;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCotizacion();
  }

  Future<void> _loadCotizacion() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await locator<GetCotizacionUseCase>()(
      cotizacionId: widget.cotizacionId,
    );

    if (result is Success<Cotizacion>) {
      setState(() {
        _cotizacion = result.data;
        _loading = false;
      });
    } else if (result is Error<Cotizacion>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CotizacionFormCubit>(),
      child: BlocListener<CotizacionFormCubit, CotizacionFormState>(
        listener: (context, state) {
          if (state is CotizacionEstadoUpdated) {
            setState(() => _cotizacion = state.cotizacion);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Estado actualizado')),
            );
            _loadCotizacion();
          }
          if (state is CotizacionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadCotizacion();
          }
          if (state is CotizacionFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: GradientBackground(
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              appBar: SmartAppBar(
                title: _cotizacion?.codigo ?? 'Cotizacion',
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                actions: [
                  if (_cotizacion != null) ...[
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => _mostrarOpcionesPDF(_cotizacion!),
                      tooltip: 'Generar PDF',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'pdf_interno',
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf),
                            title: Text('PDF Interno'),
                            subtitle: Text('Con todos los precios',
                                style: TextStyle(fontSize: 11)),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pdf_cliente',
                          child: ListTile(
                            leading: Icon(Icons.send),
                            title: Text('PDF Cliente'),
                            subtitle: Text('Solo muestra el total',
                                style: TextStyle(fontSize: 11)),
                            dense: true,
                          ),
                        ),
                        const PopupMenuDivider(),
                        if (_cotizacion!.esEditable)
                          const PopupMenuItem(
                            value: 'editar',
                            child: ListTile(
                              leading: Icon(Icons.edit, color: AppColors.blue1),
                              title: Text('Editar'),
                              dense: true,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'duplicar',
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Duplicar'),
                            dense: true,
                          ),
                        ),
                        if (_cotizacion!.esEditable)
                          const PopupMenuItem(
                            value: 'eliminar',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                              dense: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              body: _buildBody(),
              bottomNavigationBar: _buildBottomActions(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadCotizacion,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cot = _cotizacion!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: _loadCotizacion,
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderSection(cot, dateFormat),
          const SizedBox(height: 12),
          _buildClienteSection(cot),
          const SizedBox(height: 12),
          _buildItemsSection(cot),
          const SizedBox(height: 12),
          _buildTotalesSection(cot),
          if (cot.observaciones != null || cot.condiciones != null) ...[
            const SizedBox(height: 12),
            _buildNotasSection(cot),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Header ───

  Widget _buildHeaderSection(Cotizacion cot, DateFormat dateFormat) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: AppColors.blue1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(cot.codigo, fontSize: 15),
                      if (cot.nombre != null)
                        Text(
                          cot.nombre!,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                CotizacionEstadoChip(estado: cot.estado),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
                Icons.calendar_today, 'Emision', dateFormat.format(cot.fechaEmision)),
            if (cot.fechaVencimiento != null)
              _buildDetailRow(Icons.event, 'Vencimiento',
                  dateFormat.format(cot.fechaVencimiento!)),
            _buildDetailRow(
                Icons.monetization_on_outlined, 'Moneda', cot.moneda),
            if (cot.sedeNombre != null)
              _buildDetailRow(Icons.store_outlined, 'Sede', cot.sedeNombre!),
            if (cot.vendedorNombre != null)
              _buildDetailRow(
                  Icons.person_outline, 'Vendedor', cot.vendedorNombre!),
          ],
        ),
      ),
    );
  }

  // ─── Cliente ───

  Widget _buildClienteSection(Cotizacion cot) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.person_outline, 'CLIENTE'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'Nombre', cot.nombreCliente),
            if (cot.documentoCliente != null)
              _buildDetailRow(
                  Icons.badge_outlined, 'Documento', cot.documentoCliente!),
            if (cot.emailCliente != null)
              _buildDetailRow(
                  Icons.email_outlined, 'Email', cot.emailCliente!),
            if (cot.telefonoCliente != null)
              _buildDetailRow(
                  Icons.phone_outlined, 'Telefono', cot.telefonoCliente!),
            if (cot.direccionCliente != null)
              _buildDetailRow(Icons.location_on_outlined, 'Direccion',
                  cot.direccionCliente!),
          ],
        ),
      ),
    );
  }

  // ─── Items ───

  Widget _buildItemsSection(Cotizacion cot) {
    final detalles = cot.detalles ?? [];

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                Icons.shopping_cart_outlined, 'ITEMS (${detalles.length})'),
            const SizedBox(height: 12),
            ...detalles.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                        height: 16,
                        color: AppColors.blueborder.withValues(alpha: 0.4)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.bluechip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.descripcion,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.cantidad} x ${cot.moneda} ${d.precioUnitario.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppSubtitle(
                        '${cot.moneda} ${d.total.toStringAsFixed(2)}',
                        fontSize: 12,
                        color: AppColors.blue1,
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Totales ───

  Widget _buildTotalesSection(Cotizacion cot) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal',
                '${cot.moneda} ${cot.subtotal.toStringAsFixed(2)}'),
            if (cot.descuento > 0) ...[
              const SizedBox(height: 4),
              _buildTotalRow('Descuento',
                  '-${cot.moneda} ${cot.descuento.toStringAsFixed(2)}',
                  color: Colors.red),
            ],
            const SizedBox(height: 4),
            _buildTotalRow(_getNombreImpuesto(),
                '${cot.moneda} ${cot.impuestos.toStringAsFixed(2)}'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                  height: 1,
                  color: AppColors.blueborder.withValues(alpha: 0.5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppSubtitle('TOTAL', fontSize: 14),
                AppSubtitle(
                  '${cot.moneda} ${cot.total.toStringAsFixed(2)}',
                  fontSize: 16,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Notas ───

  Widget _buildNotasSection(Cotizacion cot) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cot.observaciones != null) ...[
              _buildSectionHeader(Icons.notes, 'OBSERVACIONES'),
              const SizedBox(height: 8),
              Text(
                cot.observaciones!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            if (cot.observaciones != null && cot.condiciones != null)
              const SizedBox(height: 14),
            if (cot.condiciones != null) ...[
              _buildSectionHeader(Icons.gavel_outlined, 'CONDICIONES'),
              const SizedBox(height: 8),
              Text(
                cot.condiciones!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Bottom Actions ───

  Widget? _buildBottomActions(BuildContext context) {
    if (_cotizacion == null) return null;

    final cot = _cotizacion!;
    final actions = <Widget>[];

    if (cot.estado == EstadoCotizacion.borrador) {
      actions.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: _navigateToEdit,
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Editar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue1,
            side: const BorderSide(color: AppColors.blue1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ));
      actions.add(const SizedBox(width: 12));
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<CotizacionFormCubit>().cambiarEstado(
                  cot.id,
                  EstadoCotizacion.pendiente,
                );
          },
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Enviar a Pendiente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ));
    } else if (cot.estado == EstadoCotizacion.aprobada) {
      actions.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Convertir a Venta',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                content: const Text(
                  'Se creara una venta con los datos de esta cotizacion. ¿Desea continuar?',
                  style: TextStyle(fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(
                        '/empresa/ventas/desde-cotizacion/${cot.id}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Convertir'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.point_of_sale, size: 18),
          label: const Text('Convertir a Venta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ));
    } else if (cot.estado == EstadoCotizacion.pendiente) {
      actions.addAll([
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<CotizacionFormCubit>().cambiarEstado(
                    cot.id,
                    EstadoCotizacion.rechazada,
                  );
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<CotizacionFormCubit>().cambiarEstado(
                    cot.id,
                    EstadoCotizacion.aprobada,
                  );
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ]);
    }

    if (actions.isEmpty) return null;

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
      child: Row(children: actions),
    );
  }

  // ─── Helpers de UI ───

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue1),
        const SizedBox(width: 8),
        AppSubtitle(title, fontSize: 12),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Acciones ───

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'editar':
        _navigateToEdit();
        break;
      case 'pdf_interno':
        _generarDocumentoPDF(_cotizacion!, modoCliente: false);
        break;
      case 'pdf_cliente':
        _generarDocumentoPDF(_cotizacion!, modoCliente: true);
        break;
      case 'duplicar':
        context
            .read<CotizacionFormCubit>()
            .duplicarCotizacion(_cotizacion!.id);
        break;
      case 'eliminar':
        _showDeleteConfirmation(context);
        break;
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await context.push<bool>(
      '/empresa/cotizaciones/${_cotizacion!.id}/editar',
    );
    if (result == true) {
      _loadCotizacion();
    }
  }

  void _mostrarOpcionesPDF(Cotizacion cotizacion) {
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
                          .map((f) => ButtonSegment(
                                value: f,
                                label: Text(f.label),
                              ))
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
                title: const Text('PDF Interno'),
                subtitle: const Text(
                    'Incluye precios unitarios, descuentos y subtotales'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarDocumentoPDF(cotizacion,
                      modoCliente: false, formato: selectedFormato);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('PDF para Cliente'),
                subtitle: const Text(
                    'Solo muestra descripcion, cantidad y total final'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarDocumentoPDF(cotizacion,
                      modoCliente: true, formato: selectedFormato);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarDocumentoPDF(Cotizacion cotizacion,
      {bool modoCliente = false,
      FormatoPapel formato = FormatoPapel.A4}) async {
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
      porcentajeImpuesto =
          configState.configuracion.impuestoDefaultPorcentaje;
    }

    ConfiguracionDocumentoCompleta? documentConfig;
    try {
      final result = await locator<GetConfiguracionCompletaUseCase>()(
        tipo: 'COTIZACION',
        formato: formato.apiValue,
        sedeId: cotizacion.sedeId,
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
        builder: (context) => DocumentoCotizacionPreviewPage(
          cotizacion: cotizacion,
          empresaNombre: empresa.nombre,
          empresaRuc: empresa.ruc,
          modoCliente: modoCliente,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
          documentConfig: documentConfig,
          formatoPapel: formato,
          logoEmpresa: logoBytes,
        ),
      ),
    );
  }

  String _getNombreImpuesto() {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      return configState.configuracion.nombreImpuesto;
    }
    return 'IGV';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar cotizacion',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'Esta accion no se puede deshacer. ¿Desea continuar?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<CotizacionFormCubit>()
                  .eliminarCotizacion(_cotizacion!.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
