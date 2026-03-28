import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/plan_suscripcion_detail.dart';

class PlanCard extends StatelessWidget {
  final PlanSuscripcionDetail plan;
  final bool isCurrentPlan;
  final bool isLoading;
  final VoidCallback? onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    this.isCurrentPlan = false,
    this.isLoading = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlan ? AppColors.blue1 : AppColors.greyLight,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentPlan
                  ? AppColors.blue1.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Column(
              children: [
                if (isCurrentPlan)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Plan Actual',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  plan.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: plan.precioFormateado,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!plan.isFreePlan)
                        TextSpan(
                          text: ' / ${plan.periodoFormateado}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.greyLight),
          // Limits
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incluye:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLimitRow(Icons.inventory_2_outlined, 'Productos',
                    plan.formatLimite(plan.limiteProductos)),
                _buildLimitRow(Icons.miscellaneous_services_outlined,
                    'Servicios', plan.formatLimite(plan.limiteServicios)),
                _buildLimitRow(Icons.people_outline, 'Usuarios',
                    plan.formatLimite(plan.limiteUsuarios)),
                _buildLimitRow(Icons.store_outlined, 'Sedes',
                    plan.formatLimite(plan.limiteSedes)),
                _buildLimitRow(Icons.request_quote_outlined, 'Cotizaciones',
                    plan.formatLimite(plan.limiteCotizaciones)),
                _buildLimitRow(Icons.dashboard_customize_outlined,
                    'Plantillas', plan.formatLimite(plan.limitePlantillasAtributos)),
                _buildLimitRow(Icons.cloud_outlined, 'Almacenamiento',
                    plan.almacenamientoFormateado),
                _buildLimitRow(Icons.language, 'Pagina web',
                    plan.tieneWebPermanente ? 'Permanente' : '2 meses'),
                const SizedBox(height: 8),
                // Precios por periodo
                if (!plan.isFreePlan && (plan.precioSemestral != null || plan.precioAnual != null)) ...[
                  const Text(
                    'Ahorra pagando adelantado:',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (plan.precioSemestral != null)
                    _buildLimitRow(Icons.calendar_month, '6 meses',
                        'S/ ${plan.precioSemestral!.toStringAsFixed(2)}'),
                  if (plan.precioAnual != null)
                    _buildLimitRow(Icons.calendar_today, '12 meses',
                        'S/ ${plan.precioAnual!.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                ],
                // Features
                if (plan.tienePersonalizacion)
                  _buildFeatureRow('Personalizacion de marca'),
                if (plan.tieneReportesAvanzados)
                  _buildFeatureRow('Reportes avanzados'),
                if (plan.tieneApi) _buildFeatureRow('Acceso a API'),
                if (plan.tieneDominioPropio)
                  _buildFeatureRow('Dominio propio'),
              ],
            ),
          ),
          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: isCurrentPlan || isLoading ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrentPlan ? AppColors.grey : AppColors.blue1,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.greyLight,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      isCurrentPlan ? 'Plan Actual' : 'Seleccionar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
