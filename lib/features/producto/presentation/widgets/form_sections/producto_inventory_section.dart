import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de características físicas del producto
/// Contiene: peso y dimensiones
/// NOTA: Stock inicial se agrega después de crear el producto mediante ProductoStock
class ProductoInventorySection extends StatelessWidget {
  final TextEditingController pesoController;

  const ProductoInventorySection({
    super.key,
    required this.pesoController,
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
          AppSubtitle('CARACTERÍSTICAS FÍSICAS'),
          const SizedBox(height: 12),
          CustomText(
            controller: pesoController,
            borderColor: AppColors.blue1,
            label: 'Peso (kg)',
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          Text(
            'El stock se agregará después de crear el producto',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
