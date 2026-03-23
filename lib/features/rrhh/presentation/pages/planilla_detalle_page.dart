import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/boleta_pago.dart';
import '../../domain/entities/periodo_planilla.dart';
import '../bloc/planilla/planilla_cubit.dart';
import '../bloc/planilla/planilla_state.dart';

class PlanillaDetallePage extends StatefulWidget {
  final String periodoId;

  const PlanillaDetallePage({super.key, required this.periodoId});

  @override
  State<PlanillaDetallePage> createState() => _PlanillaDetallePageState();
}

class _PlanillaDetallePageState extends State<PlanillaDetallePage> {
  late final PlanillaCubit _cubit;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _cubit = locator<PlanillaCubit>();
    _cubit.loadPeriodoDetail(widget.periodoId);
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
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && _hasChanges) {
            // Parent will refresh
          }
        },
        child: Scaffold(
          appBar: SmartAppBar(
            title: 'Detalle Planilla',
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
          ),
          body: GradientContainer(
            child: BlocConsumer<PlanillaCubit, PlanillaState>(
              listener: (context, state) {
                if (state is PlanillaActionSuccess) {
                  _hasChanges = true;
                  SnackBarHelper.showSuccess(context, state.message);
                  _cubit.loadPeriodoDetail(widget.periodoId);
                }
                if (state is PlanillaError) {
                  SnackBarHelper.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is PlanillaLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PlanillaPeriodoDetailLoaded) {
                  return _buildContent(context, state.periodo);
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
                          onPressed: () =>
                              _cubit.loadPeriodoDetail(widget.periodoId),
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, PeriodoPlanilla periodo) {
    return RefreshIndicator(
      onRefresh: () async =>
          await _cubit.loadPeriodoDetail(widget.periodoId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          _buildHeaderCard(periodo),
          const SizedBox(height: 16),

          // Totals card
          _buildTotalsCard(periodo),
          const SizedBox(height: 16),

          // Bulk pay button for APROBADA
          if (periodo.estaAprobada) ...[
            CustomButton(
              text: 'Pagar Toda la Planilla',
              backgroundColor: Colors.teal,
              onPressed: () => _confirmAction(
                context,
                'Pagar Planilla',
                'Se pagara toda la planilla del periodo ${periodo.periodo}.',
                () => _cubit.pagarPlanilla(
                    periodo.id, {'metodoPago': 'TRANSFERENCIA'}),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Boletas list
          if (periodo.boletas != null && periodo.boletas!.isNotEmpty) ...[
            Text(
              'Boletas (${periodo.boletas!.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.blue3,
              ),
            ),
            const SizedBox(height: 10),
            ...periodo.boletas!.map(
              (boleta) => _buildBoletaCard(context, boleta),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sin boletas en este periodo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(PeriodoPlanilla periodo) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  periodo.periodo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
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
          _buildInfoRow('Rango',
              '${DateFormatter.formatDate(periodo.fechaInicio)} - ${DateFormatter.formatDate(periodo.fechaFin)}'),
          _buildInfoRow('Sede', periodo.sedeNombre ?? '-'),
          if (periodo.calculadoPorNombre != null)
            _buildInfoRow('Calculado por', periodo.calculadoPorNombre!),
          if (periodo.aprobadoPorNombre != null)
            _buildInfoRow('Aprobado por', periodo.aprobadoPorNombre!),
          if (periodo.fechaAprobacion != null)
            _buildInfoRow(
                'Fecha aprobacion', DateFormatter.formatDateTime(periodo.fechaAprobacion!)),
          if (periodo.observaciones != null &&
              periodo.observaciones!.isNotEmpty)
            _buildInfoRow('Observaciones', periodo.observaciones!),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(PeriodoPlanilla periodo) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.blue3,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAmountCard(
                  'Total Bruto',
                  periodo.totalBruto,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAmountCard(
                  'Descuentos',
                  periodo.totalDescuentos,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAmountCard(
                  'Aportaciones',
                  periodo.totalAportaciones,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAmountCard(
                  'Total Neto',
                  periodo.totalNeto,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(String label, double? value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? 'S/ ${value.toStringAsFixed(2)}' : '-',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoletaCard(BuildContext context, BoletaPago boleta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final result = await context.push(
            '/empresa/rrhh/planilla/boleta/${boleta.id}',
          );
          if (result == true) {
            _hasChanges = true;
            _cubit.loadPeriodoDetail(widget.periodoId);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: GradientContainer(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: boleta.estado.color.withValues(alpha: 0.1),
                child: Text(
                  (boleta.empleadoNombre ?? 'E').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: boleta.estado.color,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boleta.empleadoNombre ?? 'Empleado',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      boleta.empleadoCodigo ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Neto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${boleta.totalNeto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: boleta.estado.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      boleta.estado.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: boleta.estado.color,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
