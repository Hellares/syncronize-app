import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart' as df;
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/sorteo_analytics_cubit.dart';
import '../bloc/sorteo_analytics_state.dart';

/// Dashboard de analytics de SORTEOS/DINÁMICAS — mismo lenguaje visual
/// que Estadísticas de Ventas: KPIs compactos, donuts con leyenda,
/// barras de participación y listas top.
class SorteoAnalyticsPage extends StatefulWidget {
  const SorteoAnalyticsPage({super.key});

  @override
  State<SorteoAnalyticsPage> createState() => _SorteoAnalyticsPageState();
}

class _SorteoAnalyticsPageState extends State<SorteoAnalyticsPage> {
  // Periodo: MES (actual) | TRIMESTRE (últimos 3 meses) | ANIO | 'TODO'
  // (= historial completo, sin fechas)
  String _periodo = 'MES';
  String? _tipo; // null = todos, SORTEO | DINAMICA | BINGO

  // Paleta categórica validada (CVD-safe con gaps + leyenda) — la misma
  // del dashboard de ventas. El color sigue a la entidad.
  static const _azul = Color(0xFF1976D2);
  static const _naranja = Color(0xFFEF6C00);
  static const _teal = Color(0xFF009688);
  static const _purpura = Color(0xFFAB47BC);

  static const _coloresCanal = <String, Color>{
    'FACEBOOK': _azul,
    'INSTAGRAM': _purpura,
    'TIKTOK': _teal,
    'WHATSAPP': _naranja,
  };
  static const _labelsCanal = <String, String>{
    'FACEBOOK': 'Facebook',
    'INSTAGRAM': 'Instagram',
    'TIKTOK': 'TikTok',
    'WHATSAPP': 'WhatsApp',
    'OTRO': 'Otro',
  };
  static const _coloresTipo = <String, Color>{
    'SORTEO': _azul,
    'DINAMICA': _naranja,
    'BINGO': _teal,
  };
  static const _labelsTipo = <String, String>{
    'SORTEO': 'Sorteo',
    'DINAMICA': 'Dinámica',
    'BINGO': 'Bingo',
  };
  static const _labelsEstadoPremio = <String, String>{
    'REGISTRADO': 'Registrado',
    'PREPARANDO': 'Preparando',
    'ENVIADO': 'Enviado',
    'ENTREGADO': 'Entregado',
  };
  static const _labelsModalidad = <String, String>{
    'ENVIO_AGENCIA': 'Envío por agencia',
    'RETIRO_TIENDA': 'Retiro en tienda',
    'EFECTIVO': 'Efectivo (Yape)',
  };

  @override
  void initState() {
    super.initState();
    _load();
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
        inicio = df.DateFormatter.formatForApi(DateTime(now.year, now.month - 2, 1));
        fin = df.DateFormatter.formatForApi(now);
        break;
      case 'ANIO':
        inicio = df.DateFormatter.formatForApi(DateTime(now.year, 1, 1));
        fin = df.DateFormatter.formatForApi(now);
        break;
      default: // historial completo, sin fechas
        inicio = null;
        fin = null;
    }
    context.read<SorteoAnalyticsCubit>().load(
          fechaInicio: inicio,
          fechaFin: fin,
          tipo: _tipo,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        customHeight: 40,
        title: 'Estadísticas de Sorteos',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: BlocBuilder<SorteoAnalyticsCubit, SorteoAnalyticsState>(
        builder: (context, state) {
          if (state is SorteoAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SorteoAnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(state.message, textAlign: TextAlign.center),
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
          if (state is SorteoAnalyticsLoaded) {
            final d = state.data;
            return Column(children: [
              if (state.refreshing)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildFiltros(),
                      const SizedBox(height: 12),
                      _buildResumen(
                          (d['resumen'] as Map?)?.cast<String, dynamic>() ??
                              {}),
                      const SizedBox(height: 12),
                      _buildActividadBot(
                          (d['serieDiaria'] as List<dynamic>? ?? [])),
                      const SizedBox(height: 12),
                      _buildDonutCard(
                        'Recaudado por Canal',
                        (d['porCanal'] as List<dynamic>? ?? []),
                        labelKey: 'canal',
                        labels: _labelsCanal,
                        colores: _coloresCanal,
                      ),
                      const SizedBox(height: 12),
                      _buildDonutCard(
                        'Recaudado por Tipo',
                        (d['porTipo'] as List<dynamic>? ?? []),
                        labelKey: 'tipo',
                        labels: _labelsTipo,
                        colores: _coloresTipo,
                      ),
                      const SizedBox(height: 12),
                      _buildTopSorteos(
                          (d['topSorteos'] as List<dynamic>? ?? [])),
                      const SizedBox(height: 12),
                      _buildTopJugadores(
                          (d['topJugadores'] as List<dynamic>? ?? [])),
                      const SizedBox(height: 12),
                      _buildPremios(d),
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
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue1.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.blue1 : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.blue1 : Colors.grey.shade600,
            )),
      ),
    );
  }

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
          Text('Periodo (por fecha del sorteo)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: periodos.entries
                .map((e) => _chip(e.value, _periodo == e.key, () {
                      setState(() => _periodo = e.key);
                      _load();
                    }))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text('Tipo',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Todos', _tipo == null, () {
                setState(() => _tipo = null);
                _load();
              }),
              ..._labelsTipo.entries.map((e) => _chip(e.value, _tipo == e.key,
                      () {
                    setState(() => _tipo = e.key);
                    _load();
                  })),
            ],
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

  Widget _buildResumen(Map<String, dynamic> r) {
    final horas = (r['tiempoValidacionHoras'] as num?)?.toDouble();
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
          _kpi('Sorteos', '${r['sorteos'] ?? 0} (${r['abiertos'] ?? 0} ab.)',
              Icons.card_giftcard, Colors.blue),
          _kpi('Recaudado', 'S/${_n(r['recaudado'])}', Icons.attach_money,
              Colors.green),
          _kpi('Jugadas', '${r['participaciones'] ?? 0}',
              Icons.confirmation_number_outlined, Colors.orange),
          _kpi('Jugadores', '${r['participantesUnicos'] ?? 0}',
              Icons.groups_outlined, Colors.teal),
          _kpi('Gasto/jugador', 'S/${_n(r['ticketPromedio'])}',
              Icons.trending_up, Colors.indigo),
          _kpi('Conversión pago', '${_n(r['conversionPagoPct'])}%',
              Icons.task_alt, Colors.green),
          _kpi('Por validar', '${r['pendientesValidar'] ?? 0}',
              Icons.pending_outlined, Colors.amber),
          _kpi(
              'Premios',
              '${r['premiosEntregados'] ?? 0}/${r['premios'] ?? 0} entr.',
              Icons.redeem,
              Colors.purple),
          _kpi(
              'Validación',
              horas == null
                  ? '-'
                  : horas < 1
                      ? '${(horas * 60).toStringAsFixed(0)} min'
                      : '${horas.toStringAsFixed(1)} h',
              Icons.timer_outlined,
              Colors.brown),
        ],
      ),
    ]);
  }

  // ── Actividad del bot (30 días) ───────────────────────────────────────

  Widget _buildActividadBot(List<dynamic> serie) {
    final registradas = serie
        .map((s) => (((s as Map)['registradas']) as num?)?.toDouble() ?? 0.0)
        .toList();
    final activadas = serie
        .map((s) => (((s as Map)['activadas']) as num?)?.toDouble() ?? 0.0)
        .toList();
    final maxY = [...registradas, ...activadas, 1.0]
        .reduce((a, b) => a > b ? a : b);
    final hayDatos = maxY > 1.0 ||
        registradas.any((v) => v > 0) ||
        activadas.any((v) => v > 0);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Actividad del Bot (30 días)', fontSize: 12),
          const SizedBox(height: 2),
          Text('Jugadores registrados vs pagos validados por día',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          // Leyenda (2 series)
          Row(children: [
            _leyendaDot(_azul, 'Registradas'),
            const SizedBox(width: 12),
            _leyendaDot(_teal, 'Activadas (pagadas)'),
          ]),
          const SizedBox(height: 8),
          if (!hayDatos)
            Center(
                child: Text('Sin actividad reciente',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY * 1.2,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final dia =
                            ((serie[s.x.toInt()] as Map)['dia'] ?? '') as String;
                        final esReg = s.barIndex == 0;
                        return LineTooltipItem(
                          '$dia\n${esReg ? 'Registradas' : 'Activadas'}: ${s.y.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      }).toList(),
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
                        interval: (maxY / 3).clamp(1.0, double.infinity),
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
                          if (idx % 7 != 0 || idx >= serie.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                                ((serie[idx] as Map)['dia'] ?? '') as String,
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
                    horizontalInterval:
                        (maxY / 3).clamp(1.0, double.infinity),
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < registradas.length; i++)
                          FlSpot(i.toDouble(), registradas[i]),
                      ],
                      isCurved: false,
                      color: _azul,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < activadas.length; i++)
                          FlSpot(i.toDouble(), activadas[i]),
                      ],
                      isCurved: false,
                      color: _teal,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _leyendaDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
    ]);
  }

  // ── Donuts ────────────────────────────────────────────────────────────

  Widget _buildDonutCard(
    String titulo,
    List<dynamic> items, {
    required String labelKey,
    required Map<String, String> labels,
    required Map<String, Color> colores,
  }) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppSubtitle(titulo, fontSize: 12),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            _donut(items.map((m) {
              final item = (m as Map).cast<String, dynamic>();
              final clave = (item[labelKey] ?? '') as String;
              return _SPieItem(
                label: labels[clave] ?? clave,
                sub:
                    'S/${_n(item['recaudado'])} · ${item['sorteos'] ?? 0} sorteos · ${item['participaciones'] ?? 0} jugadas',
                valor: ((item['recaudado'] as num?) ?? 0).toDouble(),
                color: colores[clave] ?? Colors.blueGrey,
              );
            }).toList()),
        ]),
      ),
    );
  }

  Widget _donut(List<_SPieItem> items) {
    final total = items.fold<double>(0, (s, i) => s + i.valor);
    if (total <= 0) {
      // Todo en 0 soles (p. ej. sorteos gratuitos): leyenda sin torta
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final i in items) _leyendaFila(i, null)],
      );
    }
    return Row(children: [
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
          children: [
            for (final i in items)
              _leyendaFila(i, total > 0 ? i.valor / total * 100 : null),
          ],
        ),
      ),
    ]);
  }

  Widget _leyendaFila(_SPieItem i, double? pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: i.color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(i.sub,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (pct != null)
          Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800)),
      ]),
    );
  }

  // ── Tops ──────────────────────────────────────────────────────────────

  Widget _buildTopSorteos(List<dynamic> sorteos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Sorteos por Recaudación', fontSize: 12),
          const SizedBox(height: 10),
          if (sorteos.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            ...sorteos.take(10).toList().asMap().entries.map((e) {
              final s = (e.value as Map).cast<String, dynamic>();
              final tipo = (s['tipo'] ?? '') as String;
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
                          Text(s['titulo'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${_labelsTipo[tipo] ?? tipo} · ${s['participaciones'] ?? 0} jugadas · '
                            'premios ${s['premiosEntregados'] ?? 0}/${s['premios'] ?? 0}',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                  ),
                  Text('S/${_n(s['recaudado'])}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _coloresTipo[tipo] ?? AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildTopJugadores(List<dynamic> jugadores) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Jugadores', fontSize: 12),
          const SizedBox(height: 2),
          Text('Solo jugadas con pago validado',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          if (jugadores.isEmpty)
            Center(
                child: Text('Sin datos',
                    style: TextStyle(color: Colors.grey.shade500)))
          else
            ...jugadores.take(10).toList().asMap().entries.map((e) {
              final j = (e.value as Map).cast<String, dynamic>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _teal)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(j['nombre'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            'DNI ${j['dni'] ?? ''} · ${j['participaciones'] ?? 0} jugadas en ${j['sorteosDistintos'] ?? 0} sorteos',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade600),
                          ),
                        ]),
                  ),
                  Text('S/${_n(j['gastado'])}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _teal)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  // ── Premios ───────────────────────────────────────────────────────────

  Widget _buildPremios(Map<String, dynamic> d) {
    final porEstado = (d['premiosPorEstado'] as List<dynamic>? ?? []);
    final porModalidad = (d['premiosPorModalidad'] as List<dynamic>? ?? []);
    final zonas = (d['zonasPremios'] as List<dynamic>? ?? []);
    if (porEstado.isEmpty && porModalidad.isEmpty && zonas.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget barras(String titulo, List<dynamic> items,
        Map<String, String> labels, String key, Color color) {
      if (items.isEmpty) return const SizedBox.shrink();
      final maxC = items.fold<int>(0, (m, i) {
        final c = (((i as Map)['cantidad']) as num?)?.toInt() ?? 0;
        return c > m ? c : m;
      });
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        ...items.map((i) {
          final item = (i as Map).cast<String, dynamic>();
          final clave = (item[key] ?? '') as String;
          final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(labels[clave] ?? clave,
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
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ]),
          );
        }),
        const SizedBox(height: 6),
      ]);
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Premios', fontSize: 12),
          const SizedBox(height: 10),
          barras('Por estado', porEstado, _labelsEstadoPremio, 'estado',
              _purpura),
          barras('Por modalidad de entrega', porModalidad, _labelsModalidad,
              'modalidad', _naranja),
          if (zonas.isNotEmpty) ...[
            Text('Zonas de envío de premios',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            ...zonas.map((z) {
              final zm = (z as Map).cast<String, dynamic>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(zm['zona'] ?? '',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${zm['cantidad'] ?? 0} premios',
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade600)),
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

/// Porción de torta: label + detalle para leyenda, valor y color fijo.
class _SPieItem {
  final String label;
  final String sub;
  final double valor;
  final Color color;

  const _SPieItem({
    required this.label,
    required this.sub,
    required this.valor,
    required this.color,
  });
}
