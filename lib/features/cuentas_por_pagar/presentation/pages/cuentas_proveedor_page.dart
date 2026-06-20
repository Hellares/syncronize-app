import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../bloc/cuentas_pagar_state.dart';
import '../widgets/cuenta_card.dart';

/// Todas las compras a crédito (con saldo) de UN proveedor + el total adeudado.
/// Es la página de CxP filtrada a un proveedor.
class CuentasProveedorPage extends StatelessWidget {
  final String proveedorId;
  final String nombreProveedor;

  const CuentasProveedorPage({
    super.key,
    required this.proveedorId,
    required this.nombreProveedor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CuentasPagarCubit>()..loadCuentas(proveedorId: proveedorId),
      child: _CuentasProveedorView(nombreProveedor: nombreProveedor),
    );
  }
}

class _CuentasProveedorView extends StatelessWidget {
  final String nombreProveedor;
  const _CuentasProveedorView({required this.nombreProveedor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: nombreProveedor,
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
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
              final pendientes = state.cuentas.where((c) => c.estado != 'PAGADA').toList();
              final totalDeuda = pendientes.fold<double>(0, (s, c) => s + c.saldoPendiente);
              final vencidas = pendientes.where((c) => c.estado == 'VENCIDA').toList();
              final totalVencido = vencidas.fold<double>(0, (s, c) => s + c.saldoPendiente);

              return RefreshIndicator(
                onRefresh: () => context.read<CuentasPagarCubit>().loadCuentas(),
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildHeader(totalDeuda, totalVencido, pendientes.length, vencidas.length),
                    const SizedBox(height: 12),
                    if (state.cuentas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
                              const SizedBox(height: 12),
                              Text('Sin deudas con este proveedor', style: TextStyle(color: Colors.grey.shade500)),
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
        ),
      ),
    );
  }

  Widget _buildHeader(double totalDeuda, double totalVencido, int compras, int vencidas) {
    return GradientContainer(
      borderColor: totalVencido > 0 ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSubtitle('Total que debes', fontSize: 12, color: AppColors.blueGrey),
            const SizedBox(height: 4),
            AppTitle('S/ ${totalDeuda.toStringAsFixed(2)}', fontSize: 24, color: Colors.red),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(Icons.receipt_long, '$compras compra${compras != 1 ? 's' : ''}', AppColors.blue1),
                const SizedBox(width: 8),
                if (vencidas > 0)
                  _chip(Icons.warning_amber_rounded, 'Vencido S/ ${totalVencido.toStringAsFixed(2)}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(texto, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
