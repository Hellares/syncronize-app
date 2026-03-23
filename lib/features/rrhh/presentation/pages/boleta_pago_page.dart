import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';

import '../../domain/entities/boleta_pago.dart';
import '../bloc/planilla/planilla_cubit.dart';
import '../bloc/planilla/planilla_state.dart';

class BoletaPagoPage extends StatefulWidget {
  final String boletaId;

  const BoletaPagoPage({super.key, required this.boletaId});

  @override
  State<BoletaPagoPage> createState() => _BoletaPagoPageState();
}

class _BoletaPagoPageState extends State<BoletaPagoPage> {
  late final PlanillaCubit _cubit;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _cubit = locator<PlanillaCubit>();
    _cubit.loadBoleta(widget.boletaId);
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
            title: 'Boleta de Pago',
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
          ),
          body: GradientContainer(
            child: BlocConsumer<PlanillaCubit, PlanillaState>(
              listener: (context, state) {
                if (state is PlanillaActionSuccess) {
                  _hasChanges = true;
                  SnackBarHelper.showSuccess(context, state.message);
                  _cubit.loadBoleta(widget.boletaId);
                }
                if (state is PlanillaError) {
                  SnackBarHelper.showError(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is PlanillaLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PlanillaBoletaLoaded) {
                  return _buildContent(context, state.boleta);
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
                          onPressed: () => _cubit.loadBoleta(widget.boletaId),
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

  Widget _buildContent(BuildContext context, BoletaPago boleta) {
    final ingresos = boleta.detalles
            ?.where((d) => d.tipo == TipoDetalleBoleta.ingreso)
            .toList() ??
        [];
    final descuentos = boleta.detalles
            ?.where((d) => d.tipo == TipoDetalleBoleta.descuento)
            .toList() ??
        [];
    final aportes = boleta.detalles
            ?.where((d) => d.tipo == TipoDetalleBoleta.aporteEmpleador)
            .toList() ??
        [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Employee header
        _buildEmpleadoHeader(boleta),
        const SizedBox(height: 16),

        // Work summary
        _buildWorkSummary(boleta),
        const SizedBox(height: 16),

        // Ingresos table
        if (ingresos.isNotEmpty) ...[
          _buildDetalleTable('Ingresos', ingresos, Colors.green),
          const SizedBox(height: 12),
        ],

        // Descuentos table
        if (descuentos.isNotEmpty) ...[
          _buildDetalleTable('Descuentos', descuentos, Colors.red),
          const SizedBox(height: 12),
        ],

        // Aportes table
        if (aportes.isNotEmpty) ...[
          _buildDetalleTable('Aportes del Empleador', aportes, Colors.purple),
          const SizedBox(height: 12),
        ],

        // Neto highlight
        _buildNetoCard(boleta),
        const SizedBox(height: 20),

        // Pay button
        if (boleta.estaPendiente)
          CustomButton(
            text: 'Pagar Boleta',
            backgroundColor: Colors.green,
            onPressed: () => _confirmPay(context, boleta),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmpleadoHeader(BoletaPago boleta) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: boleta.estado.color.withValues(alpha: 0.1),
            child: Text(
              (boleta.empleadoNombre ?? 'E').substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: boleta.estado.color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boleta.empleadoNombre ?? 'Empleado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (boleta.empleadoCodigo != null)
                  Text(
                    boleta.empleadoCodigo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.blue1,
                    ),
                  ),
                if (boleta.empleadoCargo != null)
                  Text(
                    boleta.empleadoCargo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (boleta.empleadoDepartamento != null)
                  Text(
                    boleta.empleadoDepartamento!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: boleta.estado.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              boleta.estado.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: boleta.estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkSummary(BoletaPago boleta) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen Laboral',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.blue3,
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Dias Trab.', '${boleta.diasTrabajados}', Colors.blue)),
              Expanded(child: _buildMiniStat('Faltas', '${boleta.diasFalta}', Colors.red)),
              Expanded(child: _buildMiniStat('Tardanzas', '${boleta.diasTardanza}', Colors.orange)),
              Expanded(child: _buildMiniStat('Hrs Extra', boleta.horasExtra.toStringAsFixed(1), Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Salario Base', 'S/ ${boleta.salarioBase.toStringAsFixed(2)}'),
          if (boleta.periodoPeriodo != null)
            _buildInfoRow('Periodo', boleta.periodoPeriodo!),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetalleTable(
      String title, List<DetalleBoletaPago> detalles, Color color) {
    final total = detalles.fold<double>(0, (sum, d) => sum + d.monto);

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Detail rows
          ...detalles.map((detalle) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detalle.concepto,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (detalle.descripcion != null &&
                              detalle.descripcion!.isNotEmpty)
                            Text(
                              detalle.descripcion!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (detalle.porcentaje != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${detalle.porcentaje!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    Text(
                      'S/ ${detalle.monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 12),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetoCard(BoletaPago boleta) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.08),
            Colors.green.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL NETO A PAGAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'S/ ${boleta.totalNeto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSummaryChip('Ingresos', boleta.totalIngresos, Colors.blue),
              const SizedBox(width: 8),
              const Text('-', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              _buildSummaryChip('Descuentos', boleta.totalDescuentos, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          'S/ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPay(BuildContext context, BoletaPago boleta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagar Boleta'),
        content: Text(
          'Se registrara el pago de S/ ${boleta.totalNeto.toStringAsFixed(2)} para ${boleta.empleadoNombre ?? 'el empleado'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cubit.pagarBoleta(boleta.id, {'metodoPago': 'TRANSFERENCIA'});
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }
}
