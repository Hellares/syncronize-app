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

/// Umbrales Ley 28194 (bancarización).
const double umbralBancarizacionPen = 2000;
const double umbralBancarizacionUsd = 500;

/// Lista fija de bancos para el dropdown (Fase 1).
/// Si crece el listado, promover a endpoint /catalogos/bancos.
const List<String> bancosPeru = [
  'BCP', 'BBVA', 'Interbank', 'Scotiabank', 'Banco de la Nación',
  'BanBif', 'Pichincha', 'Mi Banco', 'Caja Arequipa', 'Caja Huancayo',
  'Otro',
];

/// ¿La venta supera el umbral de Ley 28194 (independiente del método)?
/// Cuando es true, el banner se muestra y SUNAT exige bancarizar.
bool aplicaBancarizacion({required double totalVentaPen}) {
  return totalVentaPen >= umbralBancarizacionPen;
}

/// ¿Este método de pago necesita referencia/N° de operación obligatoria
/// cuando la venta dispara bancarización?
bool requiereReferenciaPago({required String metodo, required double totalVentaPen}) {
  return aplicaBancarizacion(totalVentaPen: totalVentaPen) &&
      metodo != 'EFECTIVO' &&
      metodo != 'CREDITO';
}

/// ¿Este método requiere seleccionar entidad financiera (banco)?
/// Solo aplica a TARJETA / TRANSFERENCIA.
bool requiereBancoPago(String metodo) {
  return metodo == 'TARJETA' || metodo == 'TRANSFERENCIA';
}

/// Helper compuesto: ¿este pago concreto necesita banco obligatorio?
bool requiereBancoPagoObligatorio({required String metodo, required double totalVentaPen}) {
  return aplicaBancarizacion(totalVentaPen: totalVentaPen) && requiereBancoPago(metodo);
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
  final double? montoCredito;
  final int? numeroCuotas;
  /// Total de la venta en soles. Si supera umbralBancarizacionPen se pide banco/referencia.
  final double totalVentaPen;
  /// Banco seleccionado cuando aplica bancarización (dropdown).
  final String? bancoActual;
  final ValueChanged<String?>? onBancoChanged;

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
    this.montoCredito,
    this.numeroCuotas,
    this.totalVentaPen = 0,
    this.bancoActual,
    this.onBancoChanged,
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
                                if (((p['banco'] as String?)?.isNotEmpty ?? false) ||
                                    (p['referencia'] as String).isNotEmpty)
                                  Text(
                                    [
                                      if ((p['banco'] as String?)?.isNotEmpty ?? false) p['banco'],
                                      if ((p['referencia'] as String).isNotEmpty) 'Ref: ${p['referencia']}',
                                    ].join(' · '),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                  ),
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
                  if (montoCredito != null && montoCredito! > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'A credito${numeroCuotas != null && numeroCuotas! > 0 ? ' ($numeroCuotas cuota${numeroCuotas! > 1 ? 's' : ''})' : ''}',
                          style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                        ),
                        Text('S/ ${montoCredito!.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[600])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Agregar pago — ocultar si ya se cubrió el monto
        if (saldoPendiente <= 0.01 && pagos.isNotEmpty)
          GradientContainer(
            borderColor: Colors.green.shade300,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pago completo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green[700]),
                    ),
                  ),
                  Text('S/ ${totalPagado.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green[700])),
                ],
              ),
            ),
          )
        else
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_card, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      AppSubtitle('Agregar pago'),
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
                  // Banner bancarización: visible siempre que la venta supera el umbral.
                  // Si el método actual es EFECTIVO, el cajero verá una nota distinta
                  // arriba para advertir que el efectivo viola Ley 28194.
                  if (aplicaBancarizacion(totalVentaPen: totalVentaPen)) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: metodoActual == 'EFECTIVO' ? Colors.red[50] : Colors.amber[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (metodoActual == 'EFECTIVO' ? Colors.red[700] : Colors.amber[700])!,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            metodoActual == 'EFECTIVO' ? Icons.warning_amber_rounded : Icons.info_outline,
                            size: 14,
                            color: metodoActual == 'EFECTIVO' ? Colors.red[800] : Colors.amber[800],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              metodoActual == 'EFECTIVO'
                                  ? 'Ley 28194: el efectivo en ventas ≥ S/${umbralBancarizacionPen.toStringAsFixed(0)} requiere confirmación. El cliente perderá derecho a deducir IGV.'
                                  : 'Bancarización (Ley 28194): venta ≥ S/${umbralBancarizacionPen.toStringAsFixed(0)} requiere medios bancarios.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: metodoActual == 'EFECTIVO' ? Colors.red[900] : Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Dropdown banco — visible siempre que método sea TARJETA/TRANSFERENCIA.
                  // Asterisco solo si la bancarización lo vuelve obligatorio.
                  if (requiereBancoPago(metodoActual)) ...[
                    DropdownButtonFormField<String>(
                      initialValue: bancoActual,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: requiereBancoPagoObligatorio(metodo: metodoActual, totalVentaPen: totalVentaPen)
                            ? 'Banco *'
                            : 'Banco',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green[700]!),
                        ),
                      ),
                      items: bancosPeru.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: onBancoChanged,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Monto + Referencia + Botón agregar
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CurrencyTextField(
                          controller: montoController,
                          enableRealTimeValidation: false,
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
                            label: requiereReferenciaPago(metodo: metodoActual, totalVentaPen: totalVentaPen)
                                ? 'Referencia *'
                                : 'Referencia',
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
