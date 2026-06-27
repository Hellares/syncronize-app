import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/resumen_caja.dart';

/// Card que muestra el resumen de la caja con totales de ingresos, egresos y saldo
class ResumenCajaCard extends StatelessWidget {
  final ResumenCaja resumen;
  final double montoApertura;

  const ResumenCajaCard({
    super.key,
    required this.resumen,
    this.montoApertura = 0,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle(
            'RESUMEN DE CAJA',
            fontSize: 10,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 10),
          // Monto apertura
          if (montoApertura > 0) ...[
            _buildResumenRow(
              'Monto Apertura',
              currencyFormat.format(montoApertura),
              AppColors.blue2,
            ),
            const Divider(height: 14),
          ],
          // Total Ingresos
          _buildResumenRow(
            'Total Ingresos',
            currencyFormat.format(resumen.totalIngresos),
            AppColors.green,
          ),
          // Nota informativa: si hubo anulaciones, recordar al cajero
          // que ese monto YA fue descontado de Ingresos (el INGRESO
          // original quedó anulado, no es un egreso aparte).
          if (resumen.egresoAnulacionVenta > 0) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '(− ${currencyFormat.format(resumen.egresoAnulacionVenta)} anulados)',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Total Egresos
          _buildResumenRow(
            'Total Egresos',
            currencyFormat.format(resumen.totalEgresos),
            AppColors.red,
          ),
          // Desglose por categoría — solo egresos manuales reales.
          ...resumen.egresosPorCategoria.map((e) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '· ${e.label}'
                      '${e.cantidad > 0 ? " (${e.cantidad})" : ""}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      currencyFormat.format(e.total),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              )),
          // Bloque informativo de anulaciones — NO suma a Total Egresos
          // (es un ingreso revertido, ya descontado arriba).
          if (resumen.egresoAnulacionVenta > 0) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Anulación de Venta'
                            '${resumen.cantidadAnulaciones > 0 ? " (${resumen.cantidadAnulaciones})" : ""}'
                            ' — ya descontado de Ingresos',
                            style: TextStyle(
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(resumen.egresoAnulacionVenta),
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 20),
          // Saldo en Caja: lo fisico en la gaveta (EFECTIVO + apertura).
          // Es lo que el cajero deberia contar al cerrar.
          _buildResumenRow(
            'Saldo en Caja',
            currencyFormat.format(resumen.saldoEfectivo),
            resumen.saldoEfectivo >= 0 ? AppColors.green : AppColors.red,
            isBold: true,
          ),
          // Medios Digitales = saldo total - efectivo. Cubre YAPE, PLIN,
          // TARJETA, TRANSFERENCIA. Si no hubo cobros digitales, ocultamos
          // las dos lineas para no llenar de ruido.
          if ((resumen.saldo - resumen.saldoEfectivo).abs() > 0.01) ...[
            const SizedBox(height: 8),
            _buildResumenRow(
              'Medios Digitales',
              currencyFormat.format(resumen.saldo - resumen.saldoEfectivo),
              AppColors.blue2,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.5),
            ),
            _buildResumenRow(
              'Total Operado',
              currencyFormat.format(resumen.saldo),
              AppColors.blue1,
              isBold: true,
            ),
          ],
          // Detalles por metodo de pago — solo mostramos métodos con
          // actividad real (ingresos > 0 ó egresos > 0). EFECTIVO siempre
          // aparece aunque esté en 0 si hubo apertura (apertura inflada en
          // saldo).
          if (resumen.detalles.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const AppSubtitle(
              'Por Metodo de Pago',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            // Header de columnas: Ingresos / Egresos / Saldo.
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: Text(
                      'Ingresos',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Egresos',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Saldo',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...resumen.detalles
                .where((d) => d.totalIngresos > 0 || d.totalEgresos > 0)
                .map((detalle) => _buildMetodoRow(detalle, currencyFormat)),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Fila de método con icono + nombre a la izquierda y 3 columnas a la
  /// derecha: ingresos (verde) / egresos (rojo) / saldo (negro destacado).
  /// Si una columna es 0 se muestra como "—" gris para reducir ruido.
  Widget _buildMetodoRow(ResumenMetodoPago d, NumberFormat fmt) {
    String formatOrDash(double v) => v.abs() < 0.01 ? '—' : fmt.format(v);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(d.metodoPago.icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              d.metodoPago.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              formatOrDash(d.totalIngresos),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: d.totalIngresos > 0
                    ? AppColors.green
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: Text(
              formatOrDash(d.totalEgresos),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: d.totalEgresos > 0
                    ? AppColors.red
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: Text(
              fmt.format(d.saldo),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: d.saldo > 0
                    ? AppColors.textPrimary
                    : (d.saldo < 0 ? AppColors.red : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
