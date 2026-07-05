import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
import '../../../../core/widgets/date/custom_date.dart' hide DateFormatter;
import '../../../../core/widgets/smart_appbar.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../bloc/resumen_financiero_cubit.dart';
import '../bloc/resumen_financiero_state.dart';

class ResumenFinancieroPage extends StatelessWidget {
  const ResumenFinancieroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ResumenFinancieroCubit>(),
      child: const _ResumenFinancieroView(),
    );
  }
}

class _ResumenFinancieroView extends StatefulWidget {
  const _ResumenFinancieroView();

  @override
  State<_ResumenFinancieroView> createState() => _ResumenFinancieroViewState();
}

class _ResumenFinancieroViewState extends State<_ResumenFinancieroView> {
  String _periodoLabel = 'Este mes';
  DateTime _fechaDesde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaHasta = DateTime.now();

  /// Sede seleccionada para el resumen (null = toda la empresa). Es un filtro
  /// LOCAL a esta pantalla: no toca la sede activa global.
  String? _sedeId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ResumenFinancieroCubit>().loadResumen(
          fechaDesde: DateFormatter.toUtcIso(_fechaDesde),
          fechaHasta: DateFormatter.toUtcIso(_fechaHasta),
          sedeId: _sedeId,
        );
  }

  void _seleccionarSede(String? sedeId) {
    if (_sedeId == sedeId) return;
    setState(() => _sedeId = sedeId);
    _load();
  }

  void _seleccionarPeriodo(String label, DateTime desde, DateTime hasta) {
    setState(() {
      _periodoLabel = label;
      _fechaDesde = desde;
      _fechaHasta = hasta;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Resumen Financiero',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exportar reportes',
            onPressed: () => context.push('/empresa/reportes-financieros'),
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocBuilder<ResumenFinancieroCubit, ResumenFinancieroState>(
          builder: (context, state) {
            if (state is ResumenFinancieroLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ResumenFinancieroError) {
              return Center(child: Text('Error al cargar'));
            }
            if (state is ResumenFinancieroLoaded) {
              return _buildContent(state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(ResumenFinancieroLoaded state) {
    final data = state.resumen.data;
    final graficoDiario = state.grafico?.datos ?? [];

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.blue1,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSedeSelector(),
          _buildPeriodoSelector(),
          const SizedBox(height: 12),
          _buildFlujoNeto(data),
          const SizedBox(height: 12),
          if (graficoDiario.isNotEmpty) ...[
            _buildGrafico(graficoDiario),
            const SizedBox(height: 12),
          ],
          _buildVentasCompras(data),
          const SizedBox(height: 12),
          _buildCuentasPendientes(data),
          const SizedBox(height: 12),
          _buildCajaHoy(data),
          const SizedBox(height: 12),
          if (data['tesoreria'] != null) ...[
            _buildTesoreria(data),
            const SizedBox(height: 12),
          ],
          _buildBancos(data),
          const SizedBox(height: 12),
          _buildMarketplace(data),
          const SizedBox(height: 12),
          if (data['prestamos'] != null) _buildPrestamos(data),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- SEDE ---
  /// Tabs segmentados "Toda la empresa | `sede`..." (mismo diseño que
  /// Ventas/Anuladas en la página de ventas). Solo aparece si hay más de una
  /// sede operable. Filtro local a esta pantalla (no toca la sede activa).
  Widget _buildSedeSelector() {
    final sedes = context.watch<SedeActivaCubit>().state.operables;
    if (sedes.length < 2) return const SizedBox.shrink();

    // Hasta 3 opciones reparten el ancho (como Ventas|Anuladas); con más
    // sedes el control scrollea horizontal para no aplastar los nombres.
    final expandir = sedes.length + 1 <= 3;
    final items = [
      _tabSedeItem(
        label: 'Toda la empresa',
        icon: Icons.business,
        selected: _sedeId == null,
        expanded: expandir,
        onTap: () => _seleccionarSede(null),
      ),
      ...sedes.map((s) => _tabSedeItem(
            label: s.nombre,
            icon: Icons.store,
            selected: _sedeId == s.id,
            expanded: expandir,
            onTap: () => _seleccionarSede(s.id),
          )),
    ];

    final control = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );

    if (expandir) return control;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: control,
    );
  }

  Widget _tabSedeItem({
    required String label,
    required IconData icon,
    required bool selected,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    final item = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 7, horizontal: expanded ? 0 : 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.blue1 : Colors.grey.shade500),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.blue1 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? Expanded(child: item) : item;
  }

  /// Tag para las cards que SIEMPRE son de toda la empresa (bancos, préstamos,
  /// marketplace) cuando hay una sede seleccionada: aclara que no están
  /// filtradas ni sumadas a los totales de la sede.
  Widget _empresaTag() {
    if (_sedeId == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('toda la empresa',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
    );
  }

  // --- PERIODO ---
  Widget _buildPeriodoSelector() {
    final now = DateTime.now();
    final periodos = [
      {'label': 'Hoy', 'desde': DateTime(now.year, now.month, now.day), 'hasta': now},
      {'label': 'Esta semana', 'desde': now.subtract(Duration(days: now.weekday - 1)), 'hasta': now},
      {'label': 'Este mes', 'desde': DateTime(now.year, now.month, 1), 'hasta': now},
      {'label': 'Mes anterior', 'desde': DateTime(now.year, now.month - 1, 1), 'hasta': DateTime(now.year, now.month, 0)},
      {'label': 'Este ano', 'desde': DateTime(now.year, 1, 1), 'hasta': now},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...periodos.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomFilterChip(
                  backgroundColor: AppColors.white,
                  label: p['label'] as String,
                  selected: _periodoLabel == p['label'],
                  onSelected: () => _seleccionarPeriodo(
                    p['label'] as String,
                    p['desde'] as DateTime,
                    p['hasta'] as DateTime,
                  ),
                ),
              )),
          // Rango personalizado con el CustomDate del proyecto (mismo patrón
          // que la página de Ventas), en vez del picker full-page de Material.
          SizedBox(
            width: 130,
            child: CustomDate(
              // Refresca el texto del campo cuando el período cambia por
              // fuera (chips): con un atajo activo el campo vuelve al hint.
              key: ValueKey(_periodoLabel == 'Personalizado'
                  ? '${_fechaDesde}_$_fechaHasta'
                  : 'sin-rango'),
              dateType: DateFieldType.dateRange,
              initialDateRange: _periodoLabel == 'Personalizado'
                  ? DateRange(startDate: _fechaDesde, endDate: _fechaHasta)
                  : null,
              borderColor: AppColors.blue1,
              hintText: 'Personalizado',
              height: 30,
              showDaysSelectedLabel: false,
              onDateRangeSelected: (range) {
                if (range?.startDate != null && range?.endDate != null) {
                  _seleccionarPeriodo(
                      'Personalizado', range!.startDate!, range.endDate!);
                } else {
                  // Rango limpiado → volver al default "Este mes".
                  final now = DateTime.now();
                  _seleccionarPeriodo(
                      'Este mes', DateTime(now.year, now.month, 1), now);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- GRAFICO ---
  Widget _buildGrafico(List<Map<String, dynamic>> graficoDiario) {
    final dateFormat = DateFormat('dd/MM');
    final maxIngresos = graficoDiario.fold<double>(0, (m, d) => ((d['ingresos'] as num?)?.toDouble() ?? 0) > m ? (d['ingresos'] as num).toDouble() : m);
    final maxEgresos = graficoDiario.fold<double>(0, (m, d) => ((d['egresos'] as num?)?.toDouble() ?? 0) > m ? (d['egresos'] as num).toDouble() : m);
    final maxY = (maxIngresos > maxEgresos ? maxIngresos : maxEgresos) * 1.2;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('INGRESOS VS EGRESOS', fontSize: 10, font: AppFont.amazonEmberMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(width: 12, height: 3, color: Colors.green),
                const SizedBox(width: 4),
                Text('Ingresos', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                const SizedBox(width: 12),
                Container(width: 12, height: 3, color: Colors.red),
                const SizedBox(width: 4),
                Text('Egresos', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: graficoDiario.length > 15 ? (graficoDiario.length / 5).ceil().toDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= graficoDiario.length) return const SizedBox.shrink();
                          final fecha = DateTime.tryParse(graficoDiario[idx]['fecha'] ?? '');
                          if (fecha == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(dateFormat.format(fecha), style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxY > 0 ? maxY : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: graficoDiario.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), (e.value['ingresos'] as num?)?.toDouble() ?? 0)).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(show: graficoDiario.length <= 15),
                      belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: graficoDiario.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), (e.value['egresos'] as num?)?.toDouble() ?? 0)).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: graficoDiario.length <= 15),
                      belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FLUJO NETO ---
  Widget _buildFlujoNeto(Map<String, dynamic> data) {
    final resumen = data['resumen'] as Map<String, dynamic>;
    final ingresos = (resumen['totalIngresos'] as num?)?.toDouble() ?? 0;
    final egresos = (resumen['totalEgresos'] as num?)?.toDouble() ?? 0;
    final flujo = (resumen['flujoNeto'] as num?)?.toDouble() ?? 0;

    return GradientContainer(
      borderColor: flujo >= 0 ? Colors.green.shade300 : Colors.red.shade300,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(flujo >= 0 ? Icons.trending_up : Icons.trending_down, color: flujo >= 0 ? Colors.green : Colors.red, size: 20),
                const SizedBox(width: 10),
                const AppSubtitle('FLUJO NETO DEL MES', fontSize: 10, font:AppFont.amazonEmberMedium),
              ],
            ),
            const SizedBox(height: 4),
            AppSubtitle(
              'S/ ${flujo.toStringAsFixed(2)}',
              fontSize: 20,
              color: flujo >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _miniCard('Ingresos', ingresos, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Egresos', egresos, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- VENTAS Y COMPRAS ---
  /// Columna derecha de la card VENTAS: desglose por canal, siempre los
  /// tres (Mostrador / Marketplace / Cotización) aunque estén en 0.
  Widget _canalColumna(Map<String, dynamic>? porCanal) {
    const canales = [
      ('POS', 'Mostrador (POS)', Icons.point_of_sale),
      ('ONLINE', 'Marketplace', Icons.storefront),
      ('COTIZACION', 'Cotización', Icons.request_quote_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('POR CANAL',
            style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        for (final (key, label, icon) in canales) ...[
          Builder(builder: (_) {
            final m = porCanal?[key] as Map<String, dynamic>?;
            final cantidad = m?['cantidad'] ?? 0;
            final total = (m?['total'] as num?)?.toDouble() ?? 0;
            final activo = cantidad != 0;
            final color = !activo
                ? Colors.grey.shade400
                : key == 'ONLINE'
                    ? Colors.teal.shade700
                    : Colors.grey.shade700;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 10, color: color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 8, color: color)),
                        Text('$cantidad · S/ ${_fmt(total)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildVentasCompras(Map<String, dynamic> data) {
    final ventas = data['ventas'] as Map<String, dynamic>;
    final compras = data['compras'] as Map<String, dynamic>;

    // IntrinsicHeight: ambas cards estiran a la altura de la más alta
    // (VENTAS con su columna de canales) — sin tocar fonts ni contenido.
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // VENTAS más ancha (3/5): lleva dos columnas internas
        // (totales | por canal).
        Expanded(
          flex: 3,
          child: GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: totales del período.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.point_of_sale, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            const AppSubtitle('VENTAS', fontSize: 10, font: AppFont.amazonEmberMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AppSubtitle('S/ ${_fmt(ventas['totalVentas'])}', fontSize: 13, color: Colors.green),
                        Text('${ventas['cantidad']} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('Cobrado: S/ ${_fmt(ventas['totalCobrado'])}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        if ((ventas['pendienteCobro'] as num?)?.toDouble() != 0)
                          Text('Pendiente: S/ ${_fmt(ventas['pendienteCobro'])}', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),
                  // Separador vertical + columna derecha: por canal.
                  Container(
                    width: 0.6,
                    height: 74,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: AppColors.blueborder.withValues(alpha: 0.5),
                  ),
                  Flexible(
                    child: _canalColumna(
                        ventas['porCanal'] as Map<String, dynamic>?),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      const AppSubtitle('COMPRAS', fontSize: 10, font: AppFont.amazonEmberMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppSubtitle('S/ ${_fmt(compras['totalCompras'])}', fontSize: 13, color: Colors.red),
                  Text('${compras['cantidad']} compras', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Pagado: S/ ${_fmt(compras['totalPagado'])}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  if ((compras['pendientePago'] as num?)?.toDouble() != 0)
                    Text('Pendiente: S/ ${_fmt(compras['pendientePago'])}', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  // --- CUENTAS PENDIENTES ---
  Widget _buildCuentasPendientes(Map<String, dynamic> data) {
    final cobrar = data['cuentasPorCobrar'] as Map<String, dynamic>;
    final pagar = data['cuentasPorPagar'] as Map<String, dynamic>;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('CUENTAS PENDIENTES', fontSize: 10, font: AppFont.amazonEmberMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text('Por cobrar', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                      AppSubtitle('S/ ${_fmt(cobrar['total'])}', fontSize: 13, color: Colors.green),
                      if ((cobrar['totalVencido'] as num?)?.toDouble() != 0)
                        Text('Vencido: S/ ${_fmt(cobrar['totalVencido'])}', style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 4),
                          Text('Por pagar', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                      AppSubtitle('S/ ${_fmt(pagar['total'])}', fontSize: 13, color: Colors.red),
                      if ((pagar['totalVencido'] as num?)?.toDouble() != 0)
                        Text('Vencido: S/ ${_fmt(pagar['totalVencido'])}', style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            // Desglose por naturaleza de la deuda: crédito programado vs
            // compras CONTADO confirmadas sin pagar (exigibles YA).
            if (((pagar['totalContadoImpago'] as num?)?.toDouble() ?? 0) > 0 ||
                ((pagar['totalCredito'] as num?)?.toDouble() ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Crédito: S/ ${_fmt(pagar['totalCredito'])}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700),
                      ),
                    ),
                    if (((pagar['totalContadoImpago'] as num?)?.toDouble() ?? 0) > 0)
                      Expanded(
                        child: Text(
                          'Contado sin pagar (${pagar['cantidadContadoImpago']}): S/ ${_fmt(pagar['totalContadoImpago'])}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- CAJA HOY ---
  Widget _buildCajaHoy(Map<String, dynamic> data) {
    final caja = data['caja'] as Map<String, dynamic>;
    // Desglose: cajas físicas (POS) vs tesorería/marketplace (digital que
    // vive en el banco, no pasó por el cajón). Fallback a totales si el
    // backend aún no manda el desglose.
    final operativas = caja['operativas'] as Map<String, dynamic>?;
    final tesoreriaHoy = caja['tesoreriaHoy'] as Map<String, dynamic>?;
    final ingresos = ((operativas?['ingresos'] ?? caja['ingresosHoy']) as num?)
            ?.toDouble() ??
        0;
    final egresos = ((operativas?['egresos'] ?? caja['egresosHoy']) as num?)
            ?.toDouble() ??
        0;
    final flujo =
        ((operativas?['flujo'] ?? caja['flujoHoy']) as num?)?.toDouble() ?? 0;
    final tesIngresos = (tesoreriaHoy?['ingresos'] as num?)?.toDouble() ?? 0;
    final tesEgresos = (tesoreriaHoy?['egresos'] as num?)?.toDouble() ?? 0;
    final tesFlujo = (tesoreriaHoy?['flujo'] as num?)?.toDouble() ?? 0;
    final hayTesoreria = tesIngresos != 0 || tesEgresos != 0;
    final abiertas = caja['cajasAbiertas'] as int? ?? 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('CAJAS (POS) HOY', fontSize: 10, font: AppFont.amazonEmberMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: abiertas > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$abiertas caja${abiertas != 1 ? 's' : ''} abierta${abiertas != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, color: abiertas > 0 ? Colors.green : Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Solo el dinero que fluyó por los CAJONES de los cajeros.
            Row(
              children: [
                Expanded(child: _miniCard('Ingresos', ingresos, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Egresos', egresos, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Flujo', flujo, flujo >= 0 ? Colors.green : Colors.red)),
              ],
            ),
            // Flujo de TESORERÍA/MARKETPLACE del día: cobros Yape de pedidos
            // y sus devoluciones — dinero que vive en el banco, NO en los
            // cajones. Se muestra aparte para no confundirlo con caja.
            if (hayTesoreria) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront, size: 13, color: Colors.teal.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Marketplace / Tesorería (digital → banco)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+${tesIngresos.toStringAsFixed(2)}  −${tesEgresos.toStringAsFixed(2)}  = S/ ${tesFlujo.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tesFlujo >= 0
                              ? Colors.teal.shade800
                              : Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TESORERÍA / LIQUIDEZ ---
  /// Dónde está la plata HOY: bóveda(s) de efectivo (Caja Central), efectivo
  /// en cajas abiertas, float de cajas chicas y bancos. El total es la
  /// liquidez consolidada de la empresa (no depende del período elegido).
  Widget _buildTesoreria(Map<String, dynamic> data) {
    final t = data['tesoreria'] as Map<String, dynamic>;
    final bovedas = (t['saldoBovedas'] as num?)?.toDouble() ?? 0;
    final cajasAbiertas = (t['efectivoCajasAbiertas'] as num?)?.toDouble() ?? 0;
    final cajaChica = (t['saldoCajaChica'] as num?)?.toDouble() ?? 0;
    final bancos = (t['saldoBancos'] as num?)?.toDouble() ?? 0;
    final liquidez = (t['liquidezTotal'] as num?)?.toDouble() ?? 0;
    // Con sede seleccionada, los bancos (empresa) NO suman a la liquidez.
    final incluyeBancos = t['incluyeBancos'] as bool? ?? true;

    Widget fila(String label, double monto, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            ),
            Text(
              'S/ ${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: monto >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(incluyeBancos ? 'LIQUIDEZ (HOY)' : 'LIQUIDEZ DE SEDE (HOY)',
                    fontSize: 10, font: AppFont.amazonEmberMedium),
                const Spacer(),
                AppSubtitle('S/ ${liquidez.toStringAsFixed(2)}',
                    fontSize: 11, color: AppColors.blue1),
              ],
            ),
            const SizedBox(height: 8),
            fila('Bóveda (Caja Central)', bovedas, Icons.lock_outline),
            fila('Efectivo en cajas abiertas', cajasAbiertas, Icons.point_of_sale),
            fila('Caja chica', cajaChica, Icons.wallet_outlined),
            fila(
              incluyeBancos ? 'Bancos' : 'Bancos (empresa, no suma)',
              bancos,
              Icons.account_balance,
            ),
          ],
        ),
      ),
    );
  }

  // --- BANCOS ---
  Widget _buildBancos(Map<String, dynamic> data) {
    final bancos = data['bancos'] as Map<String, dynamic>;
    final cuentas = bancos['cuentas'] as List<dynamic>? ?? [];
    final totalSaldo = (bancos['totalSaldo'] as num?)?.toDouble() ?? 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('CUENTAS BANCARIAS', fontSize: 10, font: AppFont.amazonEmberMedium),
                _empresaTag(),
                const Spacer(),
                AppSubtitle('S/ ${totalSaldo.toStringAsFixed(2)}', fontSize: 11, color: AppColors.blue1),
              ],
            ),
            if (cuentas.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...cuentas.map((c) {
                final cuenta = c as Map<String, dynamic>;
                final saldo = (cuenta['saldoActual'] as num?)?.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      if (cuenta['esPrincipal'] == true)
                        Icon(Icons.star, size: 12, color: Colors.amber.shade600)
                      else
                        const SizedBox(width: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text('${cuenta['nombreBanco']} (${cuenta['moneda']})', style: TextStyle(fontSize: 11, color: Colors.grey.shade700))),
                      if (saldo != null)
                        Text('S/ ${saldo.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: saldo >= 0 ? Colors.green : Colors.red)),
                    ],
                  ),
                );
              }),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin cuentas registradas', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
          ],
        ),
      ),
    );
  }

  // --- MARKETPLACE ---
  Widget _buildMarketplace(Map<String, dynamic> data) {
    final mp = data['pedidosMarketplace'] as Map<String, dynamic>;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                const AppSubtitle('MARKETPLACE', fontSize: 10, color: Colors.teal, font: AppFont.amazonEmberMedium),
                _empresaTag(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _miniCard('Total', (mp['totalPedidos'] as num?)?.toDouble() ?? 0, Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Validado', (mp['totalValidado'] as num?)?.toDouble() ?? 0, Colors.green)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${mp['cantidad']} pedidos - ${mp['pedidosPendientes']} pendientes - ${mp['pedidosEntregados']} entregados',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // --- PRESTAMOS ---
  Widget _buildPrestamos(Map<String, dynamic> data) {
    final p = data['prestamos'] as Map<String, dynamic>;
    final deuda = (p['totalDeuda'] as num?)?.toDouble() ?? 0;
    final original = (p['totalOriginal'] as num?)?.toDouble() ?? 0;
    final pagado = (p['totalPagado'] as num?)?.toDouble() ?? 0;
    final porcentaje = (p['porcentajePagado'] as num?)?.toInt() ?? 0;
    final activos = p['cantidadActivos'] as int? ?? 0;

    if (activos == 0) return const SizedBox.shrink();

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.brown),
                const SizedBox(width: 6),
                const AppSubtitle('PRESTAMOS', fontSize: 11, color: Colors.brown),
                _empresaTag(),
                const Spacer(),
                Text('$activos activo${activos != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _miniCard('Deuda total', deuda, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Pagado', pagado, Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: original > 0 ? pagado / original : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(porcentaje >= 100 ? Colors.green : Colors.brown),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text('$porcentaje% pagado de S/ ${original.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _miniCard(String label, double monto, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('S/ ${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _fmt(dynamic value) => ((value as num?)?.toDouble() ?? 0).toStringAsFixed(2);
}
