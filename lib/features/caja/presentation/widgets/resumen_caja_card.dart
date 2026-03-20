import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/movimiento_caja.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle(
            'Resumen de Caja',
            fontSize: 16,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 16),
          // Monto apertura
          if (montoApertura > 0) ...[
            _buildResumenRow(
              'Monto Apertura',
              currencyFormat.format(montoApertura),
              AppColors.blue2,
            ),
            const Divider(height: 16),
          ],
          // Total Ingresos
          _buildResumenRow(
            'Total Ingresos',
            currencyFormat.format(resumen.totalIngresos),
            AppColors.green,
          ),
          const SizedBox(height: 8),
          // Total Egresos
          _buildResumenRow(
            'Total Egresos',
            currencyFormat.format(resumen.totalEgresos),
            AppColors.red,
          ),
          const Divider(height: 20),
          // Saldo
          _buildResumenRow(
            'Saldo en Caja',
            currencyFormat.format(resumen.saldo + montoApertura),
            resumen.saldo >= 0 ? AppColors.green : AppColors.red,
            isBold: true,
          ),
          // Detalles por metodo de pago
          if (resumen.detalles.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const AppSubtitle(
              'Por Metodo de Pago',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            ...resumen.detalles.map(
              (detalle) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      detalle.metodoPago.icon,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detalle.metodoPago.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      currencyFormat.format(detalle.saldo),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: detalle.saldo >= 0
                            ? AppColors.green
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
