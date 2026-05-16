import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';

import '../utils/movimiento_grouping.dart';

/// Bottom sheet con detalle del grupo de movimientos. Muestra:
/// - Cabecera con codigo de venta (si aplica) o categoria.
/// - Lista de items con metodo de pago, hora y monto parcial.
/// - Total.
/// - Boton "Ir a venta" cuando el grupo pertenece a una venta.
void showMovimientoDetalleSheet(BuildContext context, MovimientoGroup group) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      final currency = NumberFormat.currency(
        locale: 'es_PE',
        symbol: 'S/ ',
        decimalDigits: 2,
      );

      final isIngreso = group.tipo.apiValue == 'INGRESO';
      final signo = isIngreso ? '+' : '-';

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: group.tipo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(group.categoria.icon,
                        color: group.tipo.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle(
                          group.ventaCodigo != null
                              ? 'Venta ${group.ventaCodigo}'
                              : group.categoria.label,
                          fontSize: 14,
                          color: AppColors.blue3,
                        ),
                        Text(
                          DateFormatter.formatDateTime(group.fechaMovimiento),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const AppSubtitle(
                'DESGLOSE POR METODO',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              ...group.items.map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(m.metodoPago.icon,
                          size: 18, color: AppColors.blue3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.metodoPago.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        currency.format(m.monto),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isIngreso ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$signo ${currency.format(group.montoTotal)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIngreso ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
              if (group.ventaId != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      context.push('/empresa/ventas/${group.ventaId}');
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Ver venta completa'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
