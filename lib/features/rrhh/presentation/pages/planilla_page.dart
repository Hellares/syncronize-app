import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/periodo_planilla.dart';
import '../bloc/planilla/planilla_cubit.dart';
import '../bloc/planilla/planilla_state.dart';

class PlanillaPage extends StatefulWidget {
  const PlanillaPage({super.key});

  @override
  State<PlanillaPage> createState() => _PlanillaPageState();
}

class _PlanillaPageState extends State<PlanillaPage> {
  late final PlanillaCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<PlanillaCubit>();
    _cubit.loadPeriodos();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Planilla',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: BlocConsumer<PlanillaCubit, PlanillaState>(
            listener: (context, state) {
              if (state is PlanillaActionSuccess) {
                SnackBarHelper.showSuccess(context, state.message);
                _cubit.loadPeriodos();
              }
              if (state is PlanillaError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is PlanillaLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PlanillaPeriodosLoaded) {
                if (state.periodos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin periodos de planilla',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => await _cubit.loadPeriodos(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.periodos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildPeriodoCard(context, state.periodos[index]);
                    },
                  ),
                );
              }

              if (state is PlanillaError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                      const SizedBox(height: 12),
                      Text(state.message,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _cubit.loadPeriodos(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodoCard(BuildContext context, PeriodoPlanilla periodo) {
    return InkWell(
      onTap: () async {
        final result = await context.push(
          '/empresa/rrhh/planilla/${periodo.id}',
        );
        if (result == true) _cubit.loadPeriodos();
      },
      borderRadius: BorderRadius.circular(12),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodo.periodo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue3,
                        ),
                      ),
                      if (periodo.sedeNombre != null)
                        Text(
                          periodo.sedeNombre!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: periodo.estado.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    periodo.estado.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: periodo.estado.color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Totals
            if (periodo.totalNeto != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTotalChip('Bruto', periodo.totalBruto, Colors.blue),
                  _buildTotalChip('Descuentos', periodo.totalDescuentos, Colors.red),
                  _buildTotalChip('Neto', periodo.totalNeto, Colors.green),
                ],
              ),

            if (periodo.totalBoletas != null) ...[
              const SizedBox(height: 8),
              Text(
                '${periodo.totalBoletas} boletas',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            // Action buttons per estado
            const SizedBox(height: 12),
            _buildActionButton(context, periodo),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalChip(String label, double? value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value != null ? 'S/ ${value.toStringAsFixed(2)}' : '-',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, PeriodoPlanilla periodo) {
    switch (periodo.estado) {
      case EstadoPeriodoPlanilla.borrador:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calculate, size: 16),
            label: const Text('Calcular', style: TextStyle(fontSize: 12)),
            onPressed: () => _confirmAction(
              context,
              'Calcular Planilla',
              'Se calculara la planilla para el periodo ${periodo.periodo}.',
              () => _cubit.calcularPlanilla(periodo.id),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      case EstadoPeriodoPlanilla.calculada:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
            onPressed: () => _confirmAction(
              context,
              'Aprobar Periodo',
              'Se aprobara el periodo ${periodo.periodo}.',
              () => _cubit.aprobarPeriodo(periodo.id),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      case EstadoPeriodoPlanilla.aprobada:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.payments, size: 16),
            label: const Text('Pagar', style: TextStyle(fontSize: 12)),
            onPressed: () => _confirmAction(
              context,
              'Pagar Planilla',
              'Se procedera al pago de la planilla del periodo ${periodo.periodo}.',
              () => _cubit.pagarPlanilla(periodo.id, {'metodoPago': 'TRANSFERENCIA'}),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
