import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../domain/entities/venta_detalle_input.dart';

class ResumenVentaWidget extends StatelessWidget {
  final List<VentaDetalleInput> items;
  final String moneda;
  final String nombreImpuesto;
  final double porcentajeImpuesto;

  const ResumenVentaWidget({
    super.key,
    required this.items,
    this.moneda = 'PEN',
    this.nombreImpuesto = 'IGV',
    this.porcentajeImpuesto = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold(0.0, (sum, i) => sum + i.subtotal);
    final descuento = items.fold(0.0, (sum, i) => sum + i.descuento);
    final impuestos = subtotal * (porcentajeImpuesto / 100);
    final total = subtotal + impuestos;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow('Items', '${items.length}'),
            const SizedBox(height: 4),
            _buildRow('Subtotal', '$moneda ${subtotal.toStringAsFixed(2)}'),
            if (descuento > 0) ...[
              const SizedBox(height: 4),
              _buildRow(
                'Descuento',
                '-$moneda ${descuento.toStringAsFixed(2)}',
                color: Colors.red,
              ),
            ],
            const SizedBox(height: 4),
            _buildRow(
              '$nombreImpuesto (${porcentajeImpuesto.toStringAsFixed(0)}%)',
              '$moneda ${impuestos.toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                height: 1,
                color: AppColors.blueborder.withValues(alpha: 0.5),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppSubtitle('TOTAL', fontSize: 14),
                AppSubtitle(
                  '$moneda ${total.toStringAsFixed(2)}',
                  fontSize: 16,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
