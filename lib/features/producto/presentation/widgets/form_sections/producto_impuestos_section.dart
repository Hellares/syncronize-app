import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de impuestos, afectación IGV e ICBPER del producto
class ProductoImpuestosSection extends StatelessWidget {
  final TextEditingController impuestoPorcentajeController;
  final TextEditingController descuentoMaximoController;
  final double? igvGlobal;
  final String tipoAfectacionIgv;
  final bool aplicaIcbper;
  final ValueChanged<String> onTipoAfectacionChanged;
  final ValueChanged<bool> onAplicaIcbperChanged;

  const ProductoImpuestosSection({
    super.key,
    required this.impuestoPorcentajeController,
    required this.descuentoMaximoController,
    this.igvGlobal,
    this.tipoAfectacionIgv = 'GRAVADO',
    this.aplicaIcbper = false,
    required this.onTipoAfectacionChanged,
    required this.onAplicaIcbperChanged,
  });

  @override
  Widget build(BuildContext context) {
    final esGravado = tipoAfectacionIgv == 'GRAVADO';

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('IMPUESTOS Y DESCUENTOS'),
          const SizedBox(height: 8),

          // Tipo de Afectación IGV (SUNAT Cat. 07)
          Text('Tipo de Afectación IGV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildAfectacionChip('GRAVADO', 'Gravado', Icons.check_circle, Colors.green),
              const SizedBox(width: 6),
              _buildAfectacionChip('EXONERADO', 'Exonerado', Icons.remove_circle, Colors.orange),
              const SizedBox(width: 6),
              _buildAfectacionChip('INAFECTO', 'Inafecto', Icons.cancel, Colors.grey),
            ],
          ),

          if (!esGravado)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  tipoAfectacionIgv == 'EXONERADO'
                      ? 'Producto exonerado de IGV. No se cobrará impuesto.'
                      : 'Producto inafecto al IGV. No está sujeto al impuesto.',
                  style: TextStyle(fontSize: 10, color: Colors.amber.shade800),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // IGV y Descuento Max
          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: impuestoPorcentajeController,
                  borderColor: AppColors.blue1,
                  label: 'Impuesto (%)',
                  hintText: esGravado
                      ? (igvGlobal != null ? 'Global: ${igvGlobal!.toStringAsFixed(0)}%' : '0.00')
                      : '0 (${tipoAfectacionIgv.toLowerCase()})',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: esGravado,
                  validator: _validatePercentage,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomText(
                  controller: descuentoMaximoController,
                  borderColor: AppColors.blue1,
                  label: 'Descuento Máx. (%)',
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validatePercentage,
                ),
              ),
            ],
          ),

          if (esGravado && igvGlobal != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Vacío = usa IGV global (${igvGlobal!.toStringAsFixed(0)}%). Solo llena si es diferente.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),

          const SizedBox(height: 10),

          // ICBPER
          GestureDetector(
            onTap: () => onAplicaIcbperChanged(!aplicaIcbper),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: aplicaIcbper,
                    onChanged: (v) => onAplicaIcbperChanged(v ?? false),
                    activeColor: AppColors.blue1,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aplica ICBPER (Bolsa plástica)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      Text('S/ 0.50 por unidad - Ley N° 30884', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfectacionChip(String value, String label, IconData icon, Color color) {
    final selected = tipoAfectacionIgv == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTipoAfectacionChanged(value);
          if (value != 'GRAVADO') {
            impuestoPorcentajeController.clear();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: selected ? color : Colors.grey),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: selected ? color : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePercentage(String? value) {
    if (value != null && value.isNotEmpty) {
      final val = double.tryParse(value);
      if (val == null || val < 0 || val > 100) {
        return 'Ingrese un valor entre 0 y 100';
      }
    }
    return null;
  }
}
