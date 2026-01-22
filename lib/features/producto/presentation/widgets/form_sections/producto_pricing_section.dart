import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../../core/widgets/currency/currency_formatter.dart';

/// Sección de precios del producto
/// Contiene: precio de venta y precio de costo
class ProductoPricingSection extends StatelessWidget {
  final TextEditingController precioController;
  final TextEditingController precioCostoController;
  final bool esCombo;
  final String? tipoPrecioCombo;

  const ProductoPricingSection({
    super.key,
    required this.precioController,
    required this.precioCostoController,
    required this.esCombo,
    this.tipoPrecioCombo,
  });

  bool get _esPrecioCalculado =>
      esCombo && (tipoPrecioCombo == 'CALCULADO' || tipoPrecioCombo == 'CALCULADO_CON_DESCUENTO');

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blue1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('PRECIOS'),
          const SizedBox(height: 12),
          // Mensaje informativo para combos con precio calculado
          if (_esPrecioCalculado) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El precio de este combo se calculará automáticamente cuando agregues los productos componentes.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: CurrencyTextField(
                  controller: precioController,
                  label: _esPrecioCalculado
                      ? 'Precio de Venta (calculado)'
                      : 'Precio de Venta *',
                  hintText: '0.00',
                  borderColor: AppColors.blue1,
                  enabled: !esCombo || tipoPrecioCombo == 'FIJO' || tipoPrecioCombo == null,
                  enableRealTimeValidation: true,
                  validator: (value) {
                    // Si es combo con precio calculado, el precio NO es requerido
                    if (_esPrecioCalculado) {
                      return null;
                    }

                    // Para otros casos, el precio es requerido
                    if (value == null || value.trim().isEmpty) {
                      return 'El precio es requerido';
                    }

                    final precio = CurrencyUtilsImproved.parseToDouble(value);
                    if (precio <= 0) {
                      return 'El precio debe ser mayor a 0';
                    }

                    // Validar precio >= costo
                    final costo = precioCostoController.currencyValue;
                    if (costo > 0 && precio < costo) {
                      return 'El precio debe ser ≥ al costo';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CurrencyTextField(
                  allowZero: false,
                  requiredField: true,
                  controller: precioCostoController,
                  label: 'Precio de Costo',
                  hintText: '0.00',
                  borderColor: AppColors.blue1,
                  enableRealTimeValidation: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
