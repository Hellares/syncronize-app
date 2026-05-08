import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/empresa_categoria.dart';

/// Card para mostrar una categoría activa de la empresa, con el mismo
/// lenguaje visual que las cards de productos: GradientContainer +
/// shadow neumorphic + chips compactos + iconos con fondo coloreado.
class CategoriaCard extends StatelessWidget {
  final EmpresaCategoria categoria;
  final VoidCallback onDesactivar;

  const CategoriaCard({
    super.key,
    required this.categoria,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonalizada = categoria.categoriaMaestraId == null;
    final accentColor = isPersonalizada ? Colors.purple : AppColors.blue1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        shadowStyle: ShadowStyle.neumorphic,
        borderColor: AppColors.blueborder,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono leading con fondo coloreado
            _buildLeadingIcon(accentColor),
            const SizedBox(width: 10),
            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categoria.nombreDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (categoria.descripcionDisplay != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      categoria.descripcionDisplay!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (isPersonalizada)
                        _buildChip(
                            'Personalizada', Colors.purple, Icons.star_outline),
                      if (categoria.categoriaMaestra?.esPopular ?? false)
                        _buildChip('Popular', Colors.amber.shade700,
                            Icons.local_fire_department_outlined),
                      if (categoria.orden != null)
                        _buildChip(
                            '#${categoria.orden}', AppColors.blue1, null),
                      if (!categoria.isVisible)
                        _buildChip(
                            'Oculta', Colors.grey.shade600, Icons.visibility_off_outlined),
                    ],
                  ),
                ],
              ),
            ),
            // Menú trailing
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              onSelected: (value) {
                if (value == 'desactivar') onDesactivar();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'desactivar',
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Desactivar',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(Color accentColor) {
    final iconData = categoria.categoriaMaestra?.icono != null
        ? _getIconData(categoria.categoriaMaestra!.icono!)
        : Icons.category_outlined;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 0.6,
        ),
      ),
      child: Icon(iconData, color: accentColor, size: 18),
    );
  }

  Widget _buildChip(String label, Color color, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'devices': Icons.devices,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'tv': Icons.tv,
      'camera': Icons.camera,
      'headphones': Icons.headphones,
      'watch': Icons.watch,
      'print': Icons.print,
      'router': Icons.router,
      'keyboard': Icons.keyboard,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'store': Icons.store,
      'shopping_cart': Icons.shopping_cart,
      'category': Icons.category,
    };
    return iconMap[iconName] ?? Icons.category_outlined;
  }
}
