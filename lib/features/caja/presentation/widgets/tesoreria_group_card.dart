import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../utils/tesoreria_grouping.dart';

/// Card que renderiza un [TesoreriaGroup]:
///  - Si es grupo de 1: fila simple igual a un movimiento suelto.
///  - Si es grupo de N: header (titulo + monto total) + chips por metodo
///    con el desglose (ej. "💵 Efectivo +S/150,00", "📱 Yape +S/30,00").
class TesoreriaGroupCard extends StatelessWidget {
  final TesoreriaGroup group;

  const TesoreriaGroupCard({super.key, required this.group});

  String _money(double v) => 'S/ ${v.toStringAsFixed(2)}';

  Color get _color =>
      group.esIngreso ? AppColors.greendark : AppColors.red;
  String get _signo => group.esIngreso ? '+' : '-';

  @override
  Widget build(BuildContext context) {
    if (!group.isGrouped) {
      return _singleTile(group.items.first);
    }
    return _groupedCard();
  }

  Widget _singleTile(MovimientoCaja mov) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _color.withValues(alpha: 0.12),
        child: Icon(mov.categoria.icon, color: _color, size: 18),
      ),
      title: Text(
        group.titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: mov.anulado ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.subtitulo != null && group.subtitulo!.isNotEmpty)
            Text(
              group.subtitulo!,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(mov.metodoPago.icon,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                mov.metodoPago.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormatter.formatDateTime(mov.fechaMovimiento),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (mov.anulado) ...[
                const SizedBox(width: 8),
                _badgeAnulado(),
              ],
            ],
          ),
        ],
      ),
      trailing: Text(
        '$_signo${_money(group.montoTotal)}',
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _groupedCard() {
    final iconCategoria = group.items.first.categoria.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _color.withValues(alpha: 0.15),
                    child: Icon(iconCategoria, color: _color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (group.subtitulo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${group.subtitulo!} · ${DateFormatter.formatDateTime(group.items.first.fechaMovimiento)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '$_signo${_money(group.montoTotal)}',
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // Desglose por método (chips inline)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.items.map((m) => _MetodoChip(
                  metodo: m.metodoPago,
                  monto: m.monto,
                  signo: _signo,
                  color: _color,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeAnulado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'ANULADO',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetodoChip extends StatelessWidget {
  final MetodoPago metodo;
  final double monto;
  final String signo;
  final Color color;

  const _MetodoChip({
    required this.metodo,
    required this.monto,
    required this.signo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metodo.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            metodo.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            '$signo S/${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
