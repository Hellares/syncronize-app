import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/marca_maestra.dart';

/// Card para mostrar una marca maestra disponible (catálogo global).
/// Mismo lenguaje visual que las cards de productos: GradientContainer +
/// chips compactos. Si ya está activada se atenúa visualmente.
class MarcaMaestraCard extends StatelessWidget {
  final MarcaMaestra maestra;
  final VoidCallback onActivar;
  final bool isActivada;

  const MarcaMaestraCard({
    super.key,
    required this.maestra,
    required this.onActivar,
    this.isActivada = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isActivada ? Colors.grey.shade500 : AppColors.blue1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isActivada ? 0.65 : 1,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            maestra.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActivada)
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 16),
                      ],
                    ),
                    if (maestra.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        maestra.descripcion!,
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
                        if (maestra.esPopular)
                          _buildChip('Popular', Colors.amber.shade700,
                              Icons.local_fire_department_outlined),
                        if (maestra.paisOrigen != null)
                          _buildChip(maestra.paisOrigen!, AppColors.blue1,
                              Icons.public_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isActivada ? _buildActivadaChip() : _buildActivarButton(),
            ],
          ),
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

  Widget _buildActivadaChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 11, color: Colors.green.shade700),
          const SizedBox(width: 3),
          Text(
            'Activada',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivarButton() {
    return InkWell(
      onTap: onActivar,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blue1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Activar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
