import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de dimensiones del producto
/// Contiene: largo, ancho y alto
class ProductoDimensionesSection extends StatelessWidget {
  final TextEditingController largoController;
  final TextEditingController anchoController;
  final TextEditingController altoController;

  const ProductoDimensionesSection({
    super.key,
    required this.largoController,
    required this.anchoController,
    required this.altoController,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle('DIMENSIONES (cm)'),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: largoController,
                  borderColor: AppColors.blue1,
                  label: 'Largo',
                  hintText: '0.0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  controller: anchoController,
                  borderColor: AppColors.blue1,
                  label: 'Ancho',
                  hintText: '0.0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  controller: altoController,
                  borderColor: AppColors.blue1,
                  label: 'Alto',
                  hintText: '0.0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
