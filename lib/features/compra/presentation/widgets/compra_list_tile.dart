import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/compra.dart';

class CompraListTile extends StatelessWidget {
  final Compra compra;
  final VoidCallback? onTap;

  const CompraListTile({
    super.key,
    required this.compra,
    this.onTap,
  });

  Color _estadoColor() {
    switch (compra.estado) {
      case EstadoCompra.BORRADOR:
        return Colors.blueGrey;
      case EstadoCompra.CONFIRMADA:
        return AppColors.green;
      case EstadoCompra.ANULADA:
        return AppColors.red;
    }
  }

  IconData _estadoIcon() {
    switch (compra.estado) {
      case EstadoCompra.BORRADOR:
        return Icons.edit_note;
      case EstadoCompra.CONFIRMADA:
        return Icons.check_circle_outline;
      case EstadoCompra.ANULADA:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor();

    return GradientContainer(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(10),
      borderColor: AppColors.blue.withValues(alpha: 0.15),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Avatar con ícono de estado
                CircleAvatar(
                  radius: 20,
                  backgroundColor: estadoColor.withValues(alpha: 0.12),
                  child: Icon(_estadoIcon(), color: estadoColor, size: 18),
                ),
                const SizedBox(width: 10),
                // Datos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        compra.codigo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.blue3,
                        font: AppFont.amazonEmberMedium,
                      ),
                      const SizedBox(height: 2),
                      AppSubtitle(
                        compra.nombreProveedor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        font: AppFont.amazonEmberDisplay,
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Fecha + hora: solo ícono + texto (sin chip).
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 11, color: AppColors.blue),
                              const SizedBox(width: 3),
                              Text(
                                DateFormatter.formatDateTime(
                                    compra.fechaRecepcion),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.blue),
                              ),
                            ],
                          ),
                          if (compra.ordenCompraCodigo != null)
                            _chip(
                              icon: Icons.receipt_long,
                              label: 'OC: ${compra.ordenCompraCodigo}',
                              color: AppColors.blue1,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Monto + estado
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${compra.moneda} ${compra.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _chip(
                      icon: _estadoIcon(),
                      label: compra.estadoTexto.toUpperCase(),
                      color: estadoColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }
}
