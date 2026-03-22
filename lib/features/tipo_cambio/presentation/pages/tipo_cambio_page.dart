import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../bloc/tipo_cambio_cubit.dart';
import '../bloc/tipo_cambio_state.dart';

class TipoCambioPage extends StatelessWidget {
  const TipoCambioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<TipoCambioCubit>()..loadAll(),
      child: const _TipoCambioView(),
    );
  }
}

class _TipoCambioView extends StatelessWidget {
  const _TipoCambioView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Tipo de Cambio',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<TipoCambioCubit, TipoCambioState>(
          builder: (context, state) {
            if (state is TipoCambioLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TipoCambioError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<TipoCambioCubit>().reload(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            if (state is TipoCambioLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<TipoCambioCubit>().reload(),
                color: AppColors.blue1,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (state.tipoCambioHoy != null)
                      _TipoCambioHoyCard(tipoCambio: state.tipoCambioHoy!),
                    const SizedBox(height: 12),
                    _RegistrarManualButton(
                      onRegistrado: () => context.read<TipoCambioCubit>().reload(),
                    ),
                    const SizedBox(height: 16),
                    const AppSubtitle('Historial (últimos 30 días)', fontSize: 14, color: AppColors.blue1),
                    const SizedBox(height: 8),
                    if (state.historial.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.currency_exchange, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Sin historial disponible', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.historial.map((tc) => _HistorialCard(tipoCambio: tc)),
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
}

class _TipoCambioHoyCard extends StatelessWidget {
  final TipoCambio tipoCambio;
  const _TipoCambioHoyCard({required this.tipoCambio});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange, color: AppColors.blue1, size: 22),
                const SizedBox(width: 8),
                const AppSubtitle('Tipo de Cambio Hoy', fontSize: 15, color: AppColors.blue1),
                const Spacer(),
                if (tipoCambio.fuente != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tipoCambio.fuente!,
                      style: const TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ValorCard(
                    label: 'Compra',
                    valor: tipoCambio.compra,
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValorCard(
                    label: 'Venta',
                    valor: tipoCambio.venta,
                    color: Colors.orange,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatDate(tipoCambio.fecha),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValorCard extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  final IconData icon;

  const _ValorCard({
    required this.label,
    required this.valor,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor.toStringAsFixed(4),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _RegistrarManualButton extends StatelessWidget {
  final VoidCallback onRegistrado;
  const _RegistrarManualButton({required this.onRegistrado});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showRegistrarDialog(context),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Registrar tipo de cambio manual'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue1,
          side: const BorderSide(color: AppColors.blue1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showRegistrarDialog(BuildContext context) {
    final compraController = TextEditingController();
    final ventaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar Tipo de Cambio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: compraController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Compra',
                  hintText: 'Ej: 3.7200',
                  prefixIcon: Icon(Icons.arrow_downward, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el valor de compra';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ventaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Venta',
                  hintText: 'Ej: 3.7800',
                  prefixIcon: Icon(Icons.arrow_upward, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el valor de venta';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final compra = double.parse(compraController.text);
              final venta = double.parse(ventaController.text);
              final fecha = DateTime.now().toIso8601String().split('T').first;

              Navigator.of(dialogContext).pop();

              final cubit = context.read<TipoCambioCubit>();
              final success = await cubit.registrarManual(
                compra: compra,
                venta: venta,
                fecha: fecha,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Tipo de cambio registrado correctamente'
                        : 'Error al registrar tipo de cambio'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1),
            child: const Text('Registrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final TipoCambio tipoCambio;
  const _HistorialCard({required this.tipoCambio});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Fecha
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.formatDate(tipoCambio.fecha),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (tipoCambio.fuente != null)
                  Text(
                    tipoCambio.fuente!,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const Spacer(),
            // Compra
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Compra', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  tipoCambio.compra.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Venta
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Venta', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  tipoCambio.venta.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
