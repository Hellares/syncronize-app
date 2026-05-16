import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/reporte_gastos.dart';
import '../bloc/reportes_cubit.dart';
import '../bloc/reportes_state.dart';

class GastosRecurrentesReportesPage extends StatelessWidget {
  const GastosRecurrentesReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ReportesGastosCubit>()..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static final _money = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);
  static final _moneyCompact = NumberFormat.compactCurrency(locale: 'es_PE', symbol: 'S/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Reportes de Gastos',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocConsumer<ReportesGastosCubit, ReportesGastosState>(
          listener: (context, state) {
            if (state is ReportesGastosError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is ReportesGastosLoading || state is ReportesGastosInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ReportesGastosError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () => context.read<ReportesGastosCubit>().reload(),
                    ),
                  ],
                ),
              );
            }
            if (state is ReportesGastosLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<ReportesGastosCubit>().reload(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _cardTotalMesActual(context, state.data.mesActual),
                    const SizedBox(height: 16),
                    _cardEvolucion(state.data.evolucionMensual, state.meses),
                    const SizedBox(height: 16),
                    _cardBreakdown(state.data.mesActual),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _cardTotalMesActual(BuildContext context, ReporteMesActual mes) {
    final parts = mes.periodo.split('-');
    final anio = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final mesLabel = DateFormat.yMMMM('es_PE').format(DateTime(anio, m));

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.blue1, size: 18),
              const SizedBox(width: 8),
              Text(
                'Total operativo · ${mesLabel[0].toUpperCase()}${mesLabel.substring(1)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _money.format(mes.totalGastado),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mes.porCategoria.length} categoría${mes.porCategoria.length == 1 ? '' : 's'} con gasto',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _cardEvolucion(List<ReporteEvolucionMes> evolucion, int meses) {
    if (evolucion.isEmpty || evolucion.every((e) => e.total == 0)) {
      return GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.show_chart, color: AppColors.blue1, size: 18),
                SizedBox(width: 8),
                Text(
                  'Evolución mensual',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Sin pagos registrados en los últimos $meses meses',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final maxTotal = evolucion.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final spots = <FlSpot>[];
    for (var i = 0; i < evolucion.length; i++) {
      spots.add(FlSpot(i.toDouble(), evolucion[i].total));
    }

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppColors.blue1, size: 18),
              const SizedBox(width: 8),
              Text(
                'Evolución mensual · últimos $meses meses',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxTotal * 1.15,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.blue1.withValues(alpha: 0.9),
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      if (idx < 0 || idx >= evolucion.length) return null;
                      final e = evolucion[idx];
                      return LineTooltipItem(
                        '${e.periodo}\n${_money.format(e.total)}',
                        const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxTotal / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.grey.withValues(alpha: 0.2),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxTotal / 4,
                      getTitlesWidget: (value, _) {
                        return Text(
                          _moneyCompact.format(value),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (evolucion.length / 6).ceilToDouble().clamp(1, 6),
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= evolucion.length) return const SizedBox.shrink();
                        final partes = evolucion[i].periodo.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${_mesCorto(int.parse(partes[1]))}\n${partes[0].substring(2)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.blue1,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.blue1,
                        strokeWidth: 1.5,
                        strokeColor: AppColors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.blue1.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBreakdown(ReporteMesActual mes) {
    if (mes.porCategoria.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxMonto = mes.porCategoria.first.monto;
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart, color: AppColors.blue1, size: 18),
              SizedBox(width: 8),
              Text(
                'Por categoría — mes actual',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...mes.porCategoria.map((c) => _categoriaRow(c, maxMonto)),
        ],
      ),
    );
  }

  Widget _categoriaRow(ReporteCategoriaMes c, double maxMonto) {
    final color = _parseColor(c.color) ?? AppColors.blue1;
    final pct = maxMonto > 0 ? (c.monto / maxMonto) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_parseIcon(c.icono), size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.nombre,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                _money.format(c.monto),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _mesCorto(int m) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[(m - 1).clamp(0, 11)];
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed == null) return null;
    return Color(clean.length == 6 ? 0xFF000000 | parsed : parsed);
  }

  IconData _parseIcon(String? icono) {
    if (icono == null) return Icons.category;
    final cp = int.tryParse(icono);
    if (cp == null) return Icons.category;
    return IconData(cp, fontFamily: 'MaterialIcons');
  }
}
