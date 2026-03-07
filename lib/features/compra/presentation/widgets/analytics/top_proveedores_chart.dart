import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/compra_analytics.dart';

class TopProveedoresChart extends StatelessWidget {
  final List<ProveedorTop> proveedores;

  const TopProveedoresChart({super.key, required this.proveedores});

  static const _colors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    if (proveedores.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos de proveedores', style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }

    final top = proveedores.take(6).toList();
    final total = top.fold<double>(0, (sum, p) => sum + p.montoTotal);

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: top.asMap().entries.map((e) {
                  final pct = total > 0 ? (e.value.montoTotal / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: e.value.montoTotal,
                    color: _colors[e.key % _colors.length],
                    radius: 50,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: top.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[e.key % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.value.nombre,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'S/ ${_formatAmount(e.value.montoTotal)}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }
}
