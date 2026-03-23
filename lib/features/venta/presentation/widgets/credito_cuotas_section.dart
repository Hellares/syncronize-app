import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/cuota_calculator.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/cuotas_dial_selector.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

/// Sección de crédito/cuotas/interés para VentaPOS
/// Muestra las opciones de crédito según la condición de pago (CREDITO o MIXTO)
class CreditoCuotasSection extends StatelessWidget {
  final String condicionPago; // CONTADO, CREDITO, MIXTO
  final int numeroCuotas;
  final ValueChanged<int> onCuotasChanged;
  final TextEditingController montoCreditoController;
  final double montoCredito;
  final double montoPagarAhora;
  final bool interesHabilitado;
  final bool interesEsEditable;
  final double porcentajeInteres;
  final TextEditingController porcentajeInteresController;
  final ValueChanged<String> onInteresChanged;
  final bool moraHabilitada;
  final double porcentajeMoraDiario;
  final double moraMaximaPorcentaje;
  final int diasGraciaMora;
  final bool hasItems;
  final double totalVenta;

  const CreditoCuotasSection({
    super.key,
    required this.condicionPago,
    required this.numeroCuotas,
    required this.onCuotasChanged,
    required this.montoCreditoController,
    required this.montoCredito,
    required this.montoPagarAhora,
    required this.interesHabilitado,
    required this.interesEsEditable,
    required this.porcentajeInteres,
    required this.porcentajeInteresController,
    required this.onInteresChanged,
    required this.moraHabilitada,
    required this.porcentajeMoraDiario,
    required this.moraMaximaPorcentaje,
    required this.diasGraciaMora,
    required this.hasItems,
    this.totalVenta = 0,
  });

  bool get _esCredito => condicionPago == 'CREDITO' || condicionPago == 'MIXTO';

  double get _montoInteresCalculado =>
      CuotaCalculator.calcularInteres(montoCredito, porcentajeInteres);

  double get _montoCreditoConInteres =>
      CuotaCalculator.calcularTotalConInteres(montoCredito, porcentajeInteres);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (condicionPago == 'MIXTO') _buildMixtoSection(),
        if (condicionPago == 'CREDITO') _buildCreditoSection(),
      ],
    );
  }

  Widget _buildMixtoSection() {
    return Column(
      children: [
        GradientContainer(
          borderColor: Colors.orange.shade300,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_score, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    AppSubtitle('Parte a Credito', color: Colors.orange[700]!),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CurrencyTextField(
                        controller: montoCreditoController,
                        enableRealTimeValidation: false,
                        borderColor: Colors.orange[700]!,
                        label: 'Monto a credito',
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(width: 10),
                    CuotasDialSelector(
                      label: 'Cuotas',
                      value: numeroCuotas,
                      activeColor: Colors.orange[700],
                      onChanged: onCuotasChanged,
                    ),
                  ],
                ),
                // Warning si monto crédito >= total
                if (totalVenta > 0 && montoCredito >= totalVenta) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El monto a credito debe ser menor al total. Usa "Credito" para credito total.',
                            style: TextStyle(fontSize: 11, color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (interesHabilitado && _esCredito) ...[
                  const SizedBox(height: 10),
                  _buildInteresCredito(),
                ],
                if (montoCredito > 0 && montoCredito < totalVenta && numeroCuotas > 0) ...[
                  const SizedBox(height: 10),
                  _buildCuotasPreview(),
                ],
                if (montoPagarAhora > 0) ...[
                  const SizedBox(height: 10),
                  GradientContainer(
                    borderColor: Colors.green.shade300,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pagar ahora:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700])),
                          Text('S/ ${montoPagarAhora.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCreditoSection() {
    return Column(
      children: [
        GradientContainer(
          borderColor: Colors.orange.shade300,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_score, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text('Credito Total',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                  ],
                ),
                const SizedBox(height: 10),
                CuotasDialSelector(
                  label: 'Cuotas',
                  value: numeroCuotas,
                  activeColor: Colors.orange[700],
                  onChanged: onCuotasChanged,
                ),
                if (interesHabilitado && _esCredito) ...[
                  const SizedBox(height: 10),
                  _buildInteresCredito(),
                ],
                if (numeroCuotas > 0 && hasItems) ...[
                  const SizedBox(height: 10),
                  _buildCuotasPreview(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInteresCredito() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent, size: 14, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text('Interés por crédito',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: interesEsEditable
                    ? CustomText(
                        controller: porcentajeInteresController,
                        borderColor: Colors.green.shade400,
                        label: 'Interés (%)',
                        hintText: 'Ej: 5',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: onInteresChanged,
                      )
                    : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Interés (%)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('${porcentajeInteres.toStringAsFixed(2)}%'),
                      ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Interés: S/ ${_montoInteresCalculado.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
                  Text('Total: S/ ${_montoCreditoConInteres.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCuotasPreview() {
    final interes = (interesHabilitado && porcentajeInteres > 0) ? porcentajeInteres : 0.0;
    final cuotas = CuotaCalculator.calcular(
      montoCredito: montoCredito,
      numeroCuotas: numeroCuotas,
      porcentajeInteres: interes,
    );

    if (cuotas.isEmpty) return const SizedBox.shrink();

    final totalConInteres = CuotaCalculator.calcularTotalConInteres(montoCredito, interes);

    return GradientContainer(
      borderColor: Colors.blue.shade200,
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          initiallyExpanded: false,
          dense: true,
          leading: Icon(Icons.calendar_month, size: 16, color: Colors.blue[700]),
          title: Text(
            '$numeroCuotas cuota${numeroCuotas > 1 ? 's' : ''} de S/ ${cuotas.first.monto.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('S/ ${totalConInteres.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue[700])),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 18, color: Colors.blue[400]),
            ],
          ),
          children: [
            const Divider(height: 8),
            const SizedBox(height: 4),
            ...cuotas.map((cuota) {
              final fecha = cuota.fechaVencimiento;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${cuota.numero}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue[700])),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('S/ ${cuota.monto.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
            if (moraHabilitada && cuotas.isNotEmpty) ...[
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Condiciones de mora por atraso',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange[800])),
                          const SizedBox(height: 4),
                          Text(
                            '• Interes: $porcentajeMoraDiario% diario sobre el monto de la cuota\n'
                            '${diasGraciaMora > 0 ? '• Gracia: $diasGraciaMora dia${diasGraciaMora > 1 ? 's' : ''} despues del vencimiento\n' : ''}'
                            '• Tope maximo: ${moraMaximaPorcentaje.toStringAsFixed(0)}% del monto de la cuota\n'
                            '• Ej: cuota de S/ ${cuotas.first.monto.toStringAsFixed(2)} → mora diaria S/ ${(cuotas.first.monto * porcentajeMoraDiario / 100).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 10, color: Colors.orange[700], height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
