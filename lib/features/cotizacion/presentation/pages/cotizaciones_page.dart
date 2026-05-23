import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/custom_filter_chip.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_list/cotizacion_list_cubit.dart';
import '../bloc/cotizacion_list/cotizacion_list_state.dart';
import '../widgets/cotizacion_estado_chip.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  EstadoCotizacion? _filtroEstado;
  final _searchController = TextEditingController();
  String? _currentEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadCotizaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCotizaciones() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      context.read<CotizacionListCubit>().loadCotizaciones(
            empresaId: _currentEmpresaId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            _currentEmpresaId = newEmpresaId;
            _loadCotizaciones();
          }
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Cotizaciones',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nueva Cotización',
              onPressed: () async {
                await context.push('/empresa/cotizaciones/nueva');
                if (context.mounted) {
                  context.read<CotizacionListCubit>().reload();
                }
              },
            ),
          ],
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Barra de busqueda
              Padding(
                padding: const EdgeInsets.all(12),
                child: CustomSearchField(
                  controller: _searchController,
                  borderColor: AppColors.blue1,
                  hintText: 'Buscar por codigo, cliente...',
                  onChanged: (query) {
                    context.read<CotizacionListCubit>().search(query);
                  },
                  onSubmitted: (query) {
                    context.read<CotizacionListCubit>().search(query);
                  },
                  onClear: () {
                    context.read<CotizacionListCubit>().search('');
                  },
                ),
              ),
          
              // Chips de filtro de estado
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    CustomFilterChip(
                      label: 'Todos',
                      selected: _filtroEstado == null,
                      onSelected: () => _filterByEstado(null),
                      showCheckmark: true,
                    ),
                    const SizedBox(width: 6),
                    ...EstadoCotizacion.values.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CustomFilterChip(
                            showCheckmark: true,
                            label: e.label,
                            selected: _filtroEstado == e,
                            onSelected: () => _filterByEstado(e),
                          ),
                        )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Contador de resultados
              BlocBuilder<CotizacionListCubit, CotizacionListState>(
                builder: (context, state) {
                  if (state is CotizacionListLoaded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppText(
                          '${state.cotizaciones.length} cotización${state.cotizaciones.length != 1 ? 'es' : ''}',
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 4),

              // Lista
              Expanded(
                child: BlocBuilder<CotizacionListCubit, CotizacionListState>(
                  builder: (context, state) {
                    if (state is CotizacionListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
          
                    if (state is CotizacionListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.message),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.read<CotizacionListCubit>().reload(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
          
                    if (state is CotizacionListLoaded) {
                      if (state.cotizaciones.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No hay cotizaciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
          
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<CotizacionListCubit>().reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: state.cotizaciones.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final cotizacion = state.cotizaciones[index];
                            return _CotizacionListTile(
                              cotizacion: cotizacion,
                              onTap: () async {
                                await context.push(
                                  '/empresa/cotizaciones/${cotizacion.id}',
                                );
                                if (context.mounted) {
                                  context
                                      .read<CotizacionListCubit>()
                                      .reload();
                                }
                              },
                            );
                          },
                        ),
                      );
                    }
          
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterByEstado(EstadoCotizacion? estado) {
    setState(() => _filtroEstado = estado);
    context.read<CotizacionListCubit>().filterByEstado(estado);
  }
}

class _CotizacionListTile extends StatelessWidget {
  final Cotizacion cotizacion;
  final VoidCallback onTap;

  const _CotizacionListTile({
    required this.cotizacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usar DateFormatter para formato consistente

    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(cotizacion.codigo),
                  const SizedBox(width: 8),
                  CotizacionEstadoChip(estado: cotizacion.estado),
                  if (cotizacion.tieneReservaActiva) ...[
                    const SizedBox(width: 6),
                    const _ReservaBadge(),
                  ],
                  Spacer(),
                  Text(
                    DateFormatter.formatDateTime(cotizacion.fechaEmision),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (cotizacion.nombre != null &&
                  cotizacion.nombre!.isNotEmpty) ...[
                const SizedBox(height: 2),
                AppSubtitle(cotizacion.nombre!, fontSize: 10,)
              ],
              const SizedBox(height: 2),
              Row(
                children: [
                  SizedBox(width: 70, child: AppText('Cliente:', size: 10,)),
                  Expanded(child: AppText(cotizacion.nombreCliente, fontWeight: FontWeight.w400, size: 10,)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  SizedBox(width: 70, child: AppText('Telefono:', size: 10,)),
                  Expanded(child: AppText(cotizacion.telefonoCliente ?? 'N/A', fontWeight: FontWeight.w400, size: 10)),
                ],
              ),
              if (cotizacion.sedeNombre != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppText('Sede:', size: 10,)),
                    Expanded(child: AppText(cotizacion.sedeNombre!, fontWeight: FontWeight.w400, size: 10)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (cotizacion.vendedorNombre != null)
                    Text(
                      'Vendedor:   ${cotizacion.vendedorNombre}',
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                  Text(
                    '${cotizacion.moneda} ${cotizacion.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge compacto que indica que la cotización tiene productos con stock
/// reservado. Naranja para llamar la atención sin chocar con el estado.
class _ReservaBadge extends StatelessWidget {
  const _ReservaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_added, size: 11, color: Colors.orange.shade800),
          const SizedBox(width: 3),
          Text(
            'Reservado',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
