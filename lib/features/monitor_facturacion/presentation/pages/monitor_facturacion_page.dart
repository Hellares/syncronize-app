import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/comprobante_item.dart';
import '../../domain/repositories/monitor_facturacion_repository.dart';
import '../bloc/monitor_facturacion_cubit.dart';
import '../bloc/monitor_facturacion_state.dart';
import '../widgets/sincronizar_series_dialog.dart';
import '../../../facturacion/domain/entities/tipo_nota.dart';
import '../../../facturacion/presentation/widgets/crear_nota_dialog.dart';
import '../../../facturacion/presentation/widgets/anular_comprobante_dialog.dart';

class MonitorFacturacionPage extends StatelessWidget {
  const MonitorFacturacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MonitorFacturacionCubit(locator<MonitorFacturacionRepository>())..cargar(),
      child: const _MonitorView(),
    );
  }
}

class _MonitorView extends StatefulWidget {
  const _MonitorView();

  @override
  State<_MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<_MonitorView> {
  final _searchController = TextEditingController();
  String? _filtroTipo;
  String? _filtroStatus;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Monitor de Facturación',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Configuración de facturación',
              onPressed: () =>
                  context.push('/empresa/configuracion-facturacion'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Actualizar estados SUNAT de pendientes',
              onPressed: _consultarPendientes,
            ),
            IconButton(
              icon: const Icon(Icons.sync, size: 20),
              tooltip: 'Sincronizar series desde proveedor',
              onPressed: _sincronizarSeries,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered, size: 20),
              tooltip: 'Reporte Correlativos',
              onPressed: () => context.push('/empresa/reporte-correlativos'),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: BlocBuilder<MonitorFacturacionCubit, MonitorFacturacionState>(
                builder: (context, state) {
                  if (state is MonitorFacturacionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MonitorFacturacionError) {
                    return Center(child: Text(state.message, style: TextStyle(color: Colors.red.shade400)));
                  }
                  if (state is MonitorFacturacionLoaded) {
                    if (state.comprobantes.isEmpty) {
                      return const Center(child: Text('No hay comprobantes', style: TextStyle(color: Colors.grey)));
                    }
                    return _buildList(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por código, cliente o documento...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        context.read<MonitorFacturacionCubit>().setBusqueda(null);
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 12),
            onSubmitted: (v) => context.read<MonitorFacturacionCubit>().setBusqueda(v.isEmpty ? null : v),
          ),
          const SizedBox(height: 8),
          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', null, _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<MonitorFacturacionCubit>().setFiltroTipo(v);
                }),
                _filterChip('Boletas', 'BOLETA', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<MonitorFacturacionCubit>().setFiltroTipo(v);
                }),
                _filterChip('Facturas', 'FACTURA', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<MonitorFacturacionCubit>().setFiltroTipo(v);
                }),
                _filterChip('N. Crédito', 'NOTA_CREDITO', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<MonitorFacturacionCubit>().setFiltroTipo(v);
                }),
                _filterChip('N. Débito', 'NOTA_DEBITO', _filtroTipo, (v) {
                  setState(() => _filtroTipo = v);
                  context.read<MonitorFacturacionCubit>().setFiltroTipo(v);
                }),
                const SizedBox(width: 12),
                _statusChip('Aceptado', 'ACEPTADO', Colors.green),
                _statusChip('Pendiente', 'PENDIENTE', Colors.amber.shade700),
                _statusChip('Procesando', 'PROCESANDO', Colors.blue),
                _statusChip('Error', 'ERROR_COMUNICACION', Colors.orange),
                _statusChip('Rechazado', 'RECHAZADO', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, String? current, ValueChanged<String?> onTap) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue1 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    final selected = _filtroStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filtroStatus = selected ? null : value);
          context.read<MonitorFacturacionCubit>().setFiltroSunatStatus(selected ? null : value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: selected ? color : Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(MonitorFacturacionLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<MonitorFacturacionCubit>().cargar(page: state.currentPage),
      child: Column(
        children: [
          // Resumen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${state.total} comprobantes',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Pág ${state.currentPage}/${state.totalPages}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.comprobantes.length,
              itemBuilder: (context, i) => _ComprobanteCard(
                item: state.comprobantes[i],
                onReenviar: () => _reenviar(state.comprobantes[i]),
                onNotaEmitida: () => context.read<MonitorFacturacionCubit>().cargar(page: state.currentPage),
              ),
            ),
          ),
          // Paginación
          if (state.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: state.currentPage > 1
                        ? () => context.read<MonitorFacturacionCubit>().cargar(page: state.currentPage - 1)
                        : null,
                  ),
                  Text('${state.currentPage} / ${state.totalPages}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: state.currentPage < state.totalPages
                        ? () => context.read<MonitorFacturacionCubit>().cargar(page: state.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _enviarPendientes,
      backgroundColor: AppColors.blue1,
      icon: const Icon(Icons.send, size: 18, color: Colors.white),
      label: const Text('Enviar pendientes', style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  Future<void> _reenviar(ComprobanteItem item) async {
    try {
      await context.read<MonitorFacturacionCubit>().reenviar(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.codigoGenerado} reenviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sincronizarSeries() async {
    final sedes = _getSedes();
    if (sedes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sedes disponibles')),
      );
      return;
    }

    String? sedeId;
    if (sedes.length == 1) {
      sedeId = sedes.first.id;
    } else {
      sedeId = await _elegirSede(sedes);
    }
    if (sedeId == null || !mounted) return;

    final aplicado = await showSincronizarSeriesDialog(context, sedeId: sedeId);
    if (aplicado == true && mounted) {
      await context.read<MonitorFacturacionCubit>().cargar();
    }
  }

  List<Sede> _getSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) return state.context.sedes;
    return [];
  }

  Future<String?> _elegirSede(List<Sede> sedes) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.store_mall_directory, size: 18, color: AppColors.blue1),
                      SizedBox(width: 8),
                      Text('Selecciona una sede',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sedes.length,
                    itemBuilder: (_, i) {
                      final s = sedes[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, size: 18),
                        title: Text(s.nombre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text(s.codigo, style: const TextStyle(fontSize: 10)),
                        onTap: () => Navigator.of(ctx).pop(s.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enviarPendientes() async {
    final result = await context.read<MonitorFacturacionCubit>().enviarPendientes();
    if (mounted) {
      final data = result is Success ? (result as Success).data : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          data != null
              ? 'Enviados: ${data['enviados']}, Errores: ${data['errores']}'
              : 'Error al enviar pendientes',
        )),
      );
    }
  }

  Future<void> _consultarPendientes() async {
    final cubit = context.read<MonitorFacturacionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Consultando estados en el proveedor...'), duration: Duration(seconds: 2)),
    );
    final result = await cubit.consultarPendientes();
    if (!mounted) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final total = data['total'] ?? 0;
      final procesados = data['procesados'] ?? 0;
      final truncado = data['truncado'] == true;
      final pendientesRestantes = data['pendientesRestantes'] ?? 0;
      final actualizados = data['actualizados'] ?? 0;
      final aunProcesando = data['aunProcesando'] ?? 0;
      final noEncontrados = data['noEncontrados'] ?? 0;
      final errores = (data['errores'] as List?)?.length ?? 0;

      final String mensaje;
      if (total == 0) {
        mensaje = 'No hay comprobantes en PROCESANDO';
      } else if (truncado) {
        mensaje = '✓ Procesé $procesados de $total (restan $pendientesRestantes). '
            'Actualizados: $actualizados · Aún proc: $aunProcesando · Err: $errores. '
            'Presiona de nuevo para continuar.';
      } else {
        mensaje = '✓ Actualizados: $actualizados · Aún procesando: $aunProcesando · No encontrados: $noEncontrados · Errores: $errores';
      }

      messenger.showSnackBar(SnackBar(
        content: Text(mensaje),
        duration: Duration(seconds: truncado ? 6 : 4),
        backgroundColor: truncado ? Colors.amber[700] : null,
      ));
      await cubit.cargar();
    } else if (result is Error<Map<String, dynamic>>) {
      messenger.showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.red[700]));
    }
  }
}

// ── Card individual de comprobante ──

class _ComprobanteCard extends StatelessWidget {
  final ComprobanteItem item;
  final VoidCallback onReenviar;
  final VoidCallback onNotaEmitida;

  const _ComprobanteCard({
    required this.item,
    required this.onReenviar,
    required this.onNotaEmitida,
  });

  bool get _puedeEmitirNota =>
      item.esAceptado &&
      !item.anulado &&
      !item.proveedorArchivado &&
      item.sedeId != null &&
      (item.tipoComprobante == 'FACTURA' || item.tipoComprobante == 'BOLETA');

  /// Anulación oficial:
  ///  - FACTURA / NC-FC* / ND-FD* → CDB (RA), plazo 7 días.
  ///  - BOLETA                    → RC (Resumen Diario), plazo 3 días.
  /// NC-BC* / ND-BD* todavía no se soportan desde el app.
  bool get _puedeAnularConCdb {
    if (!item.esAceptado || item.anulado || item.proveedorArchivado) return false;
    if (item.sedeId == null) return false;
    final dias = DateTime.now().difference(item.fechaEmision).inDays;
    if (item.tipoComprobante == 'FACTURA') return dias <= 7;
    if (item.tipoComprobante == 'BOLETA') return dias <= 3;
    if (item.tipoComprobante == 'NOTA_CREDITO' || item.tipoComprobante == 'NOTA_DEBITO') {
      return item.serie.startsWith('F') && dias <= 7;
    }
    return false;
  }

  Future<void> _emitirNota(BuildContext context, TipoNota tipo) async {
    final result = await CrearNotaDialog.show(
      context,
      comprobanteOrigenId: item.id,
      sedeId: item.sedeId!,
      tipoNota: tipo,
      comprobanteCodigo: item.codigoGenerado,
      comprobanteTotal: item.total,
      moneda: item.moneda,
    );
    if (result != null) onNotaEmitida();
  }

  Future<void> _anular(BuildContext context) async {
    final result = await AnularComprobanteDialog.show(
      context,
      comprobanteId: item.id,
      comprobanteCodigo: item.codigoGenerado,
      tipoComprobante: item.tipoComprobante,
      fechaEmision: item.fechaEmision,
      sedeId: item.sedeId!,
      total: item.total,
      moneda: item.moneda,
    );
    if (result != null) onNotaEmitida();
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: _borderColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: tipo + código + status
            Row(
              children: [
                _tipoChip(),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(item.codigoGenerado,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                if (item.proveedorLabel != null) ...[
                  _proveedorChip(),
                  const SizedBox(width: 4),
                ],
                _sunatStatusChip(),
              ],
            ),
            const SizedBox(height: 6),
            // Cliente + documento
            Row(
              children: [
                Expanded(
                  child: Text(item.nombreCliente,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis),
                ),
                if (item.numeroDocumento != null)
                  Text(item.numeroDocumento!,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 4),
            // Fecha + total
            Row(
              children: [
                Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(DateFormatter.formatDateTime(item.fechaEmision),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                const Spacer(),
                Text('${item.simboloMoneda} ${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            // Error
            if (item.errorProveedor != null && item.esPendiente) ...[
              const SizedBox(height: 4),
              Text(_traducirError(item.errorProveedor!),
                  style: TextStyle(fontSize: 9, color: Colors.red.shade400),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            // Motivo nota
            if (item.motivoNota != null) ...[
              const SizedBox(height: 4),
              Text('Motivo: ${item.motivoNota}',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
            // Acciones
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (item.esPendiente && !item.proveedorArchivado)
                  _actionButton(Icons.send, 'Reenviar', Colors.blue, onReenviar),
                if (item.esPendiente && item.proveedorArchivado)
                  _actionButtonDisabled(
                    Icons.send,
                    'Archivado',
                    'El proveedor ${item.proveedorLabel} ya no acepta reenvíos. Emite una Nota de Crédito con el proveedor activo.',
                  ),
                if (item.sunatPdfUrl != null)
                  _actionButton(Icons.picture_as_pdf, 'PDF', Colors.red.shade400, () => _abrirUrl(item.sunatPdfUrl!)),
                if (item.enlaceProveedor != null)
                  _actionButton(Icons.open_in_new, 'Ver', Colors.grey.shade600, () => _abrirUrl(item.enlaceProveedor!)),
                if (_puedeEmitirNota)
                  _actionButton(Icons.note_add_outlined, 'N. Crédito', Colors.orange,
                      () => _emitirNota(context, TipoNota.notaCredito)),
                if (_puedeEmitirNota)
                  _actionButton(Icons.add_circle_outline, 'N. Débito', Colors.purple,
                      () => _emitirNota(context, TipoNota.notaDebito)),
                if (_puedeAnularConCdb)
                  _actionButton(Icons.cancel_outlined, 'Anular',
                      Colors.red, () => _anular(context)),
                if (item.ventaId != null)
                  _actionButton(Icons.receipt, 'Venta', Colors.indigo, () {
                    // Navigator.pushNamed(context, '/empresa/ventas/${item.ventaId}');
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _borderColor {
    if (item.anulado) return Colors.red.shade200;
    if (item.esAceptado) return Colors.green.shade200;
    if (item.esRechazado) return Colors.red.shade200;
    if (item.esPendiente) return Colors.amber.shade200;
    return AppColors.blueborder;
  }

  Widget _tipoChip() {
    Color color;
    switch (item.tipoComprobante) {
      case 'FACTURA': color = Colors.indigo; break;
      case 'BOLETA': color = Colors.teal; break;
      case 'NOTA_CREDITO': color = Colors.orange; break;
      case 'NOTA_DEBITO': color = Colors.purple; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(item.tipoLabel,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sunatStatusChip() {
    Color color;
    String label;
    if (item.anulado) {
      color = Colors.red;
      label = 'ANULADO';
    } else {
      switch (item.sunatStatus) {
        case 'ACEPTADO': color = Colors.green; label = 'ACEPTADO'; break;
        case 'RECHAZADO': color = Colors.red; label = 'RECHAZADO'; break;
        case 'PROCESANDO': color = Colors.blue; label = 'PROCESANDO'; break;
        case 'ERROR_COMUNICACION': color = Colors.orange; label = 'ERROR COM.'; break;
        default:
          // Diferenciar PENDIENTE: sin enviar vs con intentos fallidos
          if (item.intentosEnvio == 0) {
            color = Colors.amber.shade700; label = 'SIN ENVIAR';
          } else {
            color = Colors.orange; label = 'REINTENTO';
          }
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _actionButtonDisabled(IconData icon, String label, String tooltip) {
    final color = Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _proveedorChip() {
    final label = item.proveedorLabel!;
    final archivado = item.proveedorArchivado;
    final color = archivado ? Colors.grey.shade600 : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: archivado
            ? Border.all(color: color.withValues(alpha: 0.4), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (archivado) ...[
            Icon(Icons.archive_outlined, size: 9, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _traducirError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('token') || lower.contains('unauthorized') || lower.contains('403')) {
      return 'Credenciales del proveedor vencidas o inválidas';
    }
    if (lower.contains('ya existe')) {
      return 'Comprobante ya registrado en SUNAT';
    }
    if (lower.contains('serie') || lower.contains('numero')) {
      return 'Error en serie/correlativo, verifique configuración';
    }
    if (lower.contains('ruc') || lower.contains('documento')) {
      return 'Verifique RUC/DNI del cliente';
    }
    if (lower.contains('timeout') || lower.contains('no respondió') || lower.contains('econnrefused')) {
      return 'Proveedor no respondió, reintente más tarde';
    }
    if (lower.contains('certificado') || lower.contains('ssl')) {
      return 'Error de certificado, contacte soporte';
    }
    return error.length > 80 ? '${error.substring(0, 80)}...' : error;
  }
}
