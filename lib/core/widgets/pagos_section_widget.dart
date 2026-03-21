import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../theme/app_colors.dart';
import '../theme/gradient_container.dart';
import 'currency/currency_textfield.dart';

/// Helpers para labels/iconos de métodos de pago
String metodoLabel(String metodo) {
  switch (metodo) {
    case 'EFECTIVO': return 'Efectivo';
    case 'TARJETA': return 'Tarjeta';
    case 'YAPE': return 'Yape';
    case 'PLIN': return 'Plin';
    case 'TRANSFERENCIA': return 'Transferencia';
    default: return metodo;
  }
}

String metodoIcon(String metodo) {
  switch (metodo) {
    case 'EFECTIVO': return '💵';
    case 'TARJETA': return '💳';
    case 'YAPE': return '📱';
    case 'PLIN': return '📱';
    case 'TRANSFERENCIA': return '🏦';
    default: return '💰';
  }
}

/// Widget reutilizable para la sección completa de pagos múltiples.
///
/// Incluye: lista de pagos registrados + formulario para agregar pago
/// con soporte para múltiples métodos, moneda USD, y referencia.
class PagosSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> pagos;
  final String metodoActual;
  final ValueChanged<String> onMetodoChanged;
  final String monedaActual;
  final ValueChanged<String> onMonedaChanged;
  final double? tipoCambioVenta;
  final double saldoPendiente;
  final double totalPagado;
  final TextEditingController montoController;
  final TextEditingController referenciaController;
  final VoidCallback onAgregarPago;
  final void Function(int index) onRemoverPago;

  const PagosSectionWidget({
    super.key,
    required this.pagos,
    required this.metodoActual,
    required this.onMetodoChanged,
    required this.monedaActual,
    required this.onMonedaChanged,
    this.tipoCambioVenta,
    required this.saldoPendiente,
    required this.totalPagado,
    required this.montoController,
    required this.referenciaController,
    required this.onAgregarPago,
    required this.onRemoverPago,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pagos registrados
        if (pagos.isNotEmpty) ...[
          GradientContainer(
            borderColor: Colors.green.shade300,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text('Pagos registrados (${pagos.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pagos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(metodoIcon(p['metodo']), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(metodoLabel(p['metodo']),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                if ((p['referencia'] as String).isNotEmpty)
                                  Text('Ref: ${p['referencia']}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('S/ ${(p['monto'] as double).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green[700])),
                              if (p['monedaOriginal'] == 'USD')
                                Text('\$${(p['montoOriginal'] as double).toStringAsFixed(2)} USD (TC ${(p['tipoCambio'] as double).toStringAsFixed(3)})',
                                    style: TextStyle(fontSize: 9, color: Colors.blue[600])),
                            ],
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemoverPago(i),
                            child: Icon(Icons.close, size: 16, color: Colors.red[300]),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total pagado', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('S/ ${totalPagado.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green[700])),
                    ],
                  ),
                  if (saldoPendiente > 0.01)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo pendiente', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                        Text('S/ ${saldoPendiente.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange[700])),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Agregar pago
        GradientContainer(
          borderColor: saldoPendiente <= 0.01 && pagos.isNotEmpty
              ? Colors.green.shade300
              : AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_card, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    // const Text('Agregar pago', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    AppSubtitle('Agregar pago')
                  ],
                ),
                const SizedBox(height: 10),
                // Método de pago chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metodoPagoChip('EFECTIVO', '💵', 'Efectivo'),
                    _metodoPagoChip('TARJETA', '💳', 'Tarjeta'),
                    _metodoPagoChip('YAPE', '📱', 'Yape'),
                    _metodoPagoChip('PLIN', '📱', 'Plin'),
                    _metodoPagoChip('TRANSFERENCIA', '🏦', 'Transfer.'),
                  ],
                ),
                // Moneda
                if (tipoCambioVenta != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Moneda: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 6),
                      _monedaChip('PEN', 'S/', 'Soles'),
                      const SizedBox(width: 6),
                      _monedaChip('USD', '\$', 'Dolares'),
                      const Spacer(),
                      if (monedaActual == 'USD')
                        Text('TC: ${tipoCambioVenta!.toStringAsFixed(3)}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                // Monto + Referencia + Botón agregar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CurrencyTextField(
                        controller: montoController,
                        borderColor: Colors.green[700]!,
                        currencySymbol: monedaActual == 'USD' ? '\$' : 'S/',
                        label: saldoPendiente > 0.01
                            ? 'Pend: ${monedaActual == 'USD' && tipoCambioVenta != null ? '\$${(saldoPendiente / tipoCambioVenta!).toStringAsFixed(2)}' : 'S/${saldoPendiente.toStringAsFixed(2)}'}'
                            : 'Monto',
                      ),
                    ),
                    if (metodoActual != 'EFECTIVO') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CustomText(
                          controller: referenciaController,
                          label: 'Referencia',
                          hintText: 'N° operacion',
                          borderColor: Colors.green[700]!,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: onAgregarPago,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metodoPagoChip(String value, String icon, String label) {
    final selected = metodoActual == value;
    return GestureDetector(
      onTap: () => onMetodoChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _monedaChip(String value, String symbol, String label) {
    final selected = monedaActual == value;
    return GestureDetector(
      onTap: () => onMonedaChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Colors.blue[700]! : Colors.grey[300]!, width: 0.6),
        ),
        child: Text('$symbol $label',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}
