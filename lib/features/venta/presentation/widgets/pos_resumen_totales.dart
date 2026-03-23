import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/cuota_calculator.dart';

import '../../domain/entities/venta_detalle_input.dart';
import 'resumen_venta_widget.dart';

/// Card de resumen de totales para VentaPOS
/// Muestra subtotal, impuestos, total, interés, pagado, crédito y cambio
class PosResumenTotales extends StatelessWidget {
  final List<VentaDetalleInput> items;
  final String moneda;
  final String nombreImpuesto;
  final double porcentajeImpuesto;
  final double totalVenta;
  final double totalPagado;
  final double montoCredito;
  final int numeroCuotas;
  final bool esCredito;
  final String condicionPago;
  final bool interesHabilitado;
  final double porcentajeInteres;

  const PosResumenTotales({
    super.key,
    required this.items,
    required this.moneda,
    required this.nombreImpuesto,
    required this.porcentajeImpuesto,
    required this.totalVenta,
    required this.totalPagado,
    required this.montoCredito,
    required this.numeroCuotas,
    required this.esCredito,
    required this.condicionPago,
    this.interesHabilitado = false,
    this.porcentajeInteres = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cambio = condicionPago == 'CONTADO' && totalPagado > totalVenta
        ? totalPagado - totalVenta
        : 0.0;

    final tieneInteres = esCredito && interesHabilitado && porcentajeInteres > 0 && montoCredito > 0;
    final montoInteres = tieneInteres
        ? CuotaCalculator.calcularInteres(montoCredito, porcentajeInteres)
        : 0.0;
    final totalConInteres = tieneInteres
        ? CuotaCalculator.calcularTotalConInteres(montoCredito, porcentajeInteres)
        : montoCredito;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResumenVentaWidget(
          items: items,
          moneda: moneda,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Total de la venta (valor del bien)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Venta',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('S/ ${totalVenta.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.blue1)),
                    ],
                  ),

                  // Pagado al contado (CONTADO y MIXTO)
                  if (totalPagado > 0) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pagado al contado',
                            style: TextStyle(fontSize: 11, color: Colors.green[700])),
                        Text('S/ ${totalPagado.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green[700])),
                      ],
                    ),
                  ],

                  // Saldo a crédito
                  if (esCredito && montoCredito > 0) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo a credito',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                        Text('S/ ${montoCredito.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                      ],
                    ),

                    // Interés
                    if (tieneInteres) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Interes (${porcentajeInteres.toStringAsFixed(1)}%)',
                              style: TextStyle(fontSize: 11, color: Colors.green[700])),
                          Text('+ S/ ${montoInteres.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green[700])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a pagar en $numeroCuotas cuota${numeroCuotas > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange[800]),
                            ),
                            Text('S/ ${totalConInteres.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.orange[800])),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        '$numeroCuotas cuota${numeroCuotas > 1 ? 's' : ''} de S/ ${(montoCredito / numeroCuotas).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                      ),
                    ],
                  ],

                  // Cambio (solo contado)
                  if (cambio > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cambio', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        Text('S/ ${cambio.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
