import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../../domain/entities/rendicion_caja_chica.dart';
import '../bloc/rendicion_cubit.dart';
import '../bloc/rendicion_state.dart';

class RendicionPage extends StatelessWidget {
  final String rendicionId;

  const RendicionPage({super.key, required this.rendicionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<RendicionCubit>()..loadRendicion(rendicionId),
      child: _RendicionView(rendicionId: rendicionId),
    );
  }
}

class _RendicionView extends StatelessWidget {
  final String rendicionId;

  const _RendicionView({required this.rendicionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Detalle Rendicion',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocConsumer<RendicionCubit, RendicionState>(
          listener: (context, state) {
            if (state is RendicionApproved) {
              SnackBarHelper.showSuccess(context, 'Rendicion aprobada');
              context.read<RendicionCubit>().loadRendicion(rendicionId);
            } else if (state is RendicionRejected) {
              SnackBarHelper.showSuccess(context, 'Rendicion rechazada');
              context.read<RendicionCubit>().loadRendicion(rendicionId);
            } else if (state is RendicionError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is RendicionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RendicionDetailLoaded) {
              return _buildContent(context, state.rendicion);
            }

            if (state is RendicionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () {
                        context
                            .read<RendicionCubit>()
                            .loadRendicion(rendicionId);
                      },
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, RendicionCajaChica rendicion) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    Color estadoColor;
    switch (rendicion.estado) {
      case EstadoRendicion.pendiente:
        estadoColor = const Color(0xFFFFA726);
        break;
      case EstadoRendicion.aprobada:
        estadoColor = const Color(0xFF4CAF50);
        break;
      case EstadoRendicion.rechazada:
        estadoColor = const Color(0xFFF54D85);
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          GradientContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: estadoColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSubtitle(
                            rendicion.codigo,
                            fontSize: 16,
                            color: AppColors.blue3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rendicion.cajaChicaNombre,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rendicion.estado.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estadoColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Total Gastado',
                        currencyFormat.format(rendicion.totalGastado),
                        Icons.attach_money_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Fecha',
                        DateFormatter.formatDateTime(rendicion.creadoEn),
                        Icons.calendar_today_rounded,
                      ),
                    ),
                  ],
                ),
                if (rendicion.aprobadoPorNombre != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    'Aprobado por',
                    rendicion.aprobadoPorNombre!,
                    Icons.check_circle_rounded,
                  ),
                ],
                if (rendicion.observaciones != null &&
                    rendicion.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Observaciones:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rendicion.observaciones!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gastos list
          GradientContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(
                  'Gastos (${rendicion.gastos.length})',
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 12),
                if (rendicion.gastos.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Sin gastos asociados',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...rendicion.gastos
                      .map((gasto) =>
                          _buildGastoItem(gasto, currencyFormat))
                      .toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons (only for pending renditions)
          if (rendicion.estado == EstadoRendicion.pendiente) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Rechazar',
                    backgroundColor: const Color(0xFFF54D85),
                    height: 48,
                    onPressed: () =>
                        _showRechazarDialog(context, rendicion.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Aprobar',
                    backgroundColor: const Color(0xFF4CAF50),
                    height: 48,
                    onPressed: () =>
                        _aprobarRendicion(context, rendicion.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGastoItem(
    GastoCajaChica gasto,
    NumberFormat currencyFormat,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF54D85).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              size: 18,
              color: Color(0xFFF54D85),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gasto.descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${gasto.categoriaGastoNombre} - ${DateFormatter.formatDateTime(gasto.fechaGasto)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(gasto.monto),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF54D85),
            ),
          ),
        ],
      ),
    );
  }

  void _aprobarRendicion(BuildContext context, String rendicionId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final observacionesController = TextEditingController();
        return AlertDialog(
          title: const Text('Aprobar Rendicion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Estas seguro de aprobar esta rendicion?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacionesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<RendicionCubit>().aprobarRendicion(
                      rendicionId: rendicionId,
                      observaciones:
                          observacionesController.text.isNotEmpty
                              ? observacionesController.text
                              : null,
                    );
              },
              child: const Text('Aprobar'),
            ),
          ],
        );
      },
    );
  }

  void _showRechazarDialog(BuildContext context, String rendicionId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final observacionesController = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar Rendicion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Indica el motivo del rechazo:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacionesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Motivo del rechazo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF54D85),
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                if (observacionesController.text.trim().isEmpty) {
                  SnackBarHelper.showError(
                      dialogContext, 'Ingresa el motivo del rechazo');
                  return;
                }
                Navigator.of(dialogContext).pop();
                context.read<RendicionCubit>().rechazarRendicion(
                      rendicionId: rendicionId,
                      observaciones: observacionesController.text.trim(),
                    );
              },
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }
}
