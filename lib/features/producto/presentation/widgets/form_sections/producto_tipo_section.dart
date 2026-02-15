import 'package:flutter/material.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../core/widgets/custom_switch_tile.dart';

/// Sección de tipo de producto (variantes/combo)
/// Maneja la selección entre producto simple, con variantes o combo
class ProductoTipoSection extends StatelessWidget {
  final bool tieneVariantes;
  final bool esCombo;
  final String? tipoPrecioCombo;
  final bool isEditing;
  final ValueChanged<bool> onTieneVariantesChanged;
  final ValueChanged<bool> onEsComboChanged;
  final ValueChanged<String?> onTipoPrecioComboChanged;
  final Future<bool?> Function()? onShowConversionDialog;

  const ProductoTipoSection({
    super.key,
    required this.tieneVariantes,
    required this.esCombo,
    this.tipoPrecioCombo,
    required this.isEditing,
    required this.onTieneVariantesChanged,
    required this.onEsComboChanged,
    required this.onTipoPrecioComboChanged,
    this.onShowConversionDialog,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: tieneVariantes
          ? Colors.purple
          : (esCombo ? Colors.blue : AppColors.blueborder),
      gradient: tieneVariantes
          ? LinearGradient(colors: [Colors.purple.shade50, Colors.purple.shade50])
          : (esCombo
              ? LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade50])
              : AppGradients.blueWhiteBlue()),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          // const SizedBox(height: 8),
          // Creando: solo mostrar combo | Editando: solo mostrar variantes
          if (!isEditing) _buildComboSwitch(context),
          if (isEditing && !esCombo) _buildVariantesSwitch(context),
          if (esCombo) ..._buildComboOptions(context),
          if (tieneVariantes && !isEditing) _buildVariantesInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: tieneVariantes
              ? Colors.purple
              : (esCombo ? Colors.blue : AppColors.blueGrey),
          size: 16,
        ),
        const SizedBox(width: 8),
        AppSubtitle('TIPO DE PRODUCTO'),
      ],
    );
  }

  Widget _buildComboSwitch(BuildContext context) {
    return CustomSwitchTile(
      activeColor: AppColors.green,
      activeTrackColor: AppColors.blue,
      trackOutlineColor: AppColors.blueGrey,
      title: 'Producto Combo',
      trackOutlineWidth: 1,
      subtitle: esCombo
          ? 'Este producto es un combo de otros productos'
          : 'Producto simple o con variantes',
      value: esCombo,
      onChanged: tieneVariantes
          ? null
          : (value) {
              if (value && tieneVariantes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se puede activar combo en un producto con variantes'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              onEsComboChanged(value);
            },
    );
  }

  Widget _buildVariantesSwitch(BuildContext context) {
    return CustomSwitchTile(
      activeColor: AppColors.green,
      activeTrackColor: AppColors.blue,
      trackOutlineColor: AppColors.blueGrey,
      title: 'Producto con Variantes',
      trackOutlineWidth: 1,
      subtitle: esCombo
          ? 'No se puede activar variantes en un producto combo'
          : (tieneVariantes
              ? 'El producto tiene variantes (capacidad, color, etc.)'
              : 'Producto simple sin variantes'),
      value: tieneVariantes,
      onChanged: esCombo
          ? null
          : (value) async {
              if (value && esCombo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se puede activar variantes en un producto que es combo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Si está editando y va a activar variantes, mostrar confirmación
              if (isEditing && value && !tieneVariantes && onShowConversionDialog != null) {
                final confirmar = await onShowConversionDialog!();
                if (confirmar != true) return;
              }

              onTieneVariantesChanged(value);
            },
    );
  }

  List<Widget> _buildComboOptions(BuildContext context) {
    return [
      const SizedBox(height: 16),
      CustomDropdown<String>(
        label: 'Tipo de Precio del Combo',
        hintText: 'Selecciona cómo se calculará el precio',
        borderColor: AppColors.blue1,
        value: tipoPrecioCombo,
        items: const [
          DropdownItem(value: 'FIJO', label: 'Precio Fijo'),
          DropdownItem(value: 'CALCULADO', label: 'Calculado (suma de productos)'),
          DropdownItem(value: 'CALCULADO_CON_DESCUENTO', label: 'Calculado con Descuento'),
        ],
        onChanged: onTipoPrecioComboChanged,
        validator: (value) {
          if (esCombo && (value == null || value.isEmpty)) {
            return 'Selecciona un tipo de precio para el combo';
          }
          return null;
        },
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
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
              child: AppSubtitle(
                'Un producto combo no puede tener variantes. Los combos se gestionan en la sección de "Combos" después de crear el producto.',
                fontSize: 10,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildVariantesInfo() {
    return Column(
      children: [
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: AppSubtitle(
                  'Después de crear el producto, podrás agregar las variantes (colores, tallas, etc.) con sus precios y stock individuales.',
                  fontSize: 10,
                  color: Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
