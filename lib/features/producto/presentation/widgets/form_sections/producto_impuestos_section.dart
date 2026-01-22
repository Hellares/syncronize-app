import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de impuestos y descuentos del producto
/// Contiene: porcentaje de impuesto y descuento máximo
class ProductoImpuestosSection extends StatelessWidget {
  final TextEditingController impuestoPorcentajeController;
  final TextEditingController descuentoMaximoController;

  const ProductoImpuestosSection({
    super.key,
    required this.impuestoPorcentajeController,
    required this.descuentoMaximoController,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('IMPUESTOS Y DESCUENTOS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: impuestoPorcentajeController,
                  borderColor: AppColors.blue1,
                  label: 'Impuesto (%)',
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        ],
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
