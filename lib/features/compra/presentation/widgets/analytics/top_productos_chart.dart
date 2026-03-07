import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/compra_analytics.dart';

class TopProductosChart extends StatelessWidget {
  final List<ProductoTop> productos;

  const TopProductosChart({super.key, required this.productos});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos de productos', style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    final top = productos.take(5).toList();
    final maxCosto = top.fold<double>(0, (max, p) => p.costoTotal > max ? p.costoTotal : max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCosto * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = top[groupIndex];
                return BarTooltipItem(
                  '${p.nombre}\nS/ ${p.costoTotal.toStringAsFixed(2)}\n${p.cantidad} uds',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: maxCosto > 0 ? maxCosto / 3 : 1,
                getTitlesWidget: (value, meta) =>
                    Text(_formatAmount(value), style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                  final name = top[idx].nombre;
                  final short = name.length > 8 ? '${name.substring(0, 8)}...' : name;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(short, style: const TextStyle(fontSize: 8), textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCosto > 0 ? maxCosto / 3 : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: top.asMap().entries.map((e) {
            final colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.red];
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.costoTotal,
                  color: colors[e.key % colors.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
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
