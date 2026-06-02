import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../domain/entities/proveedor.dart';

class ProveedorListTile extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback? onTap;

  const ProveedorListTile({
    super.key,
    required this.proveedor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = proveedor.isActive;
    final avatarBg =
        activo ? AppColors.blue.withValues(alpha: 0.12) : Colors.grey.shade200;
    final avatarFg = activo ? AppColors.blue1 : Colors.grey.shade600;

    return GradientContainer(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(10),
      borderColor: AppColors.blue.withValues(alpha: 0.15),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Avatar con iniciales
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarBg,
                  child: Text(
                    proveedor.iniciales,
                    style: TextStyle(
                      color: avatarFg,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Datos principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   proveedor.nombre,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 13,
                      //     color: AppColors.blue3,
                      //   ),
                      // ),
                      AppSubtitle(
                        proveedor.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.blue3,
                        font: AppFont.amazonEmberMedium,                      ),
                      const SizedBox(height: 2),
                      // Text(
                      //   '${proveedor.codigo} • ${proveedor.numeroDocumento}',
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     fontSize: 11,
                      //     color: AppColors.textSecondary,
                      //   ),
                      // ),
                      AppSubtitle(
                        '${proveedor.codigo} • ${proveedor.numeroDocumento}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        font: AppFont.amazonEmberDisplay,
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                      if (proveedor.terminosPago != null) ...[
                        const SizedBox(height: 5),
                        _chip(
                          icon: Icons.payments_outlined,
                          label: proveedor.terminosPagoTexto,
                          color: AppColors.blue,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Calificación + estado
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (proveedor.calificacion != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            proveedor.calificacion.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    if (!activo) ...[
                      if (proveedor.calificacion != null)
                        const SizedBox(height: 4),
                      _chip(
                        label: 'Inactivo',
                        color: AppColors.red,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
