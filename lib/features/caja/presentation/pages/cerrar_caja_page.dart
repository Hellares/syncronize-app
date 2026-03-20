import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../bloc/caja_activa_cubit.dart';
import '../bloc/caja_activa_state.dart';
import '../bloc/caja_movimientos_cubit.dart';
import '../bloc/caja_movimientos_state.dart';

class CerrarCajaPage extends StatefulWidget {
  final String cajaId;

  const CerrarCajaPage({super.key, required this.cajaId});

  @override
  State<CerrarCajaPage> createState() => _CerrarCajaPageState();
}

class _CerrarCajaPageState extends State<CerrarCajaPage> {
  final _observacionesController = TextEditingController();
  final Map<MetodoPago, TextEditingController> _conteoControllers = {};
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each payment method
    for (final metodo in MetodoPago.values) {
      _conteoControllers[metodo] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    for (final controller in _conteoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return BlocListener<CajaActivaCubit, CajaActivaState>(
      listener: (context, state) {
        if (state is CajaActivaSinCaja) {
          SnackBarHelper.showSuccess(context, 'Caja cerrada exitosamente');
          Navigator.of(context).pop();
        }
        if (state is CajaActivaError) {
          setState(() => _isClosing = false);
          SnackBarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Cerrar Caja',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: BlocBuilder<CajaMovimientosCubit, CajaMovimientosState>(
            builder: (context, movState) {
              if (movState is CajaMovimientosLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (movState is CajaMovimientosLoaded &&
                  movState.resumen != null) {
                return _buildCierreForm(
                  context,
                  movState.resumen!,
                  currencyFormat,
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No se pudo cargar el resumen',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () {
                        context
                            .read<CajaMovimientosCubit>()
                            .loadMovimientos(widget.cajaId);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCierreForm(
    BuildContext context,
    ResumenCaja resumen,
    NumberFormat currencyFormat,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          GradientContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle(
                  'Resumen del Sistema',
                  fontSize: 16,
                  color: AppColors.blue3,
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total Ingresos',
                  currencyFormat.format(resumen.totalIngresos),
                  AppColors.green,
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Total Egresos',
                  currencyFormat.format(resumen.totalEgresos),
                  AppColors.red,
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  'Saldo Total',
                  currencyFormat.format(resumen.saldo),
                  AppColors.blue3,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conteo por metodo de pago
          const AppSubtitle(
            'Conteo Fisico por Metodo de Pago',
            fontSize: 16,
            color: AppColors.blue3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa el monto fisico contado para cada metodo de pago',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          ...MetodoPago.values.map((metodo) {
            final detalle = resumen.detalles
                .where((d) => d.metodoPago == metodo)
                .toList();
            final esperado =
                detalle.isNotEmpty ? detalle.first.saldo : 0.0;

            // Only show payment methods that have expected amounts or are EFECTIVO
            if (esperado == 0 && metodo != MetodoPago.efectivo) {
              return const SizedBox.shrink();
            }

            return _buildConteoCard(
              metodo,
              esperado,
              currencyFormat,
            );
          }),

          const SizedBox(height: 16),

          // Observaciones
          TextFormField(
            controller: _observacionesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observaciones (opcional)',
              hintText: 'Notas sobre el cierre de caja...',
              prefixIcon: const Icon(Icons.note_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cerrar button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cerrar Caja',
              backgroundColor: AppColors.red,
              height: 48,
              isLoading: _isClosing,
              onPressed: _isClosing ? null : () => _confirmarCierre(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConteoCard(
    MetodoPago metodo,
    double esperado,
    NumberFormat currencyFormat,
  ) {
    final controller = _conteoControllers[metodo]!;
    final conteoValue =
        double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    final diferencia = conteoValue - esperado;
    final hasDiferencia = controller.text.isNotEmpty && diferencia != 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metodo.icon, size: 20, color: AppColors.blue3),
                const SizedBox(width: 8),
                AppSubtitle(
                  metodo.label,
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esperado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(esperado),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue3,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Conteo Fisico',
                      prefixText: 'S/ ',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (hasDiferencia) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diferencia > 0
                      ? AppColors.green.withValues(alpha: 0.1)
                      : AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diferencia > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: diferencia > 0 ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Diferencia: ${currencyFormat.format(diferencia.abs())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            diferencia > 0 ? AppColors.green : AppColors.red,
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

  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _confirmarCierre(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Confirmar Cierre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blue3,
          ),
        ),
        content: const Text(
          'Esta accion no se puede deshacer. Se cerrara la caja y se registraran los conteos fisicos.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cerrarCaja(context);
            },
            child: const Text(
              'Cerrar Caja',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _cerrarCaja(BuildContext context) {
    setState(() => _isClosing = true);

    final conteos = <Map<String, dynamic>>[];
    for (final metodo in MetodoPago.values) {
      final text = _conteoControllers[metodo]!.text;
      if (text.isNotEmpty) {
        final conteoFisico =
            double.tryParse(text.replaceAll(',', '.')) ?? 0;
        conteos.add({
          'metodoPago': metodo.apiValue,
          'conteoFisico': conteoFisico,
        });
      }
    }

    context.read<CajaActivaCubit>().cerrarCaja(
          cajaId: widget.cajaId,
          conteos: conteos,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
        );
  }
}
