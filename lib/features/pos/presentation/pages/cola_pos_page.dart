import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
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
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: 'Cotizaciones por cobrar',
        leftIcon: Icons.arrow_back_rounded,
        onLeftTap: () => context.pop(),
        actions: [
          // Contador reactivo al state. Reemplaza la card del header
          // que mostraba "N cotizaciones en cola".
          BlocBuilder<ColaPosCubit, ColaPosState>(
            builder: (context, state) {
              final count = state is ColaPosLoaded
                  ? state.cotizaciones.length
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
                      Text('Las cotizaciones pendientes y aprobadas apareceran aqui',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<ColaPosCubit>().refresh(),
                // Card de header eliminada: el título "Cotizaciones por
                // cobrar" y el contador viven ahora en el SmartAppBar.
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  itemCount: state.cotizaciones.length,
                  itemBuilder: (context, index) {
                    return _CotizacionPOSCard(
                      cotizacion: state.cotizaciones[index],
                      posicion: index + 1,
                    );
                  },
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Posición en cola
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: esUrgente ? Colors.orange : AppColors.blue1,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('${widget.posicion}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 6),
                        // Chip de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.esPendiente
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.esPendiente ? 'Pendiente' : 'Aprobada',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: c.esPendiente ? Colors.amber[800] : Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                    //Text(c.nombreCliente, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    AppSubtitle(c.nombreCliente,  color: AppColors.blue1, maxLines: 1, overflow: TextOverflow.ellipsis)
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('S/ ${c.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Text('${c.totalItems} items', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vendedor + sede + fecha/hora
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  c.vendedor,
                  style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (c.sede != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.store, size: 12, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    c.sede!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.schedule, size: 12, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatDateTime(c.creadoEn),
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
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
                  if (c.tieneReservaActiva) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.greenContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_added, size: 11, color: AppColors.greendark),
                          const SizedBox(width: 3),
                          Text(
                            'Reservado',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greendark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

            child: CustomButton(
              height: 32,
              onPressed: () async {
                final result = await context.push('/empresa/cola-pos/cobrar/${c.id}');
                if (result == true && context.mounted) {
                  context.read<ColaPosCubit>().refresh();
                }
              },
              text: c.esPendiente ? 'Aprobar y Cobrar' : 'Cobrar',
              icon: c.esPendiente ? Icon(Icons.flash_on, size: 18,) : Icon(Icons.point_of_sale, size: 18,),
              backgroundColor: esUrgente
                  ? Colors.orange
                  : c.esPendiente
                      ? Colors.amber[700]!
                      : AppColors.blue1,
              textColor: Colors.white,
            ),

          ),        
        ],
      ),
    );
  }
}
