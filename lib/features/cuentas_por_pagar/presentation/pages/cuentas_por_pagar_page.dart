import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../../domain/usecases/get_deuda_por_proveedor_usecase.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../bloc/cuentas_pagar_state.dart';
import '../widgets/cuenta_card.dart';
import 'cuentas_proveedor_page.dart';

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
  String _vista = 'compra'; // 'compra' | 'proveedor'

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
        child: Column(
          children: [
            _buildVistaToggle(),
            Expanded(
              child: _vista == 'proveedor' ? _buildPorProveedor(context) : _buildPorCompra(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaToggle() {
    Widget seg(String value, IconData icon, String label) {
      final sel = _vista == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _vista = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? AppColors.blue1 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: sel ? Colors.white : AppColors.blue1),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.blue1, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: Row(
        children: [
          seg('compra', Icons.receipt_long, 'Por compra'),
          seg('proveedor', Icons.business, 'Por proveedor'),
        ],
      ),
    );
  }

  Widget _buildPorCompra() {
    return BlocBuilder<CuentasPagarCubit, CuentasPagarState>(
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
                  ...state.cuentas.map((c) => CuentaCard(cuenta: c)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPorProveedor(BuildContext context) {
    return FutureBuilder<Resource<List<DeudaProveedor>>>(
      future: locator<GetDeudaPorProveedorUseCase>().call(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final res = snapshot.data;
        if (res is Error<List<DeudaProveedor>>) {
          return Center(child: Text(res.message));
        }
        if (res is Success<List<DeudaProveedor>>) {
          final proveedores = res.data;
          if (proveedores.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    Text('Ningún proveedor con deuda', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: proveedores.map((p) => _ProveedorCard(deuda: p)).toList(),
          );
        }
        return const SizedBox.shrink();
      },
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
                    montoTexto: resumen.pendienteFormateado,
                    cantidad: resumen.cantidadPendientes,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResumenItem(
                    label: 'Vencido',
                    montoTexto: resumen.vencidoFormateado,
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
                  resumen.totalPorPagarFormateado,
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
  final String montoTexto;
  final int cantidad;
  final Color color;

  const _ResumenItem({required this.label, required this.montoTexto, required this.cantidad, required this.color});

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
          Text(montoTexto, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text('$cantidad cuenta${cantidad != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// Card de la vista "Por proveedor": nombre + deuda total. Tap → todas sus
/// compras a crédito.
class _ProveedorCard extends StatelessWidget {
  final DeudaProveedor deuda;
  const _ProveedorCard({required this.deuda});

  @override
  Widget build(BuildContext context) {
    final tieneVencido = deuda.totalVencido > 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CuentasProveedorPage(
            proveedorId: deuda.proveedorId,
            nombreProveedor: deuda.nombreProveedor,
          ),
        ),
      ),
      child: GradientContainer(
        margin: const EdgeInsets.only(bottom: 8),
        borderColor: tieneVencido ? Colors.red.shade300 : AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.business, size: 16, color: AppColors.blue1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(deuda.nombreProveedor, fontSize: 10, color: AppColors.blue1),
                    const SizedBox(height: 2),
                    Text(
                      '${deuda.cantidadCompras} compra${deuda.cantidadCompras != 1 ? 's' : ''}'
                      '${deuda.cantidadVencidas > 0 ? ' · ${deuda.cantidadVencidas} vencida${deuda.cantidadVencidas != 1 ? 's' : ''}' : ''}',
                      style: TextStyle(fontSize: 10, color: tieneVencido ? AppColors.red : Colors.grey.shade600),
                    ),
                    if (deuda.proximoVencimiento != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Próx. vence: ${DateFormatter.formatDate(deuda.proximoVencimiento!)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...deuda.deudaFormateada.split('  ·  ').map(
                        (linea) => Text(linea,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.red)),
                      ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
