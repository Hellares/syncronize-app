import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Política de vencimiento del producto.
///
/// 🔑 Acá NO se pone la fecha: se pone qué SIGNIFICA el vencimiento para este
/// producto. La fecha vive en el LOTE y se tipea al cargar la línea de compra,
/// porque cada entrega vence distinto — dos compras de la misma leche tienen
/// fechas diferentes, y una fecha en el producto haría que la segunda pisara
/// a la primera.
///
/// 🔴 El corte no es "perecedero sí/no": es la distinción de DIGESA/INDECOPI
/// entre CADUCIDAD ("no consumir después de") y consumo preferente ("mejor
/// antes de"). La primera se bloquea seco al vender; la segunda se autoriza.
class ProductoVencimientoSection extends StatelessWidget {
  final String tipoVencimiento;
  final TextEditingController diasVidaUtilController;
  final TextEditingController diasAlertaVencimientoController;
  final ValueChanged<String> onTipoVencimientoChanged;

  const ProductoVencimientoSection({
    super.key,
    required this.tipoVencimiento,
    required this.diasVidaUtilController,
    required this.diasAlertaVencimientoController,
    required this.onTipoVencimientoChanged,
  });

  static const _opciones = <String, String>{
    'NINGUNO': 'No vence',
    'CONSUMO_PREFERENTE': 'Consumo preferente',
    'CADUCIDAD': 'Caducidad',
  };

  @override
  Widget build(BuildContext context) {
    final controla = tipoVencimiento != 'NINGUNO';
    final caduca = tipoVencimiento == 'CADUCIDAD';

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy, size: 18, color: AppColors.blue1),
              const SizedBox(width: 8),
              Text(
                '¿Este producto vence?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: tipoVencimiento,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final e in _opciones.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 13)),
                ),
            ],
            onChanged: (v) => onTipoVencimientoChanged(v ?? 'NINGUNO'),
          ),
          if (controla) ...[
            const SizedBox(height: 8),
            // Que quien configura sepa qué va a pasar en el mostrador ANTES de
            // elegir, y no el día que una venta se frene.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: caduca ? Colors.red.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                caduca
                    ? '🔴 Vencido NO se puede vender, ni con autorización. Hay '
                        'que darlo de baja por merma o corregir la fecha del lote.'
                    : 'Vencido se puede vender, pero pide autorización de un '
                        'administrador.',
                style: TextStyle(
                  fontSize: 11,
                  color: caduca ? Colors.red.shade900 : Colors.amber.shade900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: diasVidaUtilController,
                    borderColor: AppColors.blue1,
                    label: 'Vida útil (días)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller: diasAlertaVencimientoController,
                    borderColor: AppColors.blue1,
                    label: 'Avisar (días antes)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'La vida útil solo SUGIERE la fecha al recibir una compra. La que '
              'vale es la impresa en el envase, y se tipea en la línea.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
