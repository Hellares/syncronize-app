import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../domain/entities/compra_analytics.dart';

class ComparativoCostosCard extends StatelessWidget {
  final ComparativoCosto comparativo;

  const ComparativoCostosCard({super.key, required this.comparativo});

  @override
  Widget build(BuildContext context) {
    final isPositive = comparativo.porcentajeCambio > 0;
    final isNeutral = comparativo.porcentajeCambio == 0;
    final changeColor = isNeutral
        ? Colors.grey
        : isPositive
            ? Colors.red.shade600
            : Colors.green.shade600;
    final changeIcon = isNeutral
        ? Icons.remove
        : isPositive
            ? Icons.trending_up
            : Icons.trending_down;

    final df = DateFormat('dd/MM/yy');

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(changeIcon, color: changeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${comparativo.porcentajeCambio.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPositive ? 'mas que antes' : isNeutral ? 'sin cambios' : 'menos que antes',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PeriodoColumn(
                    label: 'Periodo Actual',
                    fechas: '${df.format(comparativo.periodoActual.inicio)} - ${df.format(comparativo.periodoActual.fin)}',
                    total: comparativo.periodoActual.total,
                    cantidad: comparativo.periodoActual.cantidad,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _PeriodoColumn(
                    label: 'Periodo Anterior',
                    fechas: '${df.format(comparativo.periodoAnterior.inicio)} - ${df.format(comparativo.periodoAnterior.fin)}',
                    total: comparativo.periodoAnterior.total,
                    cantidad: comparativo.periodoAnterior.cantidad,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodoColumn extends StatelessWidget {
  final String label;
  final String fechas;
  final double total;
  final int cantidad;
  final Color color;

  const _PeriodoColumn({
    required this.label,
    required this.fechas,
    required this.total,
    required this.cantidad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          fechas,
          style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          'S/ ${_formatAmount(total)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          '$cantidad compras',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }
}
