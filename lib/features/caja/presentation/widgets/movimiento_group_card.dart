import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';

import '../../domain/entities/movimiento_caja.dart';
import '../utils/movimiento_grouping.dart';
import 'movimiento_detalle_sheet.dart';

/// Renderiza un grupo de movimientos: si es de 1 item se ve como un
/// item normal; si es agrupado (venta multi-pago) muestra el total y
/// chips de los metodos con su parcial. Tap abre el bottom sheet con
/// desglose y boton para ir a la venta.
///
/// Variante `compact` para "Movimientos Recientes" del dashboard
/// (tipografias y paddings menores).
class MovimientoGroupCard extends StatelessWidget {
  final MovimientoGroup group;
  final NumberFormat currencyFormat;
  final bool compact;

  const MovimientoGroupCard({
    super.key,
    required this.group,
    required this.currencyFormat,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIngreso = group.tipo == TipoMovimientoCaja.ingreso;
    final isAnulado = group.first.anulado;

    return InkWell(
      onTap: () => showMovimientoDetalleSheet(context, group),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
        child: Opacity(
          opacity: isAnulado ? 0.5 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 6 : 8),
                decoration: BoxDecoration(
                  color: group.tipo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  group.categoria.icon,
                  size: compact ? 16 : 18,
                  color: group.tipo.color,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(group),
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        decoration:
                            isAnulado ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (group.isGrouped)
                      _buildMetodosChips(compact)
                    else
                      Text(
                        '${group.first.metodoPago.label} · ${DateFormatter.formatDateTime(group.fechaMovimiento)}',
                        style: TextStyle(
                          fontSize: compact ? 10 : 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isIngreso ? '+' : '-'} ${currencyFormat.format(group.montoTotal)}',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: isIngreso ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(MovimientoGroup g) {
    if (g.ventaCodigo != null) return 'Venta ${g.ventaCodigo}';
    final descripcion = g.first.descripcion;
    if (descripcion != null && descripcion.isNotEmpty) return descripcion;
    return g.categoria.label;
  }

  Widget _buildMetodosChips(bool compact) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: group.items.map((m) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.metodoPago.icon,
                  size: compact ? 10 : 11, color: AppColors.blue3),
              const SizedBox(width: 3),
              Text(
                '${m.metodoPago.label} ${currencyFormat.format(m.monto)}',
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
