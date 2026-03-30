import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../domain/entities/pago_suscripcion.dart';
import '../bloc/mis_pagos/mis_pagos_cubit.dart';

class MisPagosPage extends StatelessWidget {
  const MisPagosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MisPagosSuscripcionCubit>()..loadPagos(),
      child: const _MisPagosView(),
    );
  }
}

class _MisPagosView extends StatelessWidget {
  const _MisPagosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle('Mis Pagos de Suscripcion', fontSize: 16),
      ),
      body: BlocBuilder<MisPagosSuscripcionCubit, MisPagosSuscripcionState>(
        builder: (context, state) {
          if (state is MisPagosSuscripcionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MisPagosSuscripcionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 48),
                  const SizedBox(height: 16),
                  AppText(state.message,
                      size: 14,
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<MisPagosSuscripcionCubit>().reload(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is MisPagosSuscripcionLoaded) {
            if (state.pagos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long,
                        size: 64,
                        color: AppColors.blue1.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const AppText(
                      'No tienes pagos registrados',
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<MisPagosSuscripcionCubit>().reload(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.pagos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _PagoCard(pago: state.pagos[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PagoCard extends StatelessWidget {
  final PagoSuscripcion pago;

  const _PagoCard({required this.pago});

  LinearGradient get _gradient {
    switch (pago.estado) {
      case 'COMPLETADO':
        return AppGradients.blueWhitegreen();
      case 'ANULADO':
        return AppGradients.gray();
      case 'PENDIENTE':
      default:
        return AppGradients.orangeWhiteBlue();
    }
  }

  Color get _borderColor {
    switch (pago.estado) {
      case 'COMPLETADO':
        return AppColors.green;
      case 'ANULADO':
        return AppColors.red;
      case 'PENDIENTE':
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      gradient: _gradient,
      borderColor: _borderColor,
      borderWidth: 0.8,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      shadowStyle: ShadowStyle.colorful,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: plan name + estado badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium,
                    color: AppColors.blue1, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      pago.planNombre ?? 'Plan Suscripcion',
                      fontSize: 13,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      'S/ ${pago.monto.toStringAsFixed(2)} - ${_formatPeriodo(pago.periodo)}',
                      size: 11,
                      color: AppColors.blue1,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              _buildEstadoBadge(pago.estado),
            ],
          ),
          const SizedBox(height: 12),

          // Info row: metodo pago + fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(_getMetodoPagoIcon(pago.metodoPago),
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                AppText(
                  _formatMetodoPago(pago.metodoPago),
                  size: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                const Spacer(),
                if (pago.creadoEn != null) ...[
                  const Icon(Icons.calendar_today,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  AppText(
                    DateFormatter.formatDate(
                        DateFormatter.toLocal(pago.creadoEn!)),
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),

          // Motivo rechazo
          if (pago.motivoRechazo != null &&
              pago.motivoRechazo!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      'Rechazado: ${pago.motivoRechazo!}',
                      size: 11,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Comprobante thumbnail
          if (pago.comprobantePagoUrl != null &&
              pago.comprobantePagoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: pago.comprobantePagoUrl!,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 60,
                      width: 60,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.image,
                          color: AppColors.textSecondary, size: 20),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 60,
                      width: 60,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const AppText(
                  'Comprobante enviado',
                  size: 11,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bgColor;
    Color textColor;
    switch (estado) {
      case 'COMPLETADO':
        bgColor = AppColors.greenContainer;
        textColor = AppColors.green;
        break;
      case 'ANULADO':
        bgColor = AppColors.red.withValues(alpha: 0.1);
        textColor = AppColors.red;
        break;
      case 'PENDIENTE':
      default:
        bgColor = AppColors.orange.withValues(alpha: 0.12);
        textColor = AppColors.orange;
        break;
    }

    return InfoChip(
      text: _formatEstado(estado),
      backgroundColor: bgColor,
      textColor: textColor,
      borderColor: textColor.withValues(alpha: 0.3),
      borderRadius: 6,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  IconData _getMetodoPagoIcon(String metodo) {
    switch (metodo) {
      case 'YAPE':
      case 'PLIN':
        return Icons.phone_android;
      case 'TRANSFERENCIA':
        return Icons.account_balance;
      case 'TARJETA':
        return Icons.credit_card;
      case 'EFECTIVO':
        return Icons.payments_outlined;
      default:
        return Icons.payment;
    }
  }

  String _formatMetodoPago(String metodo) {
    switch (metodo) {
      case 'YAPE':
        return 'Yape';
      case 'PLIN':
        return 'Plin';
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'TARJETA':
        return 'Tarjeta';
      case 'EFECTIVO':
        return 'Efectivo';
      default:
        return metodo;
    }
  }

  String _formatEstado(String estado) {
    switch (estado) {
      case 'COMPLETADO':
        return 'Completado';
      case 'ANULADO':
        return 'Anulado';
      case 'PENDIENTE':
        return 'Pendiente';
      default:
        return estado;
    }
  }

  String _formatPeriodo(String periodo) {
    switch (periodo) {
      case 'SEMESTRAL':
        return 'Semestral';
      case 'ANUAL':
        return 'Anual';
      default:
        return 'Mensual';
    }
  }
}
