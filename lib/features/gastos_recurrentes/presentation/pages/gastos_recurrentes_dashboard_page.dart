import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/pagar_gasto_dialog.dart';
import 'gasto_recurrente_detail_page.dart';
import 'gasto_recurrente_form_page.dart';
import 'gastos_recurrentes_reportes_page.dart';

class GastosRecurrentesDashboardPage extends StatelessWidget {
  const GastosRecurrentesDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<DashboardGastosCubit>()..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static final _money = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Gastos Recurrentes',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined),
            tooltip: 'Reportes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GastosRecurrentesReportesPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (innerContext) => FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () async {
            final created = await Navigator.of(innerContext).push<bool>(
              MaterialPageRoute(builder: (_) => const GastoRecurrenteFormPage()),
            );
            if (created == true && innerContext.mounted) {
              innerContext.read<DashboardGastosCubit>().reload();
            }
          },
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: GradientContainer(
        child: BlocConsumer<DashboardGastosCubit, DashboardGastosState>(
          listener: (context, state) {
            if (state is DashboardGastosError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is DashboardGastosLoading || state is DashboardGastosInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardGastosError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () => context.read<DashboardGastosCubit>().reload(),
                    ),
                  ],
                ),
              );
            }

            if (state is DashboardGastosLoaded) {
              final data = state.data;
              return RefreshIndicator(
                onRefresh: () async => context.read<DashboardGastosCubit>().reload(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _periodoSelector(context, state.periodo)),
                    SliverToBoxAdapter(child: _resumenCards(data.resumen)),
                    if (data.items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: data.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _itemCard(context, data.items[i]),
                        ),
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

  Widget _periodoSelector(BuildContext context, String periodo) {
    final parts = periodo.split('-');
    final anio = int.tryParse(parts[0]) ?? DateTime.now().year;
    final mes = int.tryParse(parts[1]) ?? DateTime.now().month;
    final label = DateFormat.yMMMM('es_PE').format(DateTime(anio, mes));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.blue1),
            onPressed: () {
              final prev = DateTime(anio, mes - 1);
              final p = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
              context.read<DashboardGastosCubit>().cambiarPeriodo(p);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.blue1),
            onPressed: () {
              final next = DateTime(anio, mes + 1);
              final p = '${next.year}-${next.month.toString().padLeft(2, '0')}';
              context.read<DashboardGastosCubit>().cambiarPeriodo(p);
            },
          ),
        ],
      ),
    );
  }

  Widget _resumenCards(DashboardGastosResumen r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _miniCard(
            color: const Color(0xFF4CAF50),
            icon: Icons.check_circle_outline,
            label: 'Pagados',
            cuenta: r.pagados,
            monto: r.montoPagado,
          ),
          const SizedBox(width: 8),
          _miniCard(
            color: const Color(0xFFFFA726),
            icon: Icons.schedule,
            label: 'Pendientes',
            cuenta: r.pendientes,
            monto: r.montoPendiente,
          ),
          const SizedBox(width: 8),
          _miniCard(
            color: const Color(0xFFE53935),
            icon: Icons.error_outline,
            label: 'Vencidos',
            cuenta: r.vencidos,
            monto: r.montoVencido,
          ),
        ],
      ),
    );
  }

  Widget _miniCard({
    required Color color,
    required IconData icon,
    required String label,
    required int cuenta,
    required double monto,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$cuenta',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              _money.format(monto),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(BuildContext context, DashboardGastoItem item) {
    final estadoColor = _estadoColor(item.estado);
    final g = item.gasto;
    final pago = item.pagoPeriodo;
    final monto = pago?.montoReal ?? g.montoEstimado;
    final periodo = (context.read<DashboardGastosCubit>().state as DashboardGastosLoaded).periodo;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GastoRecurrenteDetailPage(gastoId: g.id),
          ),
        );
        if (context.mounted) {
          context.read<DashboardGastosCubit>().reload();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_estadoIcon(item.estado), color: estadoColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.nombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${g.categoriaGastoNombre} · vence día ${g.diaVencimiento}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money.format(monto),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.estado.label,
                      style: TextStyle(fontSize: 11, color: estadoColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (pago != null) ...[
            const Divider(height: 18),
            Row(
              children: [
                Icon(
                  pago.fuente == FuentePagoGasto.caja
                      ? Icons.point_of_sale
                      : Icons.account_balance,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pago.fuente.label} · ${pago.metodoPago.label}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (pago.comprobanteUrl != null)
                  const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final ok = await PagarGastoDialog.show(
                      context,
                      gasto: g,
                      periodo: periodo,
                    );
                    if (ok == true && context.mounted) {
                      context.read<DashboardGastosCubit>().reload();
                    }
                  },
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Marcar pagado'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _estadoColor(EstadoPeriodoGasto e) {
    switch (e) {
      case EstadoPeriodoGasto.pagado:
        return const Color(0xFF4CAF50);
      case EstadoPeriodoGasto.pendiente:
        return const Color(0xFFFFA726);
      case EstadoPeriodoGasto.vencido:
        return const Color(0xFFE53935);
    }
  }

  IconData _estadoIcon(EstadoPeriodoGasto e) {
    switch (e) {
      case EstadoPeriodoGasto.pagado:
        return Icons.check_circle;
      case EstadoPeriodoGasto.pendiente:
        return Icons.schedule;
      case EstadoPeriodoGasto.vencido:
        return Icons.error;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay gastos recurrentes para este período',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Crea uno desde el botón "+" para programar luz, agua, alquiler, etc.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
