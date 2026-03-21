import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<ResumenFinancieroCubit>().loadResumen(
          fechaDesde: _fechaDesde.toIso8601String(),
          fechaHasta: _fechaHasta.toIso8601String(),
        );
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
          ...periodos.map((p) {
            final isSelected = _periodoLabel == p['label'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(p['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.blue1)),
                selected: isSelected,
                selectedColor: AppColors.blue1,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                side: BorderSide(color: isSelected ? AppColors.blue1 : Colors.grey.shade300),
                onSelected: (_) => _seleccionarPeriodo(p['label'] as String, p['desde'] as DateTime, p['hasta'] as DateTime),
              ),
            );
          }),
          FilterChip(
            label: Text('Personalizado', style: TextStyle(fontSize: 11, color: _periodoLabel == 'Personalizado' ? Colors.white : AppColors.blue1)),
            selected: _periodoLabel == 'Personalizado',
            selectedColor: AppColors.blue1,
            backgroundColor: Colors.white,
            checkmarkColor: Colors.white,
            side: BorderSide(color: _periodoLabel == 'Personalizado' ? AppColors.blue1 : Colors.grey.shade300),
            onSelected: (_) async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: _fechaDesde, end: _fechaHasta),
              );
              if (picked != null) {
                _seleccionarPeriodo('Personalizado', picked.start, picked.end);
              }
            },
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('INGRESOS VS EGRESOS', fontSize: 11, color: AppColors.blue1),
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
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(flujo >= 0 ? Icons.trending_up : Icons.trending_down, color: flujo >= 0 ? Colors.green : Colors.red, size: 24),
                const SizedBox(width: 10),
                const AppSubtitle('FLUJO NETO DEL MES', fontSize: 12),
              ],
            ),
            const SizedBox(height: 12),
            AppSubtitle(
              'S/ ${flujo.toStringAsFixed(2)}',
              fontSize: 28,
              color: flujo >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
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
  Widget _buildVentasCompras(Map<String, dynamic> data) {
    final ventas = data['ventas'] as Map<String, dynamic>;
    final compras = data['compras'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.point_of_sale, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      const AppSubtitle('VENTAS', fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppSubtitle('S/ ${_fmt(ventas['totalVentas'])}', fontSize: 18, color: Colors.green),
                  Text('${ventas['cantidad']} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Cobrado: S/ ${_fmt(ventas['totalCobrado'])}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  if ((ventas['pendienteCobro'] as num?)?.toDouble() != 0)
                    Text('Pendiente: S/ ${_fmt(ventas['pendienteCobro'])}', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      const AppSubtitle('COMPRAS', fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppSubtitle('S/ ${_fmt(compras['totalCompras'])}', fontSize: 18, color: Colors.red),
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
    );
  }

  // --- CUENTAS PENDIENTES ---
  Widget _buildCuentasPendientes(Map<String, dynamic> data) {
    final cobrar = data['cuentasPorCobrar'] as Map<String, dynamic>;
    final pagar = data['cuentasPorPagar'] as Map<String, dynamic>;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('CUENTAS PENDIENTES', fontSize: 11, color: AppColors.blue1),
            const SizedBox(height: 10),
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
                          Text('Por cobrar', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      AppSubtitle('S/ ${_fmt(cobrar['total'])}', fontSize: 16, color: Colors.green),
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
                          Text('Por pagar', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      AppSubtitle('S/ ${_fmt(pagar['total'])}', fontSize: 16, color: Colors.red),
                      if ((pagar['totalVencido'] as num?)?.toDouble() != 0)
                        Text('Vencido: S/ ${_fmt(pagar['totalVencido'])}', style: TextStyle(fontSize: 10, color: Colors.red.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CAJA HOY ---
  Widget _buildCajaHoy(Map<String, dynamic> data) {
    final caja = data['caja'] as Map<String, dynamic>;
    final ingresos = (caja['ingresosHoy'] as num?)?.toDouble() ?? 0;
    final egresos = (caja['egresosHoy'] as num?)?.toDouble() ?? 0;
    final flujo = (caja['flujoHoy'] as num?)?.toDouble() ?? 0;
    final abiertas = caja['cajasAbiertas'] as int? ?? 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('CAJA HOY', fontSize: 11, color: AppColors.blue1),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: abiertas > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$abiertas caja${abiertas != 1 ? 's' : ''} abierta${abiertas != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, color: abiertas > 0 ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _miniCard('Ingresos', ingresos, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Egresos', egresos, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _miniCard('Flujo', flujo, flujo >= 0 ? Colors.green : Colors.red)),
              ],
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const AppSubtitle('CUENTAS BANCARIAS', fontSize: 11, color: AppColors.blue1),
                const Spacer(),
                AppSubtitle('S/ ${totalSaldo.toStringAsFixed(2)}', fontSize: 14, color: AppColors.blue1),
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
                const AppSubtitle('MARKETPLACE', fontSize: 11, color: Colors.teal),
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
