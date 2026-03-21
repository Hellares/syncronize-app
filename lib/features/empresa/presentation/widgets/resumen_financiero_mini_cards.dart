import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart';
import '../../../resumen_financiero/presentation/bloc/resumen_financiero_state.dart';

class ResumenFinancieroMiniCards extends StatelessWidget {
  const ResumenFinancieroMiniCards({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: BlocBuilder<ResumenFinancieroCubit, ResumenFinancieroState>(
        builder: (context, state) {
          if (state is ResumenFinancieroLoading ||
              state is ResumenFinancieroInitial) {
            return const SizedBox(
              height: 140,
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
              height: 80,
              child: Center(
                child: Text(
                  'No se pudo cargar el resumen',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            );
          }
          if (state is ResumenFinancieroLoaded) {
            return _buildGrid(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGrid(ResumenFinancieroLoaded state) {
    final data = state.resumen.data;
    final ventas = data['ventas'] as Map<String, dynamic>?;
    final caja = data['caja'] as Map<String, dynamic>?;
    final cobrar = data['cuentasPorCobrar'] as Map<String, dynamic>?;
    final pagar = data['cuentasPorPagar'] as Map<String, dynamic>?;

    final totalVentas = _val(ventas, 'totalVentas');
    final cantidadVentas = ventas?['cantidad'] ?? 0;
    final ingresosHoy = _val(caja, 'ingresosHoy');
    final totalVencidoCobrar = _val(cobrar, 'totalVencido');
    final totalVencidoPagar = _val(pagar, 'totalVencido');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard, size: 16, color: AppColors.blue1),
            const SizedBox(width: 6),
            const AppSubtitle('Resumen Financiero',
                fontSize: 12, color: AppColors.blue3),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniFinancialCard(
                icon: Icons.point_of_sale,
                color: AppColors.green,
                value: 'S/ ${totalVentas.toStringAsFixed(2)}',
                label: 'Ventas del mes',
                subtitle: '$cantidadVentas ventas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniFinancialCard(
                icon: Icons.account_balance_wallet,
                color: AppColors.blue1,
                value: 'S/ ${ingresosHoy.toStringAsFixed(2)}',
                label: 'Ingresos hoy',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MiniFinancialCard(
                icon: Icons.arrow_downward,
                color: totalVencidoCobrar > 0 ? AppColors.red : Colors.grey,
                value: 'S/ ${totalVencidoCobrar.toStringAsFixed(2)}',
                label: 'Cuentas por cobrar vencidas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniFinancialCard(
                icon: Icons.arrow_upward,
                color: totalVencidoPagar > 0 ? AppColors.red : Colors.grey,
                value: 'S/ ${totalVencidoPagar.toStringAsFixed(2)}',
                label: 'Cuentas por pagar vencidas',
              ),
            ),
          ],
        ),
      ],
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

class _MiniFinancialCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? subtitle;

  const _MiniFinancialCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style:
                        TextStyle(fontSize: 8, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
