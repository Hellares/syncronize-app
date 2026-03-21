import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';

class AccesosRapidosSection extends StatelessWidget {
  final int colaPosCount;

  const AccesosRapidosSection({
    super.key,
    this.colaPosCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _AccesoRapidoButton(
              icon: Icons.point_of_sale,
              label: 'Nueva Venta',
              color: AppColors.green,
              onTap: () => context.push('/empresa/ventas/nueva'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AccesoRapidoButton(
              icon: Icons.receipt_long,
              label: 'Cola POS',
              color: AppColors.orange,
              badgeCount: colaPosCount,
              onTap: () => context.push('/empresa/cola-pos'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AccesoRapidoButton(
              icon: Icons.account_balance_wallet,
              label: 'Caja',
              color: AppColors.blue1,
              onTap: () => context.push('/empresa/caja'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AccesoRapidoButton(
              icon: Icons.monitor_heart,
              label: 'Monitor',
              color: Colors.deepOrange,
              onTap: () => context.push('/empresa/caja/monitor'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccesoRapidoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _AccesoRapidoButton({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
