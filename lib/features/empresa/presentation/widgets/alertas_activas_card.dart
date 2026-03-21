import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_state.dart';

class AlertasActivasCard extends StatelessWidget {
  const AlertasActivasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResumenFinancieroCubit, ResumenFinancieroState>(
      builder: (context, state) {
        if (state is ResumenFinancieroLoading ||
            state is ResumenFinancieroInitial) {
          return GradientContainer(
            borderColor: AppColors.blueborder,
            padding: const EdgeInsets.all(14),
            child: const SizedBox(
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ),
          );
        }
        if (state is ResumenFinancieroError) {
          return GradientContainer(
            borderColor: AppColors.blueborder,
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  'No se pudo cargar alertas',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
          );
        }
        if (state is ResumenFinancieroLoaded) {
          return _buildContent(state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(ResumenFinancieroLoaded state) {
    final data = state.resumen.data;
    final cobrar = data['cuentasPorCobrar'] as Map<String, dynamic>?;
    final pagar = data['cuentasPorPagar'] as Map<String, dynamic>?;
    final caja = data['caja'] as Map<String, dynamic>?;

    final vencidoCobrar = _val(cobrar, 'totalVencido');
    final vencidoPagar = _val(pagar, 'totalVencido');
    final cajasAbiertas = caja?['cajasAbiertas'] as int? ?? 0;

    final hasAlerts = vencidoCobrar > 0 || vencidoPagar > 0;

    return GradientContainer(
      borderColor: hasAlerts
          ? AppColors.orange.withValues(alpha: 0.6)
          : AppColors.blueborder,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 16,
                color: hasAlerts ? AppColors.orange : AppColors.blue1,
              ),
              const SizedBox(width: 6),
              AppSubtitle(
                'Alertas',
                fontSize: 12,
                color: hasAlerts ? AppColors.orange : AppColors.blue1,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAlerts && cajasAbiertas == 0)
            _buildAllClear()
          else ...[
            if (vencidoCobrar > 0)
              _buildAlertRow(
                icon: Icons.arrow_downward,
                color: AppColors.red,
                label: 'Cuentas por cobrar vencidas',
                detail: 'S/ ${vencidoCobrar.toStringAsFixed(2)}',
              ),
            if (vencidoPagar > 0) ...[
              if (vencidoCobrar > 0) const SizedBox(height: 6),
              _buildAlertRow(
                icon: Icons.arrow_upward,
                color: AppColors.red,
                label: 'Cuentas por pagar vencidas',
                detail: 'S/ ${vencidoPagar.toStringAsFixed(2)}',
              ),
            ],
            if (cajasAbiertas > 0) ...[
              if (vencidoCobrar > 0 || vencidoPagar > 0)
                const SizedBox(height: 6),
              _buildAlertRow(
                icon: Icons.point_of_sale,
                color: AppColors.blue1,
                label: 'Cajas abiertas',
                detail: '$cajasAbiertas',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAllClear() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            'Todo en orden',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow({
    required IconData icon,
    required Color color,
    required String label,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _val(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
