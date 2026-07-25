import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart' as df;
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/dashboard/servicio_dashboard_cubit.dart';

/// Dashboard de ÓRDENES DE SERVICIO — mismo lenguaje visual que los
/// dashboards de ventas/sorteos: filtros por periodo, KPIs compactos
/// (incluye dinero por cobrar, vencidas y reingresos), embudo de estados,
/// serie mensual, donut por tipo, técnicos y equipos más atendidos.
/// Un solo request consolidado + recarga sin blanqueo.
class ServicioDashboardPage extends StatefulWidget {
  const ServicioDashboardPage({super.key});

  @override
  State<ServicioDashboardPage> createState() => _ServicioDashboardPageState();
}

class _ServicioDashboardPageState extends State<ServicioDashboardPage> {
  // MES (actual) | TRIMESTRE (últimos 3 meses) | ANIO | 'TODO' (historial)
  String _periodo = 'MES';
  late final ServicioDashboardCubit _cubit;

  // Paleta categórica validada (la misma de ventas/sorteos)
  static const _azul = Color(0xFF1976D2);
  static const _naranja = Color(0xFFEF6C00);
  static const _teal = Color(0xFF009688);
  static const _purpura = Color(0xFFAB47BC);

  static const _labelsEstado = <String, String>{
    'RECIBIDO': 'Recibido',
    'EN_DIAGNOSTICO': 'En diagnóstico',
    'ESPERANDO_APROBACION': 'Esperando aprobación',
    'EN_REPARACION': 'En reparación',
    'PENDIENTE_PIEZAS': 'Pendiente de piezas',
    'TERCERIZADO': 'Tercerizado',
    'REPARADO': 'Reparado',
    'LISTO_ENTREGA': 'Listo para entrega',
    'ENTREGADO': 'Entregado',
    'FINALIZADO': 'Finalizado',
    'CANCELADO': 'Cancelado',
  };
  static const _labelsTipo = <String, String>{
    'REPARACION': 'Reparación',
    'MANTENIMIENTO': 'Mantenimiento',
    'INSTALACION': 'Instalación',
    'DIAGNOSTICO': 'Diagnóstico',
    'ACTUALIZACION': 'Actualización',
    'LIMPIEZA': 'Limpieza',
    'RECUPERACION_DATOS': 'Recuperación de datos',
    'CONFIGURACION': 'Configuración',
    'CONSULTORIA': 'Consultoría',
    'FORMACION': 'Formación',
  };
  static const _labelsPrioridad = <String, String>{
    'BAJA': 'Baja',
    'NORMAL': 'Normal',
    'ALTA': 'Alta',
    'URGENTE': 'Urgente',
    'EMERGENCIA': 'Emergencia',
  };
  // El color de tipo sigue a la entidad; los que exceden la paleta caen
  // a blueGrey (aparecen poco y la leyenda carga la identidad).
  static const _coloresTipo = <String, Color>{
    'REPARACION': _azul,
    'MANTENIMIENTO': _teal,
    'INSTALACION': _naranja,
    'DIAGNOSTICO': _purpura,
  };

  @override
  void initState() {
    super.initState();
    _cubit = locator<ServicioDashboardCubit>();
    _load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _load() {
    final now = DateTime.now();
    String? inicio;
    String? fin;
    switch (_periodo) {
      case 'MES':
        inicio = df.DateFormatter.formatForApi(DateTime(now.year, now.month, 1));
        fin = df.DateFormatter.formatForApi(now);
        break;
      case 'TRIMESTRE':
        inicio =
            df.DateFormatter.formatForApi(DateTime(now.year, now.month - 2, 1));
        fin = df.DateFormatter.formatForApi(now);
        break;
      case 'ANIO':
        inicio = df.DateFormatter.formatForApi(DateTime(now.year, 1, 1));
        fin = df.DateFormatter.formatForApi(now);
        break;
      default: // historial completo
        inicio = null;
        fin = null;
    }
    _cubit.loadDashboard(fechaDesde: inicio, fechaHasta: fin);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(
            customHeight: 40,
            title: 'Estadísticas de Servicios',
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
          body: BlocBuilder<ServicioDashboardCubit, ServicioDashboardState>(
            builder: (context, state) {
              if (state is ServicioDashboardLoading ||
                  state is ServicioDashboardInitial) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.blue1));
              }
              if (state is ServicioDashboardError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child:
                            Text(state.message, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar')),
                    ],
                  ),
                );
              }
              if (state is ServicioDashboardDataLoaded) {
                final d = state.data;
                return Column(children: [
                  if (state.refreshing)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    const SizedBox(height: 2),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _load(),
                      color: AppColors.blue1,
                      child: ListView(
                        padding: const EdgeInsets.all(10),
                        children: [
                          _buildFiltros(),
                          const SizedBox(height: 12),
                          _buildResumen(
                              (d['resumen'] as Map?)?.cast<String, dynamic>() ??
                                  {}),
                          const SizedBox(height: 12),
                          _buildEmbudo(
                              (d['porEstado'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildSerieMensual(
                              (d['porMes'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildPorTipo((d['porTipo'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildPrioridad(
                              (d['porPrioridad'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildTopTecnicos(
                              (d['topTecnicos'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildTopEquipos(
                              (d['topEquipos'] as List<dynamic>? ?? [])),
                          const SizedBox(height: 12),
                          _buildTercerizaciones(
                              (d['tercerizaciones'] as Map?)
                                      ?.cast<String, dynamic>() ??
                                  {}),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ]);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────

  Widget _buildFiltros() {
    const periodos = {
      'MES': 'Este mes',
      'TRIMESTRE': 'Últimos 3 meses',
      'ANIO': 'Este año',
      'TODO': 'Todo',
    };
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Periodo (por fecha de ingreso de la orden)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: periodos.entries
                .map((e) => GestureDetector(
                      onTap: () {
                        setState(() => _periodo = e.key);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _periodo == e.key
                              ? AppColors.blue1.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _periodo == e.key
                                  ? AppColors.blue1
                                  : Colors.grey.shade300),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _periodo == e.key
                                  ? AppColors.blue1
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }

  // ── Resumen ───────────────────────────────────────────────────────────

  Widget _kpi(String titulo, String valor, IconData icon, Color color) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(titulo,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  String _horasLegibles(num? horas) {
    if (horas == null) return '-';
    final h = horas.toDouble();
    if (h < 24) return '${h.toStringAsFixed(0)} h';
    return '${(h / 24).toStringAsFixed(1)} días';
  }

  Widget _buildResumen(Map<String, dynamic> r) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const AppSubtitle('Resumen General', fontSize: 12),
      const SizedBox(height: 4),
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          mainAxisExtent: 60,
        ),
        children: [
          _kpi('Órdenes', '${r['totalOrdenes'] ?? 0}',
              Icons.build_circle_outlined, Colors.blue),
          _kpi('En taller', '${r['enTaller'] ?? 0}', Icons.handyman_outlined,
              Colors.orange),
          _kpi('Entregadas', '${r['entregadas'] ?? 0}', Icons.task_alt,
              Colors.green),
          _kpi('Ingreso', 'S/${_n(r['ingresoTotal'])}', Icons.attach_money,
              Colors.green),
          _kpi('Por cobrar', 'S/${_n(r['porCobrar'])}',
              Icons.hourglass_bottom_outlined, Colors.indigo),
          _kpi('Adelantos', 'S/${_n(r['adelantosCobrados'])}',
              Icons.savings_outlined, Colors.teal),
          _kpi('Vencidas', '${r['vencidas'] ?? 0}', Icons.event_busy,
              Colors.red),
          _kpi(
              'Reingresos',
              '${r['reingresos'] ?? 0} · ${_n(r['reingresosPct'])}%',
              Icons.replay_circle_filled_outlined,
              Colors.brown),
          _kpi('T. resolución',
              _horasLegibles(r['tiempoPromedioResolucionHoras'] as num?),
              Icons.timer_outlined, Colors.purple),
        ],
      ),
    ]);
  }

  // ── Embudo de estados ─────────────────────────────────────────────────

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ENTREGADO':
      case 'FINALIZADO':
        return Colors.green.shade600;
      case 'CANCELADO':
        return Colors.red.shade400;
      case 'REPARADO':
      case 'LISTO_ENTREGA':
        return _teal;
      default:
        return _azul;
    }
  }

  Widget _buildEmbudo(List<dynamic> porEstado) {
    final maxC = porEstado.fold<int>(0, (m, e) {
      final c = (((e as Map)['cantidad']) as num?)?.toInt() ?? 0;
      return c > m ? c : m;
    });
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Órdenes por Estado', fontSize: 12),
          const SizedBox(height: 2),
          Text('En el orden del flujo de trabajo',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          if (porEstado.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            ...porEstado.map((e) {
              final item = (e as Map).cast<String, dynamic>();
              final estado = (item['estado'] ?? '') as String;
              final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
              final color = _colorEstado(estado);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_labelsEstado[estado] ?? estado,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                            Text('$cantidad',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600)),
                          ]),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxC > 0 ? cantidad / maxC : 0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ]),
              );
            }),
        ]),
      ),
    );
  }

  // ── Serie mensual ─────────────────────────────────────────────────────

  Widget _buildSerieMensual(List<dynamic> porMes) {
    if (porMes.length < 2) return const SizedBox.shrink();
    final maxC = porMes.fold<double>(0, (m, e) {
      final c = (((e as Map)['cantidad']) as num?)?.toDouble() ?? 0;
      return c > m ? c : m;
    });
    if (maxC <= 0) return const SizedBox.shrink();
    final intervalo = (maxC / 3).clamp(1.0, double.infinity);
    final labelCada = (porMes.length / 6).ceil().clamp(1, 99);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Órdenes por Mes', fontSize: 12),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxC * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m =
                          porMes[group.x.toInt()] as Map<String, dynamic>;
                      return BarTooltipItem(
                        '${m['mes']}\n${m['cantidad']} órdenes\nS/ ${_n(m['ingreso'])}',
                        const TextStyle(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: intervalo,
                      getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 8, color: Colors.grey)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx % labelCada != 0 || idx >= porMes.length) {
                          return const SizedBox.shrink();
                        }
                        final mes =
                            ((porMes[idx] as Map)['mes'] ?? '') as String;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                              mes.length > 5 ? mes.substring(5) : mes,
                              style: const TextStyle(
                                  fontSize: 7, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: intervalo,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: porMes.asMap().entries.map((e) {
                  final m = (e.value as Map).cast<String, dynamic>();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: ((m['cantidad'] as num?) ?? 0).toDouble(),
                        color: _azul,
                        width: 10,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Por tipo (donut) ──────────────────────────────────────────────────

  Widget _buildPorTipo(List<dynamic> porTipo) {
    if (porTipo.isEmpty) return const SizedBox.shrink();
    final items = porTipo.map((t) {
      final m = (t as Map).cast<String, dynamic>();
      final tipo = (m['tipo'] ?? '') as String;
      return (
        label: _labelsTipo[tipo] ?? tipo,
        sub: '${m['cantidad'] ?? 0} órdenes · S/${_n(m['ingreso'])}',
        valor: ((m['cantidad'] as num?) ?? 0).toDouble(),
        color: _coloresTipo[tipo] ?? Colors.blueGrey,
      );
    }).toList();
    final total = items.fold<double>(0, (s, i) => s + i.valor);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Órdenes por Tipo de Servicio', fontSize: 12),
          const SizedBox(height: 10),
          if (total <= 0)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            Row(children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                    startDegreeOffset: -90,
                    sections: items.map((i) {
                      final pct = i.valor / total * 100;
                      return PieChartSectionData(
                        value: i.valor,
                        color: i.color,
                        radius: 28,
                        showTitle: pct >= 8,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: i.color,
                                            shape: BoxShape.circle)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(i.label,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(i.sub,
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ]),
                                  ),
                                  Text(
                                      '${(i.valor / total * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade800)),
                                ]),
                          ))
                      .toList(),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  // ── Prioridad ─────────────────────────────────────────────────────────

  Widget _buildPrioridad(List<dynamic> porPrioridad) {
    if (porPrioridad.isEmpty) return const SizedBox.shrink();
    final maxC = porPrioridad.fold<int>(0, (m, e) {
      final c = (((e as Map)['cantidad']) as num?)?.toInt() ?? 0;
      return c > m ? c : m;
    });
    Color colorDe(String p) => p == 'EMERGENCIA' || p == 'URGENTE'
        ? Colors.red.shade600
        : p == 'ALTA'
            ? Colors.orange.shade700
            : Colors.blueGrey.shade400;
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Por Prioridad', fontSize: 12),
          const SizedBox(height: 10),
          ...porPrioridad.map((e) {
            final item = (e as Map).cast<String, dynamic>();
            final prioridad = (item['prioridad'] ?? '') as String;
            final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_labelsPrioridad[prioridad] ?? prioridad,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                          Text('$cantidad',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600)),
                        ]),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxC > 0 ? cantidad / maxC : 0,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorDe(prioridad)),
                      ),
                    ),
                  ]),
            );
          }),
        ]),
      ),
    );
  }

  // ── Tops ──────────────────────────────────────────────────────────────

  Widget _buildTopTecnicos(List<dynamic> tecnicos) {
    if (tecnicos.isEmpty) return const SizedBox.shrink();
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Técnicos', fontSize: 12),
          const SizedBox(height: 2),
          Text('Ingreso = órdenes cerradas con éxito',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          ...tecnicos.take(10).toList().asMap().entries.map((e) {
            final t = (e.value as Map).cast<String, dynamic>();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${e.key + 1}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['nombre'] ?? '',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${t['ordenes'] ?? 0} órdenes · ${t['cerradas'] ?? 0} cerradas',
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade600),
                        ),
                      ]),
                ),
                Text('S/${_n(t['ingreso'])}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1)),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildTopEquipos(List<dynamic> equipos) {
    if (equipos.isEmpty) return const SizedBox.shrink();
    final maxC = equipos.fold<int>(0, (m, e) {
      final c = (((e as Map)['cantidad']) as num?)?.toInt() ?? 0;
      return c > m ? c : m;
    });
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Equipos más Atendidos', fontSize: 12),
          const SizedBox(height: 10),
          ...equipos.take(10).map((e) {
            final item = (e as Map).cast<String, dynamic>();
            final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['equipo'] ?? '',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$cantidad órdenes',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade600)),
                        ]),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxC > 0 ? cantidad / maxC : 0,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                      ),
                    ),
                  ]),
            );
          }),
        ]),
      ),
    );
  }

  // ── Tercerizaciones (B2B entre talleres) ──────────────────────────────

  static const _labelsEstadoTerceriza = <String, String>{
    'PENDIENTE': 'Pendiente',
    'ACEPTADO': 'Aceptado',
    'RECHAZADO': 'Rechazado',
    'EN_PROCESO': 'En proceso',
    'COMPLETADO': 'Completado',
    'CANCELADO': 'Cancelado',
  };

  Widget _tarjetaB2B(String titulo, IconData icon, Color color,
      List<(String, String)> filas) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(titulo,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
          const SizedBox(height: 6),
          ...filas.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f.$1,
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade600)),
                      Text(f.$2,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ]),
              )),
        ]),
      ),
    );
  }

  Widget _buildTercerizaciones(Map<String, dynamic> t) {
    final enviadas = (t['enviadas'] as Map?)?.cast<String, dynamic>();
    final recibidas = (t['recibidas'] as Map?)?.cast<String, dynamic>();
    final partners = (t['partners'] as List<dynamic>? ?? []);
    final totalEnviadas = (enviadas?['total'] as num?)?.toInt() ?? 0;
    final totalRecibidas = (recibidas?['total'] as num?)?.toInt() ?? 0;
    if (totalEnviadas == 0 && totalRecibidas == 0) {
      return const SizedBox.shrink();
    }

    String estadosResumen(Map<String, dynamic>? lado) {
      final porEstado = (lado?['porEstado'] as List<dynamic>? ?? []);
      return porEstado
          .map((e) {
            final m = (e as Map).cast<String, dynamic>();
            final estado = (m['estado'] ?? '') as String;
            return '${m['cantidad']} ${_labelsEstadoTerceriza[estado] ?? estado}';
          })
          .join(' · ');
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Tercerizaciones (B2B)', fontSize: 12),
          const SizedBox(height: 2),
          Text('Trabajos entre talleres — ganancia = costo al cliente − precio B2B',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _tarjetaB2B(
              'Enviadas ($totalEnviadas)',
              Icons.upload_outlined,
              _naranja,
              [
                ('Pagado a talleres', 'S/${_n(enviadas?['costoB2B'])}'),
                ('Ganancia est.', 'S/${_n(enviadas?['gananciaEstimada'])}'),
                ('Por pagar', 'S/${_n(enviadas?['porPagarB2B'])}'),
              ],
            ),
            const SizedBox(width: 8),
            _tarjetaB2B(
              'Recibidas ($totalRecibidas)',
              Icons.download_outlined,
              _teal,
              [
                ('Ingreso B2B', 'S/${_n(recibidas?['ingresoB2B'])}'),
                ('Por cobrar', 'S/${_n(recibidas?['porCobrarB2B'])}'),
              ],
            ),
          ]),
          if (totalEnviadas > 0) ...[
            const SizedBox(height: 6),
            Text('Enviadas: ${estadosResumen(enviadas)}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ],
          if (totalRecibidas > 0)
            Text('Recibidas: ${estadosResumen(recibidas)}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          if (partners.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Talleres aliados',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            ...partners.map((p) {
              final m = (p as Map).cast<String, dynamic>();
              final env = (m['enviadas'] as num?)?.toInt() ?? 0;
              final rec = (m['recibidas'] as num?)?.toInt() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(m['nombre'] ?? '',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        [
                          if (env > 0) 'le enviamos $env',
                          if (rec > 0) 'nos envió $rec',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  String _n(dynamic value) {
    if (value == null) return '0.00';
    final n = value is double
        ? value
        : (value is int
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0.0);
    return n.toStringAsFixed(2);
  }
}
