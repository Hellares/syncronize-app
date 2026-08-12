import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/custom_switch_tile.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';

/// Sección de opciones del producto
/// Contiene: visible en marketplace, producto destacado, insumo
class ProductoOptionsSection extends StatelessWidget {
  final bool visibleMarketplace;
  final bool destacado;
  final bool esInsumo;

  /// El producto pide un identificador por unidad AL VENDER (IMEI, serie,
  /// placa). No se serializa el inventario: el stock sigue genérico y el dato
  /// se tipea en el carrito.
  final bool requiereIdentificador;

  /// Controller del rótulo ("IMEI"). Va como controller y no como valor +
  /// onChanged porque `CustomText` no acepta `initialValue`: reconstruirlo en
  /// cada tecla mandaría el cursor al inicio.
  final TextEditingController etiquetaIdentificadorCtrl;
  final ValueChanged<bool> onVisibleMarketplaceChanged;
  final ValueChanged<bool> onDestacadoChanged;
  final ValueChanged<bool> onEsInsumoChanged;
  final ValueChanged<bool> onRequiereIdentificadorChanged;

  const ProductoOptionsSection({
    super.key,
    required this.visibleMarketplace,
    required this.destacado,
    required this.esInsumo,
    required this.onVisibleMarketplaceChanged,
    required this.onDestacadoChanged,
    required this.onEsInsumoChanged,
    this.requiereIdentificador = false,
    required this.etiquetaIdentificadorCtrl,
    required this.onRequiereIdentificadorChanged,
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
            title: 'Visible en Marketplace',
            subtitle: 'El producto aparecerá en el marketplace público',
            value: visibleMarketplace,
            // Si es insumo, no puede ir a marketplace.
            onChanged: esInsumo ? null : onVisibleMarketplaceChanged,
          ),
          CustomSwitchTile(
            title: 'Producto Destacado',
            subtitle: 'Se mostrará con prioridad en listados',
            value: destacado,
            onChanged: esInsumo ? null : onDestacadoChanged,
          ),
          CustomSwitchTile(
            title: 'Es Insumo / Materia Prima',
            subtitle:
                'No se vende directo. Solo se usa como componente de productos compuestos (BOM).',
            value: esInsumo,
            onChanged: onEsInsumoChanged,
          ),
          CustomSwitchTile(
            title: 'Pide identificador al vender',
            subtitle:
                'Cada unidad lleva un dato propio (IMEI, N° de serie, placa) '
                'que se tipea en el carrito y sale en la boleta. El stock '
                'sigue siendo genérico.',
            value: requiereIdentificador,
            onChanged: esInsumo ? null : onRequiereIdentificadorChanged,
          ),
          // El rótulo solo tiene sentido con el switch activo; mostrarlo
          // siempre confundiría con un dato que hay que llenar igual.
          if (requiereIdentificador) ...[
            const SizedBox(height: 6),
            CustomText(
              label: '¿Cómo se llama ese dato?',
              hintText: 'IMEI',
              controller: etiquetaIdentificadorCtrl,
              borderColor: AppColors.blue1Alpha40,
            ),
            const SizedBox(height: 4),
            Text(
              'Es lo que va a decir la boleta: "— IMEI: 351234567890123". '
              'Vacío usa "N° de serie".',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
