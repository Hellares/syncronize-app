import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/gradient_container.dart';
import 'custom_dropdown.dart';

/// Card reutilizable para seleccionar tipo de comprobante y condición de pago.
///
/// Muestra: Ticket/Boleta/Factura + Contado/Crédito/Mixto
class ComprobanteCondicionCard extends StatelessWidget {
  final String tipoComprobante;
  final ValueChanged<String> onComprobanteChanged;
  final String condicionPago; // CONTADO, CREDITO, MIXTO
  final ValueChanged<String> onCondicionChanged;
  final bool showMixto;

  const ComprobanteCondicionCard({
    super.key,
    required this.tipoComprobante,
    required this.onComprobanteChanged,
    required this.condicionPago,
    required this.onCondicionChanged,
    this.showMixto = true,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdown<String>(
              label: 'Tipo de Comprobante',
              value: tipoComprobante,
              borderColor: AppColors.blue1,
              items: const [
                DropdownItem(value: 'TICKET', label: 'Ticket (Nota de venta)'),
                DropdownItem(value: 'BOLETA', label: 'Boleta'),
                DropdownItem(value: 'FACTURA', label: 'Factura'),
              ],
              onChanged: (v) {
                if (v != null) onComprobanteChanged(v);
              },
            ),
            if (tipoComprobante == 'FACTURA') ...[
              const SizedBox(height: 6),
              Text('Se requiere RUC del cliente',
                  style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            AppSubtitle('Condición de Pago', color: AppColors.blue1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _chip('CONTADO', 'Contado'),
                _chip('CREDITO', 'Credito'),
                if (showMixto) _chip('MIXTO', 'Mixto'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = condicionPago == value;
    return GestureDetector(
      onTap: () => onCondicionChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!, width: 0.6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}
