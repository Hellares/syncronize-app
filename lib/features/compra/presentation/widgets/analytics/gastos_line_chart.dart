import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/compra_analytics.dart';

class GastosLineChart extends StatelessWidget {
  final List<GastoPeriodo> gastos;

  const GastosLineChart({super.key, required this.gastos});

  @override
  Widget build(BuildContext context) {
    if (gastos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos de gastos', style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    final maxY = gastos.fold<double>(0, (max, g) => g.total > max ? g.total : max);
    final spots = gastos.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.total);
    }).toList();
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: gastos.length > 6 ? (gastos.length / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= gastos.length) return const SizedBox.shrink();
                  final label = gastos[idx].periodo;
                  final short = label.length > 7 ? label.substring(label.length - 5) : label;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(short, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: maxY > 0 ? maxY / 4 : 1,
                getTitlesWidget: (value, meta) {
                  return Text(_formatAmount(value), style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (gastos.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue.shade600,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: gastos.length <= 12,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(radius: 3, color: Colors.blue.shade600, strokeColor: Colors.white, strokeWidth: 1.5),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.shade100.withValues(alpha: 0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final gasto = gastos[spot.spotIndex];
                  return LineTooltipItem(
                    '${gasto.periodo}\nS/ ${_formatAmount(gasto.total)}\n${gasto.cantidad} compras',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
