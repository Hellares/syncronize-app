import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/empresa_statistics.dart';

class UsageLimitCard extends StatelessWidget {
  final PlanLimitsInfo planLimits;

  const UsageLimitCard({
    super.key,
    required this.planLimits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUsageRow(
            Icons.inventory_2_outlined,
            'Productos',
            planLimits.productos,
          ),
          const SizedBox(height: 10),
          _buildUsageRow(
            Icons.miscellaneous_services_outlined,
            'Servicios',
            planLimits.servicios,
          ),
          const SizedBox(height: 10),
          _buildUsageRow(
            Icons.people_outline,
            'Usuarios',
            planLimits.usuarios,
          ),
          const SizedBox(height: 10),
          _buildUsageRow(
            Icons.store_outlined,
            'Sedes',
            planLimits.sedes,
          ),
          const SizedBox(height: 10),
          _buildUsageRow(
            Icons.request_quote_outlined,
            'Cotizaciones',
            planLimits.cotizaciones,
          ),
          const SizedBox(height: 10),
          _buildUsageRow(
            Icons.dashboard_customize_outlined,
            'Plantillas',
            planLimits.plantillasAtributos,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(
    IconData icon,
    String label,
    PlanLimitInfo info,
  ) {
    final isUnlimited = info.limite == null;
    final percent = info.usagePercent;
    final progressValue = isUnlimited ? 0.0 : (percent ?? 0.0).clamp(0.0, 1.0);

    Color barColor;
    if (info.isAtLimit) {
      barColor = AppColors.red;
    } else if (info.isWarning) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.blue1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.blue2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              isUnlimited
                  ? '${info.actual} / Ilimitado'
                  : '${info.actual} / ${info.limite}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: info.isAtLimit
                    ? AppColors.red
                    : info.isWarning
                        ? AppColors.amberText
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (!isUnlimited) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.greyLight,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ],
    );
  }
}
