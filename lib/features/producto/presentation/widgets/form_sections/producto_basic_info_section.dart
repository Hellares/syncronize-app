import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de información básica del producto
/// Contiene: nombre, descripción, SKU y código de barras
class ProductoBasicInfoSection extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController descripcionController;
  final TextEditingController skuController;
  final TextEditingController codigoBarrasController;

  const ProductoBasicInfoSection({
    super.key,
    required this.nombreController,
    required this.descripcionController,
    required this.skuController,
    required this.codigoBarrasController,
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
          AppSubtitle('INFORMACION BÁSICA'),
          const SizedBox(height: 16),
          CustomText(
            controller: nombreController,
            borderColor: AppColors.blue1,
            label: 'Nombre del Producto *',
            hintText: 'Ej: Laptop HP Pavilion',
            enableVoiceInput: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          CustomText(
            controller: descripcionController,
            borderColor: AppColors.blue1,
            label: 'Descripción',
            hintText: 'Descripción del producto',
            enableVoiceInput: true,
            maxLines: null,
            minLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: skuController,
                  prefixIcon: const Icon(Icons.numbers,),
                  borderColor: AppColors.blue1,
                  label: 'SKU',
                  hintText: 'Código SKU',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomText(
                  controller: codigoBarrasController,
                  prefixIcon: const Icon(Icons.qr_code_scanner_outlined,),
                  borderColor: AppColors.blue1,
                  label: 'Código de Barras',
                  hintText: 'EAN/UPC',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
