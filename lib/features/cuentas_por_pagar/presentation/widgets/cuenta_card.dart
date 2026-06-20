import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../bloc/cuentas_pagar_cubit.dart';
import '../pages/cuenta_pagar_detalle_page.dart';
import 'pago_proveedor_sheet.dart';

/// Card de una cuenta por pagar (compra a crédito). Tap → detalle;
/// botón "Registrar pago" → sheet. Requiere un [CuentasPagarCubit] en el
/// árbol (lo lee de context) para registrar el pago y refrescar la lista.
class CuentaCard extends StatelessWidget {
  final CuentaPorPagar cuenta;
  const CuentaCard({super.key, required this.cuenta});

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    String estadoLabel;
    switch (cuenta.estado) {
      case 'VENCIDA':
        estadoColor = Colors.red;
        estadoLabel = 'Vencida';
        break;
      case 'PAGADA':
        estadoColor = Colors.green;
        estadoLabel = 'Pagada';
        break;
      default:
        estadoColor = Colors.orange;
        estadoLabel = 'Pendiente';
    }

    return GestureDetector(
      onTap: () => _abrirDetalle(context, cuenta),
      child: GradientContainer(
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
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
              // Registrar pago — solo si queda saldo.
              if (cuenta.estado != 'PAGADA' && cuenta.saldoPendiente > 0.001) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Registrar pago',
                    height: 36,
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    onPressed: () => _pagar(context, cuenta),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalle(BuildContext context, CuentaPorPagar cuenta) async {
    final cubit = context.read<CuentasPagarCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CuentaPagarDetallePage(compraId: cuenta.id, cubit: cubit),
      ),
    );
  }

  Future<void> _pagar(BuildContext context, CuentaPorPagar cuenta) async {
    final cubit = context.read<CuentasPagarCubit>();
    final ok = await PagoProveedorSheet.mostrar(context, cuenta: cuenta, cubit: cubit);
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado'), backgroundColor: Colors.green),
      );
    }
  }
}
