import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/cotizacion_pos.dart';
import '../bloc/cola_pos/cola_pos_cubit.dart';
import '../bloc/cola_pos/cola_pos_state.dart';

class ColaPosPage extends StatelessWidget {
  const ColaPosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ColaPosCubit>()..loadCola(),
      child: const _ColaPosView(),
    );
  }
}

class _ColaPosView extends StatelessWidget {
  const _ColaPosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Cola POS',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: BlocBuilder<ColaPosCubit, ColaPosState>(
          builder: (context, state) {
            if (state is ColaPosLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ColaPosError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<ColaPosCubit>().refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is ColaPosLoaded) {
              if (state.cotizaciones.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No hay cotizaciones en cola',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text('Las cotizaciones aprobadas apareceran aqui',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<ColaPosCubit>().refresh(),
                child: Column(
                  children: [
                    // Header con contador
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.blue1, AppColors.blue1.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cotizaciones en cola',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${state.cotizaciones.length} pendientes de cobro',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.cotizaciones.length}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blue1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.cotizaciones.length,
                        itemBuilder: (context, index) {
                          return _CotizacionPOSCard(
                            cotizacion: state.cotizaciones[index],
                            posicion: index + 1,
                          );
                        },
                      ),
                    ),
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

class _CotizacionPOSCard extends StatefulWidget {
  final CotizacionPOS cotizacion;
  final int posicion;

  const _CotizacionPOSCard({required this.cotizacion, required this.posicion});

  @override
  State<_CotizacionPOSCard> createState() => _CotizacionPOSCardState();
}

class _CotizacionPOSCardState extends State<_CotizacionPOSCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    final esUrgente = c.minutosEspera > 15;

    return GradientContainer(
      gradient: esUrgente ? AppGradients.orangeWhiteBlue() : AppGradients.blueWhiteBlue(),
      borderColor: esUrgente ? Colors.orange.shade300 : AppColors.blueborder,
      shadowStyle: ShadowStyle.colorful,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Posición en cola
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: esUrgente ? Colors.orange : AppColors.blue1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${widget.posicion}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: esUrgente
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.tiempoEsperaTexto,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: esUrgente ? Colors.orange[700] : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(c.nombreCliente, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('S/ ${c.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('${c.totalItems} items', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vendedor + sede
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(c.vendedor, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              if (c.sede != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.store, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(c.sede!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ],
          ),

          // Expandir detalles
          if (c.detalles.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Ocultar productos' : 'Ver productos (${c.totalItems})',
                    style: TextStyle(fontSize: 11, color: AppColors.blue1, fontWeight: FontWeight.w600),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppColors.blue1,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 6),
              ...c.detalles.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                          child: Center(child: Text('${d.cantidad}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d.producto ?? 'Producto', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text('S/ ${d.subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  )),
            ],
          ],

          // Botón convertir en venta
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push('/empresa/cola-pos/cobrar/${c.id}');
                if (result == true && context.mounted) {
                  context.read<ColaPosCubit>().refresh();
                }
              },
              icon: const Icon(Icons.point_of_sale, size: 16),
              label: const Text('Cobrar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: esUrgente ? Colors.orange : AppColors.blue1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
