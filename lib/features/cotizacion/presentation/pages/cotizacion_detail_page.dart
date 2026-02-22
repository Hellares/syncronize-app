import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
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
        child: Scaffold(
          appBar: AppBar(
            title: Text(_cotizacion?.codigo ?? 'Cotizacion'),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadCotizacion,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final cot = _cotizacion!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: _loadCotizacion,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cot.codigo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CotizacionEstadoChip(estado: cot.estado),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow('Fecha emision', dateFormat.format(cot.fechaEmision)),
                  if (cot.fechaVencimiento != null)
                    _InfoRow('Vencimiento',
                        dateFormat.format(cot.fechaVencimiento!)),
                  _InfoRow('Moneda', cot.moneda),
                  if (cot.sedeNombre != null)
                    _InfoRow('Sede', cot.sedeNombre!),
                  if (cot.vendedorNombre != null)
                    _InfoRow('Vendedor', cot.vendedorNombre!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Datos del cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  _InfoRow('Nombre', cot.nombreCliente),
                  if (cot.documentoCliente != null)
                    _InfoRow('Documento', cot.documentoCliente!),
                  if (cot.emailCliente != null)
                    _InfoRow('Email', cot.emailCliente!),
                  if (cot.telefonoCliente != null)
                    _InfoRow('Telefono', cot.telefonoCliente!),
                  if (cot.direccionCliente != null)
                    _InfoRow('Direccion', cot.direccionCliente!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Detalles / Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items (${cot.detalles?.length ?? 0})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (cot.detalles != null)
                    ...cot.detalles!.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.descripcion,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      '${d.cantidad} x ${cot.moneda} ${d.precioUnitario.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${cot.moneda} ${d.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Totales
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TotalRow('Subtotal',
                      '${cot.moneda} ${cot.subtotal.toStringAsFixed(2)}'),
                  if (cot.descuento > 0)
                    _TotalRow('Descuento',
                        '-${cot.moneda} ${cot.descuento.toStringAsFixed(2)}'),
                  _TotalRow(_getNombreImpuesto(),
                      '${cot.moneda} ${cot.impuestos.toStringAsFixed(2)}'),
                  const Divider(),
                  _TotalRow(
                    'Total',
                    '${cot.moneda} ${cot.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Observaciones
          if (cot.observaciones != null || cot.condiciones != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cot.observaciones != null) ...[
                      const Text('Observaciones',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(cot.observaciones!, style: const TextStyle(fontSize: 13)),
                    ],
                    if (cot.condiciones != null) ...[
                      const SizedBox(height: 12),
                      const Text('Condiciones',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(cot.condiciones!, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(BuildContext context) {
    if (_cotizacion == null) return null;

    final cot = _cotizacion!;
    final actions = <Widget>[];

    // Acciones segun estado
    if (cot.estado == EstadoCotizacion.borrador) {
      actions.add(FilledButton(
        onPressed: () {
          context.read<CotizacionFormCubit>().cambiarEstado(
                cot.id,
                EstadoCotizacion.pendiente,
              );
        },
        child: const Text('Enviar a Pendiente'),
      ));
    } else if (cot.estado == EstadoCotizacion.pendiente) {
      actions.addAll([
        OutlinedButton(
          onPressed: () {
            context.read<CotizacionFormCubit>().cambiarEstado(
                  cot.id,
                  EstadoCotizacion.rechazada,
                );
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Rechazar'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            context.read<CotizacionFormCubit>().cambiarEstado(
                  cot.id,
                  EstadoCotizacion.aprobada,
                );
          },
          child: const Text('Aprobar'),
        ),
      ]);
    }

    if (actions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
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

  /// Muestra un dialog para elegir el tipo de PDF
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
              // Selector de formato de papel
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
                subtitle: const Text('Incluye precios unitarios, descuentos y subtotales'),
                onTap: () {
                  Navigator.pop(ctx);
                  _generarDocumentoPDF(cotizacion,
                      modoCliente: false, formato: selectedFormato);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('PDF para Cliente'),
                subtitle: const Text('Solo muestra descripcion, cantidad y total final'),
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
      {bool modoCliente = false, FormatoPapel formato = FormatoPapel.A4}) async {
    final empresaState = context.read<EmpresaContextCubit>().state;

    if (empresaState is! EmpresaContextLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la empresa')),
      );
      return;
    }

    final empresa = empresaState.context.empresa;

    // Leer configuracion fiscal
    String nombreImpuesto = 'IGV';
    double porcentajeImpuesto = 18.0;
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      nombreImpuesto = configState.configuracion.nombreImpuesto;
      porcentajeImpuesto = configState.configuracion.impuestoDefaultPorcentaje;
    }

    // Cargar configuracion de documentos para COTIZACION con formato elegido
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
    } catch (_) {
      // Si falla, se usaran los defaults del generador
    }

    // Descargar logo si existe URL
    Uint8List? logoBytes;
    final logoUrl = documentConfig?.configuracion.logoUrl ?? empresa.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (_) {
        // Si falla la descarga, se genera sin logo
      }
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
        title: const Text('Eliminar cotizacion'),
        content: const Text(
            'Esta accion no se puede deshacer. ¿Desea continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<CotizacionFormCubit>()
                  .eliminarCotizacion(_cotizacion!.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
