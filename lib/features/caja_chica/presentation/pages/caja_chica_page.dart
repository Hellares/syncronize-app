import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/caja_chica.dart';
import '../bloc/caja_chica_list_cubit.dart';
import '../bloc/caja_chica_list_state.dart';
import 'caja_chica_detail_page.dart';
import 'crear_caja_chica_page.dart';

class CajaChicaPage extends StatelessWidget {
  const CajaChicaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CajaChicaListCubit>()..loadCajasChicas(),
      child: const _CajaChicaView(),
    );
  }
}

class _CajaChicaView extends StatelessWidget {
  const _CajaChicaView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Cajas Chicas',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue1,
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => const CrearCajaChicaPage(),
            ),
          )
              .then((result) {
            if (result == true) {
              context.read<CajaChicaListCubit>().reload();
            }
          });
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: GradientContainer(
        child: BlocConsumer<CajaChicaListCubit, CajaChicaListState>(
          listener: (context, state) {
            if (state is CajaChicaListError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is CajaChicaListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CajaChicaListError) {
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
                        context.read<CajaChicaListCubit>().reload();
                      },
                    ),
                  ],
                ),
              );
            }

            if (state is CajaChicaListLoaded) {
              if (state.cajasChicas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 56,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay cajas chicas',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea una caja chica para comenzar',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<CajaChicaListCubit>().reload();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.cajasChicas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildCajaChicaCard(
                        context, state.cajasChicas[index]);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCajaChicaCard(BuildContext context, CajaChica cajaChica) {
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

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => CajaChicaDetailPage(cajaChicaId: cajaChica.id),
          ),
        )
            .then((_) {
          context.read<CajaChicaListCubit>().reload();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
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
                        fontSize: 15,
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
            const SizedBox(height: 16),

            // Saldo info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo: ${currencyFormat.format(cajaChica.saldoActual)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Fondo: ${currencyFormat.format(cajaChica.fondoFijo)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentajeUsado,
                backgroundColor: AppColors.greyLight,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),

            // Progress label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(porcentajeUsado * 100).toStringAsFixed(0)}% usado',
                  style: TextStyle(
                    fontSize: 11,
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cajaChica.fondoBajo)
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: const Color(0xFFFFA726),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Fondo bajo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFFA726),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Responsable
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  cajaChica.responsableNombre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
