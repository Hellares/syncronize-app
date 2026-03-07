import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../empresa/presentation/widgets/stats_card.dart';
import '../../domain/usecases/get_compra_analytics_usecase.dart';
import '../bloc/compra_analytics/compra_analytics_cubit.dart';
import '../bloc/compra_analytics/compra_analytics_state.dart';
import '../widgets/analytics/gastos_line_chart.dart';
import '../widgets/analytics/top_productos_chart.dart';
import '../widgets/analytics/top_proveedores_chart.dart';
import '../widgets/analytics/comparativo_costos_card.dart';
import '../widgets/analytics/alertas_compras_widget.dart';

class CompraAnalyticsPage extends StatelessWidget {
  final String empresaId;

  const CompraAnalyticsPage({super.key, required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CompraAnalyticsCubit>()
        ..loadAnalytics(empresaId: empresaId),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Analytics de Compras',
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download, size: 18),
                onPressed: () => context.push('/empresa/compras/export'),
                tooltip: 'Exportar Excel',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => context.read<CompraAnalyticsCubit>().reload(),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          body: GradientBackground(
            style: GradientStyle.minimal,
            child: BlocBuilder<CompraAnalyticsCubit, CompraAnalyticsState>(
              builder: (context, state) {
                if (state is CompraAnalyticsLoading) {
                  return CustomLoading.small(message: 'Cargando analytics...');
                }
                if (state is CompraAnalyticsError) {
                  return _buildErrorView(context, state.message);
                }
                if (state is CompraAnalyticsLoaded) {
                  return _buildDashboard(context, state.data);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CompraAnalyticsData data) {
    final resumen = data.resumen;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CompraAnalyticsCubit>().reload();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                StatsCard(
                  title: 'Total Compras',
                  value: resumen.totalCompras.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'Monto Total',
                  value: _formatCurrency(resumen.montoTotal),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Promedio',
                  value: _formatCurrency(resumen.promedioPorCompra),
                  icon: Icons.analytics,
                  color: Colors.orange,
                ),
                StatsCard(
                  title: 'Pendientes',
                  value: resumen.comprasPendientes.toString(),
                  icon: Icons.pending,
                  color: resumen.comprasPendientes > 0 ? Colors.red : Colors.grey,
                ),
                StatsCard(
                  title: 'Total OC',
                  value: resumen.totalOrdenesCompra.toString(),
                  icon: Icons.description,
                  color: Colors.teal,
                ),
                StatsCard(
                  title: 'OC Pendientes',
                  value: resumen.ocPendientes.toString(),
                  icon: Icons.pending_actions,
                  color: resumen.ocPendientes > 0 ? Colors.amber.shade700 : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spending Trend
            _SectionCard(
              title: 'Tendencia de Gastos',
              icon: Icons.show_chart,
              child: GastosLineChart(gastos: data.gastosPeriodo),
            ),
            const SizedBox(height: 16),

            // Cost Comparison
            _SectionCard(
              title: 'Comparativo de Costos',
              icon: Icons.compare_arrows,
              child: ComparativoCostosCard(comparativo: data.comparativo),
            ),
            const SizedBox(height: 16),

            // Top Products
            _SectionCard(
              title: 'Top Productos',
              icon: Icons.inventory_2,
              child: TopProductosChart(productos: data.topProductos),
            ),
            const SizedBox(height: 16),

            // Top Suppliers
            _SectionCard(
              title: 'Top Proveedores',
              icon: Icons.local_shipping,
              child: TopProveedoresChart(proveedores: data.topProveedores),
            ),
            const SizedBox(height: 16),

            // Alerts
            _SectionCard(
              title: 'Alertas (${data.alertas.length})',
              icon: Icons.notification_important,
              child: AlertasComprasWidget(alertas: data.alertas),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<CompraAnalyticsCubit>().reload(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return 'S/${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'S/${(value / 1000).toStringAsFixed(1)}K';
    return 'S/${value.toStringAsFixed(0)}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
