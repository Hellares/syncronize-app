import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/custom_switch_tile.dart';

/// Sección de opciones del producto
/// Contiene: visible en marketplace, producto destacado, insumo
class ProductoOptionsSection extends StatelessWidget {
  final bool visibleMarketplace;
  final bool destacado;
  final bool esInsumo;
  final ValueChanged<bool> onVisibleMarketplaceChanged;
  final ValueChanged<bool> onDestacadoChanged;
  final ValueChanged<bool> onEsInsumoChanged;

  const ProductoOptionsSection({
    super.key,
    required this.visibleMarketplace,
    required this.destacado,
    required this.esInsumo,
    required this.onVisibleMarketplaceChanged,
    required this.onDestacadoChanged,
    required this.onEsInsumoChanged,
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
          AppSubtitle('OPCIONES'),
          CustomSwitchTile(
            activeColor: Colors.green,
            activeTrackColor: Colors.green.shade200,
            title: 'Visible en Marketplace',
            subtitle: 'El producto aparecerá en el marketplace público',
            value: visibleMarketplace,
            // Si es insumo, no puede ir a marketplace.
            onChanged: esInsumo ? (_) {} : onVisibleMarketplaceChanged,
          ),
          CustomSwitchTile(
            title: 'Producto Destacado',
            subtitle: 'Se mostrará con prioridad en listados',
            value: destacado,
            onChanged: esInsumo ? (_) {} : onDestacadoChanged,
          ),
          CustomSwitchTile(
            activeColor: Colors.indigo,
            activeTrackColor: Colors.indigo.shade200,
            title: 'Es Insumo / Materia Prima',
            subtitle:
                'No se vende directo. Solo se usa como componente de productos compuestos (BOM).',
            value: esInsumo,
            onChanged: onEsInsumoChanged,
          ),
        ],
      ),
    );
  }
}
