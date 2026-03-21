import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../bloc/cuentas_pagar_state.dart';

class CuentasPorPagarPage extends StatelessWidget {
  const CuentasPorPagarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CuentasPagarCubit>()..loadCuentas(),
      child: const _CuentasPagarView(),
    );
  }
}

class _CuentasPagarView extends StatefulWidget {
  const _CuentasPagarView();
  @override
  State<_CuentasPagarView> createState() => _CuentasPagarViewState();
}

class _CuentasPagarViewState extends State<_CuentasPagarView> {
  String? _filtroEstado;

  Future<void> _exportExcel(BuildContext context) async {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    await locator<ExportService>().exportAndShare(
      context: context,
      endpoint: '/reportes-financieros/export/cuentas-pagar',
      queryParams: {
        'fechaDesde': inicio.toIso8601String().split('T').first,
        'fechaHasta': now.toIso8601String().split('T').first,
      },
      fileName: 'cuentas_por_pagar_${now.month}_${now.year}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Cuentas por Pagar',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Exportar Excel',
            onPressed: () => _exportExcel(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocBuilder<CuentasPagarCubit, CuentasPagarState>(
          builder: (context, state) {
            if (state is CuentasPagarLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CuentasPagarError) {
              return Center(child: Text(state.message));
            }
            if (state is CuentasPagarLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<CuentasPagarCubit>().loadCuentas(estado: _filtroEstado),
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (state.resumen != null) _buildResumen(state.resumen!),
                    const SizedBox(height: 12),
                    _buildFiltros(context),
                    const SizedBox(height: 8),
                    if (state.cuentas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
                              const SizedBox(height: 12),
                              Text('No hay cuentas pendientes', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.cuentas.map((c) => _CuentaCard(cuenta: c)),
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

  Widget _buildResumen(ResumenCuentasPagar resumen) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ResumenItem(
                    label: 'Pendiente',
                    monto: resumen.totalPendiente,
                    cantidad: resumen.cantidadPendientes,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResumenItem(
                    label: 'Vencido',
                    monto: resumen.totalVencido,
                    cantidad: resumen.cantidadVencidas,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppSubtitle('Total por pagar', fontSize: 13),
                AppSubtitle(
                  'S/ ${resumen.totalPorPagar.toStringAsFixed(2)}',
                  fontSize: 16,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    final filtros = [
      {'label': 'Todos', 'value': null},
      {'label': 'Pendientes', 'value': 'PENDIENTE'},
      {'label': 'Vencidas', 'value': 'VENCIDA'},
      {'label': 'Pagadas', 'value': 'PAGADA'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((f) {
          final isSelected = _filtroEstado == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.blue1)),
              selected: isSelected,
              selectedColor: AppColors.blue1,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? AppColors.blue1 : Colors.grey.shade300),
              onSelected: (_) {
                setState(() => _filtroEstado = f['value']);
                context.read<CuentasPagarCubit>().loadCuentas(estado: _filtroEstado);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final double monto;
  final int cantidad;
  final Color color;

  const _ResumenItem({required this.label, required this.monto, required this.cantidad, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('S/ ${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text('$cantidad cuenta${cantidad != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _CuentaCard extends StatelessWidget {
  final CuentaPorPagar cuenta;
  const _CuentaCard({required this.cuenta});

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    String estadoLabel;
    switch (cuenta.estado) {
      case 'VENCIDA': estadoColor = Colors.red; estadoLabel = 'Vencida'; break;
      case 'PAGADA': estadoColor = Colors.green; estadoLabel = 'Pagada'; break;
      default: estadoColor = Colors.orange; estadoLabel = 'Pendiente';
    }

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: cuenta.estado == 'VENCIDA' ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSubtitle(cuenta.codigo, fontSize: 13, color: AppColors.blue1),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(estadoLabel, style: TextStyle(fontSize: 10, color: estadoColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: AppSubtitle(cuenta.nombreProveedor, fontSize: 12)),
              ],
            ),
            if (cuenta.bancoPrincipal != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.account_balance, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${cuenta.bancoPrincipal!.nombreBanco} - ${cuenta.bancoPrincipal!.numeroCuenta}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Total: S/ ${cuenta.totalCompra.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const Spacer(),
                AppSubtitle('Saldo: S/ ${cuenta.saldoPendiente.toStringAsFixed(2)}', fontSize: 13, color: estadoColor),
              ],
            ),
            if (cuenta.fechaVencimiento != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event, size: 13, color: cuenta.estado == 'VENCIDA' ? Colors.red : Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Vence: ${DateFormatter.formatDate(cuenta.fechaVencimiento!)}${cuenta.diasVencimiento != null ? ' (${cuenta.diasVencimiento! > 0 ? 'en ${cuenta.diasVencimiento} días' : cuenta.diasVencimiento == 0 ? 'hoy' : '${cuenta.diasVencimiento!.abs()} días atrás'})' : ''}',
                    style: TextStyle(fontSize: 10, color: cuenta.estado == 'VENCIDA' ? Colors.red : Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
