import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/venta_analytics/venta_analytics_cubit.dart';
import '../bloc/venta_analytics/venta_analytics_state.dart';

class VentaAnalyticsPage extends StatefulWidget {
  const VentaAnalyticsPage({super.key});

  @override
  State<VentaAnalyticsPage> createState() => _VentaAnalyticsPageState();
}

class _VentaAnalyticsPageState extends State<VentaAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<VentaAnalyticsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Reportes de Ventas',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: BlocBuilder<VentaAnalyticsCubit, VentaAnalyticsState>(
        builder: (context, state) {
          if (state is VentaAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VentaAnalyticsError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
              ],
            ));
          }
          if (state is VentaAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildResumenCards(state.resumen),
                  const SizedBox(height: 16),
                  _buildComparativo(state.comparativo),
                  const SizedBox(height: 16),
                  _buildTopProductos(state.topProductos),
                  const SizedBox(height: 16),
                  _buildTopClientes(state.topClientes),
                  const SizedBox(height: 16),
                  _buildVentasPeriodo(state.ventasPeriodo),
                  if (state.alertas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAlertas(state.alertas),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildResumenCards(Map<String, dynamic> resumen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Resumen General', fontSize: 14),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: [
            _kpiCard('Total Ventas', '${resumen['totalVentas'] ?? 0}', Icons.receipt_long, Colors.blue),
            _kpiCard('Monto Total', 'S/${_formatNumber(resumen['montoTotal'])}', Icons.attach_money, Colors.green),
            _kpiCard('Ticket Promedio', 'S/${_formatNumber(resumen['promedioPorVenta'])}', Icons.trending_up, Colors.orange),
            _kpiCard('Pendientes', '${resumen['ventasBorrador'] ?? 0}', Icons.pending, Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return GradientContainer(
      borderColor: color.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
            ]),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparativo(Map<String, dynamic> comparativo) {
    final actual = comparativo['periodoActual'] as Map<String, dynamic>?;
    final anterior = comparativo['periodoAnterior'] as Map<String, dynamic>?;
    final cambio = (comparativo['porcentajeCambio'] ?? 0).toDouble();
    final isPositive = cambio >= 0;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Comparativo Mensual', fontSize: 13),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(children: [
              Text('Periodo Actual', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/${_formatNumber(actual?['total'])}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${actual?['cantidad'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14, color: isPositive ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('${cambio.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: isPositive ? Colors.green : Colors.red)),
              ]),
            ),
            Expanded(child: Column(children: [
              Text('Periodo Anterior', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('S/${_formatNumber(anterior?['total'])}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              Text('${anterior?['cantidad'] ?? 0} ventas', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTopProductos(List<dynamic> productos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Productos', fontSize: 13),
          const SizedBox(height: 12),
          if (productos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...productos.take(5).map((p) {
              final item = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${item['cantidadVendida'] ?? 0} vendidos', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ])),
                  Text('S/${_formatNumber(item['ingresoTotal'])}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildTopClientes(List<dynamic> clientes) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Top Clientes', fontSize: 13),
          const SizedBox(height: 12),
          if (clientes.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...clientes.take(5).map((c) {
              final item = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${item['totalCompras'] ?? 0} compras', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ])),
                  Text('S/${_formatNumber(item['montoTotal'])}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildVentasPeriodo(List<dynamic> periodos) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSubtitle('Ventas por Periodo', fontSize: 13),
          const SizedBox(height: 12),
          if (periodos.isEmpty)
            Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade500)))
          else
            ...periodos.take(12).map((p) {
              final item = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(item['periodo'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  Text('${item['cantidad'] ?? 0} ventas', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text('S/${_formatNumber(item['total'])}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  Widget _buildAlertas(List<dynamic> alertas) {
    return GradientContainer(
      borderColor: Colors.amber.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            AppSubtitle('Alertas (${alertas.length})', fontSize: 13),
          ]),
          const SizedBox(height: 12),
          ...alertas.map((a) {
            final item = a as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.circle, size: 6, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(item['mensaje'] ?? '', style: const TextStyle(fontSize: 11))),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final n = value is double ? value : (value is int ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0);
    return n.toStringAsFixed(2);
  }
}
