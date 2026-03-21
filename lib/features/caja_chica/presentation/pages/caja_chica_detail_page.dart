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
import '../../domain/entities/caja_chica.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../bloc/caja_chica_detail_cubit.dart';
import '../bloc/caja_chica_detail_state.dart';
import '../bloc/rendicion_cubit.dart';
import '../bloc/rendicion_state.dart';
import 'historial_rendiciones_page.dart';
import 'nuevo_gasto_page.dart';

class CajaChicaDetailPage extends StatelessWidget {
  final String cajaChicaId;

  const CajaChicaDetailPage({super.key, required this.cajaChicaId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              locator<CajaChicaDetailCubit>()..loadDetail(cajaChicaId),
        ),
        BlocProvider(create: (_) => locator<RendicionCubit>()),
      ],
      child: _CajaChicaDetailView(cajaChicaId: cajaChicaId),
    );
  }
}

class _CajaChicaDetailView extends StatelessWidget {
  final String cajaChicaId;

  const _CajaChicaDetailView({required this.cajaChicaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Detalle Caja Chica',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocConsumer<CajaChicaDetailCubit, CajaChicaDetailState>(
          listener: (context, state) {
            if (state is CajaChicaDetailError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is CajaChicaDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CajaChicaDetailError) {
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
                            .read<CajaChicaDetailCubit>()
                            .loadDetail(cajaChicaId);
                      },
                    ),
                  ],
                ),
              );
            }

            if (state is CajaChicaDetailLoaded) {
              return _buildContent(
                context,
                state.cajaChica,
                state.gastosPendientes,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CajaChica cajaChica,
    List<GastoCajaChica> gastosPendientes,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    final porcentajeUsado = cajaChica.porcentajeUsado.clamp(0.0, 1.0);
    final isActiva = cajaChica.estado == EstadoCajaChica.activa;
    final estadoColor =
        isActiva ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E);

    Color progressColor;
    if (porcentajeUsado < 0.5) {
      progressColor = const Color(0xFF4CAF50);
    } else if (porcentajeUsado < 0.8) {
      progressColor = const Color(0xFFFFA726);
    } else {
      progressColor = const Color(0xFFF54D85);
    }

    return BlocListener<RendicionCubit, RendicionState>(
      listener: (context, rendicionState) {
        if (rendicionState is RendicionCreated) {
          SnackBarHelper.showSuccess(context, 'Rendicion creada exitosamente');
          context.read<CajaChicaDetailCubit>().reload();
        } else if (rendicionState is RendicionError) {
          SnackBarHelper.showError(context, rendicionState.message);
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<CajaChicaDetailCubit>().reload();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.blue1,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSubtitle(
                                cajaChica.nombre,
                                fontSize: 16,
                                color: AppColors.blue3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cajaChica.sedeNombre,
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
                            cajaChica.estado.label,
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
                            'Responsable',
                            cajaChica.responsableNombre,
                            Icons.person_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Fondo Fijo',
                            currencyFormat.format(cajaChica.fondoFijo),
                            Icons.savings_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Saldo Actual',
                            currencyFormat.format(cajaChica.saldoActual),
                            Icons.attach_money_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Umbral Alerta',
                            currencyFormat.format(cajaChica.umbralAlerta),
                            Icons.warning_amber_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: porcentajeUsado,
                        backgroundColor: AppColors.greyLight,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(porcentajeUsado * 100).toStringAsFixed(0)}% del fondo utilizado',
                      style: TextStyle(
                        fontSize: 12,
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      'Nuevo Gasto',
                      Icons.add_circle_rounded,
                      AppColors.blue2,
                      () => _navigateToNuevoGasto(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      'Ver Rendiciones',
                      Icons.receipt_long_rounded,
                      AppColors.blue1,
                      () => _navigateToRendiciones(context, cajaChica.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gastos pendientes section
              GradientContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppSubtitle(
                          'Gastos Pendientes',
                          fontSize: 14,
                          color: AppColors.blue3,
                        ),
                        if (gastosPendientes.isNotEmpty)
                          Text(
                            '${gastosPendientes.length} gastos',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (gastosPendientes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_rounded,
                                size: 40,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sin gastos pendientes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...gastosPendientes
                          .map((gasto) =>
                              _buildGastoItem(gasto, currencyFormat))
                          .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Crear rendicion button
              if (gastosPendientes.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<RendicionCubit, RendicionState>(
                    builder: (context, rendicionState) {
                      final isLoading = rendicionState is RendicionLoading;
                      return CustomButton(
                        text: 'Crear Rendicion',
                        backgroundColor: const Color(0xFF4CAF50),
                        height: 48,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => _crearRendicion(
                                  context,
                                  cajaChica.id,
                                  gastosPendientes,
                                ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GradientContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            '- ${currencyFormat.format(gasto.monto)}',
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

  void _navigateToNuevoGasto(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => NuevoGastoPage(cajaChicaId: cajaChicaId),
      ),
    )
        .then((result) {
      if (result == true) {
        context.read<CajaChicaDetailCubit>().reload();
      }
    });
  }

  void _navigateToRendiciones(BuildContext context, String cajaChicaId) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) =>
            HistorialRendicionesPage(cajaChicaId: cajaChicaId),
      ),
    )
        .then((_) {
      context.read<CajaChicaDetailCubit>().reload();
    });
  }

  void _crearRendicion(
    BuildContext context,
    String cajaChicaId,
    List<GastoCajaChica> gastosPendientes,
  ) {
    final gastoIds = gastosPendientes.map((g) => g.id).toList();
    context.read<RendicionCubit>().crearRendicion(
          cajaChicaId: cajaChicaId,
          gastoIds: gastoIds,
        );
  }
}
