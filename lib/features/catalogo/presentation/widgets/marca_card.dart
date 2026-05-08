import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/empresa_marca.dart';

/// Card para mostrar una marca activa de la empresa, con el mismo
/// lenguaje visual que las cards de categorías y productos:
/// GradientContainer + shadow neumorphic + chips compactos.
class MarcaCard extends StatelessWidget {
  final EmpresaMarca marca;
  final VoidCallback onDesactivar;

  const MarcaCard({
    super.key,
    required this.marca,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonalizada = marca.esPersonalizada;
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
            _buildLeadingIcon(accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    marca.nombreDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (marca.descripcionDisplay != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      marca.descripcionDisplay!,
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
                      if (marca.marcaMaestra?.esPopular ?? false)
                        _buildChip('Popular', Colors.amber.shade700,
                            Icons.local_fire_department_outlined),
                      if (marca.marcaMaestra?.paisOrigen != null)
                        _buildChip(marca.marcaMaestra!.paisOrigen!,
                            AppColors.blue1, Icons.public_outlined),
                      if (marca.orden != null)
                        _buildChip('#${marca.orden}', AppColors.blue1, null),
                      if (!marca.isVisible)
                        _buildChip('Oculta', Colors.grey.shade600,
                            Icons.visibility_off_outlined),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: Colors.grey.shade600),
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
      child: Icon(Icons.label_outlined, color: accentColor, size: 18),
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
}
