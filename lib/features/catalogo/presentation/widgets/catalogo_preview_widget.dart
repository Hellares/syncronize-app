import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/catalogo_preview.dart';

/// Widget para mostrar el preview de catálogos que se activarán
class CatalogoPreviewWidget extends StatelessWidget {
  final CatalogoPreview preview;

  const CatalogoPreviewWidget({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blue1,
      borderWidth: 0.6,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.blue1, size: 18),
              const SizedBox(width: 8),
              AppSubtitle('CATÁLOGOS QUE SE ACTIVARÁN', fontSize: 11),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Se activarán automáticamente ${preview.total} catálogos para tu empresa',
            style: const TextStyle(fontSize: 10, color: AppColors.blueGrey),
          ),
          const Divider(height: 20),

          // Categorías
          if (preview.categorias.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.category,
              title: 'Categorías (${preview.categorias.length})',
              color: AppColors.blue1,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: preview.categorias.map((categoria) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (categoria.icono != null)
                        Text(categoria.icono!, style: const TextStyle(fontSize: 13))
                      else
                        const Icon(Icons.category, size: 13, color: AppColors.blue1),
                      const SizedBox(width: 5),
                      Text(
                        categoria.nombre,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.blue2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Marcas
          if (preview.marcas.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.business,
              title: 'Marcas (${preview.marcas.length})',
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: preview.marcas.map((marca) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 13, color: AppColors.green),
                      const SizedBox(width: 5),
                      Text(
                        marca.nombre,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.blue2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),

          // Info note
          GradientContainer(
            gradient: AppGradients.orangeWhiteBlue(),
            borderColor: Colors.amber.shade300,
            borderWidth: 0.5,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            padding: const EdgeInsets.all(10),
            enableShadow: false,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Podrás agregar o quitar catálogos más tarde desde la configuración',
                    style: TextStyle(fontSize: 9, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
