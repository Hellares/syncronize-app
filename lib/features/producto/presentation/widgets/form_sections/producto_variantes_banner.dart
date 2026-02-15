import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import '../../../../../core/theme/gradient_container.dart';

/// Banner informativo para productos con variantes
/// Muestra información sobre gestión de variantes
class ProductoVariantesBanner extends StatelessWidget {
  final bool isEditing;
  final String? productoId;
  final String nombreProducto;
  final String? categoriaId;
  final bool productoIsActive;

  const ProductoVariantesBanner({
    super.key,
    required this.isEditing,
    this.productoId,
    required this.nombreProducto,
    this.categoriaId,
    required this.productoIsActive,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.amber,
      gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.amber.shade50]),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle('Producto con Variantes', color: AppColors.amberText,),
                    const SizedBox(height: 4),
                    AppSubtitle(
                      isEditing
                        ? 'Los precios y stock se gestionan en cada variante individual.'
                        : 'Una vez creado el producto, podrás agregar variantes con sus precios y stock individuales.',
                    )
                  ],
                ),
              ),
            ],
          ),
          if (isEditing && productoId != null) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Gestionar Variantes',
              icon: Icon(Icons.settings),
              backgroundColor: AppColors.warning,
              onPressed: (){
                final nombre = nombreProducto.isNotEmpty ? nombreProducto : 'Producto';
                final categoriaIdParam = categoriaId != null
                  ? '&categoriaId=${Uri.encodeComponent(categoriaId!)}'
                  : '';
                context.push('/empresa/productos/$productoId/variantes?nombre=${Uri.encodeComponent(nombre)}&isActive=$productoIsActive$categoriaIdParam');
              },
            )
          ],
        ],
      ),
    );
  }
}
