import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/serie_correlativo.dart';
import '../../domain/repositories/monitor_facturacion_repository.dart';
import '../bloc/reporte_correlativos_cubit.dart';

class ReporteCorrelativosPage extends StatelessWidget {
  const ReporteCorrelativosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReporteCorrelativosCubit(locator<MonitorFacturacionRepository>()),
      child: const _ReporteView(),
    );
  }
}

class _ReporteView extends StatefulWidget {
  const _ReporteView();

  @override
  State<_ReporteView> createState() => _ReporteViewState();
}

class _ReporteViewState extends State<_ReporteView> {
  String? _sedeId;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  String _fmtApi(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<Sede> _getSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) return state.context.sedes;
    return [];
  }

  void _onSedeChanged(String? sedeId) {
    setState(() {
      _sedeId = sedeId;
      _fechaDesde = null;
      _fechaHasta = null;
    });
    final cubit = context.read<ReporteCorrelativosCubit>();
    cubit.setSedeId(sedeId);
  }

  Future<void> _pickFechaDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaDesde = picked);
      _aplicarFechas();
    }
  }

  Future<void> _pickFechaHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaHasta = picked);
      _aplicarFechas();
    }
  }

  void _aplicarFechas() {
    context.read<ReporteCorrelativosCubit>().setFechas(
      _fechaDesde != null ? _fmtApi(_fechaDesde!) : null,
      _fechaHasta != null ? _fmtApi(_fechaHasta!) : null,
    );
  }

  void _limpiarFechas() {
    setState(() { _fechaDesde = null; _fechaHasta = null; });
    context.read<ReporteCorrelativosCubit>().setFechas(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final sedes = _getSedes();
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Reporte de Correlativos'),
        body: Column(
          children: [
            // ── Selector de sede ──
            _buildSedePicker(sedes),
            // ── Filtros de fecha (solo si hay sede seleccionada) ──
            if (_sedeId != null) _buildFiltroFechas(),
            // ── Contenido ──
            Expanded(
              child: _sedeId == null
                  ? _buildSedePrompt()
                  : BlocBuilder<ReporteCorrelativosCubit, ReporteCorrelativosState>(
                      builder: (context, state) {
                        if (state is ReporteCorrelativosLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is ReporteCorrelativosError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                                const SizedBox(height: 8),
                                Text(state.message, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context.read<ReporteCorrelativosCubit>().cargar(),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }
                        if (state is ReporteCorrelativosLoaded) {
                          return _buildContent(context, state.reporte);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedePicker(List<Sede> sedes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _sedeId != null ? AppColors.blue1 : Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sedeId,
            isExpanded: true,
            hint: Row(
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text('Seleccionar sede', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: sedes.map((sede) => DropdownMenuItem<String>(
              value: sede.id,
              child: Row(
                children: [
                  Icon(Icons.store, size: 14, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sede.nombre, overflow: TextOverflow.ellipsis)),
                  Text(sede.codigo, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            )).toList(),
            onChanged: _onSedeChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSedePrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_mall_directory, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Selecciona una sede para ver\nel reporte de correlativos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroFechas() {
    final hayFiltro = _fechaDesde != null || _fechaHasta != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickFechaDesde,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _fechaDesde != null ? AppColors.blue1 : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      _fechaDesde != null ? _fmtLabel(_fechaDesde!) : 'Desde',
                      style: TextStyle(fontSize: 12, color: _fechaDesde != null ? Colors.black87 : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('—', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickFechaHasta,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _fechaHasta != null ? AppColors.blue1 : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      _fechaHasta != null ? _fmtLabel(_fechaHasta!) : 'Hasta',
                      style: TextStyle(fontSize: 12, color: _fechaHasta != null ? Colors.black87 : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hayFiltro)
            IconButton(
              icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade500),
              onPressed: _limpiarFechas,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReporteCorrelativos reporte) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReporteCorrelativosCubit>().cargar(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ResumenCard(resumen: reporte.resumen),
          const SizedBox(height: 16),
          if (reporte.series.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay comprobantes en este rango', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...reporte.series.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SerieCard(serie: s),
            )),
        ],
      ),
    );
  }
}

// ── Resumen general ──

class _ResumenCard extends StatelessWidget {
  final ResumenCorrelativos resumen;
  const _ResumenCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final allOk = resumen.seriesConGaps == 0 && resumen.seriesDesincronizadas == 0;
    return GradientContainer(
      borderColor: allOk ? Colors.green.shade200 : Colors.orange.shade200,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: allOk ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  allOk ? 'Todo en orden' : 'Se encontraron inconsistencias',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: allOk ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _resumenItem('Series', '${resumen.totalSeries}', Colors.blue),
                _resumenItem('OK', '${resumen.seriesOk}', Colors.green),
                _resumenItem('Gaps', '${resumen.seriesConGaps}', Colors.orange),
                _resumenItem('Desinc.', '${resumen.seriesDesincronizadas}', Colors.red),
              ],
            ),
            if (resumen.totalFaltantes > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${resumen.totalFaltantes} correlativo(s) faltante(s) en total',
                style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Card por serie ──

class _SerieCard extends StatefulWidget {
  final SerieCorrelativo serie;
  const _SerieCard({required this.serie});

  @override
  State<_SerieCard> createState() => _SerieCardState();
}

class _SerieCardState extends State<_SerieCard> {
  bool _expanded = false;

  SerieCorrelativo get s => widget.serie;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: _borderColor,
      child: InkWell(
        onTap: s.faltantes.isNotEmpty || s.desincronizado
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: serie + tipo + estado
              Row(
                children: [
                  _tipoChip(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.serie, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  _estadoChip(),
                ],
              ),
              const SizedBox(height: 8),
              // Sede
              Text('Sede: ${s.sedeNombre}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 6),
              // Info grid
              Row(
                children: [
                  _infoItem('Emitidos', '${s.totalEmitidos}'),
                  _infoItem('Rango', s.totalEmitidos == 0 ? '-' : '1 → ${s.ultimoCorrelativo}'),
                  _infoItem('Contador', '${s.contadorSede}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _infoItem('Anulados', '${s.totalAnulados}'),
                  _infoItem('Faltantes', '${s.totalFaltantes}', color: s.totalFaltantes > 0 ? Colors.red : null),
                  _infoItem('Duplicados', '${s.duplicados}', color: s.duplicados > 0 ? Colors.red : null),
                ],
              ),
              // Desincronizado warning
              if (s.desincronizado && s.totalEmitidos > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_problem, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Contador sede (${s.contadorSede}) ≠ último correlativo (${s.ultimoCorrelativo})',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Expandable: faltantes
              if (_expanded && s.faltantes.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text('Correlativos faltantes:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.faltantes.map((n) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '${s.serie}-${n.toString().padLeft(8, '0')}',
                      style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontFamily: 'monospace'),
                    ),
                  )).toList(),
                ),
                if (s.totalFaltantes > s.faltantes.length) ...[
                  const SizedBox(height: 6),
                  Text(
                    '... y ${s.totalFaltantes - s.faltantes.length} más',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
              // Expand indicator
              if (s.faltantes.isNotEmpty || s.desincronizado)
                Center(
                  child: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    if (s.esOk) return Colors.green.shade200;
    if (s.esDesincronizado) return Colors.red.shade200;
    return Colors.orange.shade200;
  }

  Widget _tipoChip() {
    Color color;
    switch (s.tipoComprobante) {
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
      child: Text(s.tipoLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _estadoChip() {
    Color color;
    String label;
    IconData icon;
    switch (s.estado) {
      case 'OK':
        color = Colors.green; label = 'OK'; icon = Icons.check_circle; break;
      case 'GAPS':
        color = Colors.orange; label = 'GAPS'; icon = Icons.warning; break;
      case 'DESINCRONIZADO':
        color = Colors.red; label = 'DESINC.'; icon = Icons.sync_problem; break;
      default:
        color = Colors.grey; label = s.estado; icon = Icons.help; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.grey.shade800)),
        ],
      ),
    );
  }
}
