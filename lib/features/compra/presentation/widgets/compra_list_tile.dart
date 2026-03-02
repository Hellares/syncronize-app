import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
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
        return Colors.red;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        shadowStyle: ShadowStyle.glow,
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Icono estado
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _estadoColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _estadoIcon(),
            color: _estadoColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        // Info principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Codigo
              Text(
                compra.codigo,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily:
                      AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              // Proveedor + fecha
              Row(
                children: [
                  Icon(Icons.business, size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      compra.nombreProveedor,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontFamily:
                            AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '·',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 8),
                    ),
                  ),
                  Icon(Icons.calendar_today,
                      size: 10, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    DateFormatter.formatDate(compra.fechaRecepcion),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontFamily:
                          AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final color = _estadoColor();

    return Row(
      children: [
        // Monto total
        Text(
          '${compra.moneda} ${compra.total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.blue1,
          ),
        ),
        const Spacer(),
        // OC badge
        if (compra.ordenCompraCodigo != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.blue1.withValues(alpha: 0.2),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long,
                    size: 10, color: AppColors.blue1),
                const SizedBox(width: 4),
                AppSubtitle(
                  'OC: ${compra.ordenCompraCodigo}',
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Estado badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_estadoIcon(), size: 10, color: color),
              const SizedBox(width: 4),
              AppSubtitle(
                compra.estadoTexto.toUpperCase(),
                fontSize: 9,
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
