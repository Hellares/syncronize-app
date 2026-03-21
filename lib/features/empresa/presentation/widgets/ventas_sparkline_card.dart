import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_state.dart';

class VentasSparklineCard extends StatelessWidget {
  const VentasSparklineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(14),
      child: BlocBuilder<ResumenFinancieroCubit, ResumenFinancieroState>(
        builder: (context, state) {
          if (state is ResumenFinancieroLoading ||
              state is ResumenFinancieroInitial) {
            return const SizedBox(
              height: 130,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            );
          }
          if (state is ResumenFinancieroError) {
            return SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'No se pudo cargar datos',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            );
          }
          if (state is ResumenFinancieroLoaded) {
            return _buildContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(ResumenFinancieroLoaded state) {
    final graficoDiario = state.grafico?.datos ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, size: 16, color: AppColors.blue1),
            const SizedBox(width: 6),
            const AppSubtitle('Ventas del Mes',
                fontSize: 12, color: AppColors.blue1),
          ],
        ),
        const SizedBox(height: 12),
        if (graficoDiario.isEmpty)
          SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Sin datos de ventas',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          )
        else
          _buildChart(graficoDiario),
      ],
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> graficoDiario) {
    final dateFormat = DateFormat('dd/MM');
    final spots = graficoDiario.asMap().entries.map((e) {
      final ingresos = (e.value['ingresos'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), ingresos);
    }).toList();

    final maxY = spots.fold<double>(
            0, (m, s) => s.y > m ? s.y : m) *
        1.2;

    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx != 0 && idx != graficoDiario.length - 1) {
                    return const SizedBox.shrink();
                  }
                  if (idx < 0 || idx >= graficoDiario.length) {
                    return const SizedBox.shrink();
                  }
                  final fecha = DateTime.tryParse(
                      graficoDiario[idx]['fecha'] ?? '');
                  if (fecha == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dateFormat.format(fecha),
                      style: TextStyle(
                          fontSize: 8, color: Colors.grey.shade500),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY > 0 ? maxY : 100,
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.green,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.green.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
