import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_state.dart';

class CajasActivasCard extends StatelessWidget {
  const CajasActivasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(14),
      child: BlocBuilder<ResumenFinancieroCubit, ResumenFinancieroState>(
        builder: (context, state) {
          if (state is ResumenFinancieroLoading ||
              state is ResumenFinancieroInitial) {
            return const SizedBox(
              height: 80,
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
            );
          }
          if (state is ResumenFinancieroError) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  'No se pudo cargar datos de caja',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            );
          }
          if (state is ResumenFinancieroLoaded) {
            return _buildContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(ResumenFinancieroLoaded state) {
    final data = state.resumen.data;
    final caja = data['caja'] as Map<String, dynamic>?;

    if (caja == null) {
      return _buildEmpty();
    }

    final ingresos = _val(caja, 'ingresosHoy');
    final egresos = _val(caja, 'egresosHoy');
    final flujo = _val(caja, 'flujoHoy');
    final abiertas = caja['cajasAbiertas'] as int? ?? 0;

    if (ingresos == 0 && egresos == 0 && abiertas == 0) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.point_of_sale, size: 16, color: AppColors.blue1),
            const SizedBox(width: 6),
            const AppSubtitle('Caja Hoy',
                fontSize: 12, color: AppColors.blue1),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: abiertas > 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$abiertas abierta${abiertas != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  color: abiertas > 0 ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _miniMetric('Ingresos', ingresos, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _miniMetric('Egresos', egresos, Colors.red)),
            const SizedBox(width: 8),
            Expanded(
              child: _miniMetric(
                'Flujo',
                flujo,
                flujo >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, size: 16, color: AppColors.blue1),
          const SizedBox(width: 6),
          const AppSubtitle('Caja Hoy',
              fontSize: 12, color: AppColors.blue1),
          const Spacer(),
          Text(
            'Sin actividad de caja hoy',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, double monto, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'S/ ${monto.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
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
