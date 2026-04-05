import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/custom_filter_chip.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_list/venta_list_cubit.dart';
import '../bloc/venta_list/venta_list_state.dart';
import '../widgets/venta_estado_chip.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  EstadoVenta? _filtroEstado;
  final _searchController = TextEditingController();
  String? _currentEmpresaId;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadVentas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;
      context.read<VentaListCubit>().loadVentas(
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
            _loadVentas();
          }
        }
      },
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Ventas',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientContainer(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CustomSearchField(
                  controller: _searchController,
                  borderColor: AppColors.blue1,
                  hintText: 'Buscar por codigo, cliente...',
                  onChanged: (query) {
                    context.read<VentaListCubit>().search(query);
                  },
                  onSubmitted: (query) {
                    context.read<VentaListCubit>().search(query);
                  },
                  onClear: () {
                    context.read<VentaListCubit>().search('');
                  },
                ),
              ),

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
                    ...EstadoVenta.values.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CustomFilterChip(
                            showCheckmark: true,
                            label: e.label,
                            selected: _filtroEstado == e,
                            onSelected: () => _filterByEstado(e),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              BlocBuilder<VentaListCubit, VentaListState>(
                builder: (context, state) {
                  if (state is VentaListLoaded) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppText(
                          '${state.ventas.length} venta${state.ventas.length != 1 ? 's' : ''}',
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

              Expanded(
                child: BlocBuilder<VentaListCubit, VentaListState>(
                  builder: (context, state) {
                    if (state is VentaListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VentaListError) {
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
                                  context.read<VentaListCubit>().reload(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VentaListLoaded) {
                      if (state.ventas.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.point_of_sale,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No hay ventas',
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
                            context.read<VentaListCubit>().reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: state.ventas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final venta = state.ventas[index];
                            return _VentaListTile(
                              venta: venta,
                              onTap: () {
                                context
                                    .push('/empresa/ventas/${venta.id}');
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
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/empresa/ventas/nueva'),
      icon: const Icon(Icons.add),
      label: const Text('Nueva Venta'),
      backgroundColor: AppColors.blue1,
      foregroundColor: Colors.white,
    );
  }

  void _filterByEstado(EstadoVenta? estado) {
    setState(() => _filtroEstado = estado);
    context.read<VentaListCubit>().filterByEstado(estado);
  }
}

class _VentaListTile extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _VentaListTile({required this.venta, required this.onTap});

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
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(venta.codigo),
                  const SizedBox(width: 8),
                  VentaEstadoChip(estado: venta.estado),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDate(venta.fechaVenta),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(width: 70, child: AppText('Cliente:')),
                  Expanded(
                      child: AppText(venta.nombreCliente,
                          fontWeight: FontWeight.w400)),
                ],
              ),
              if (venta.telefonoCliente != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppText('Telefono:')),
                    Expanded(
                        child: AppText(venta.telefonoCliente!,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
              if (venta.sedeNombre != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 70, child: AppText('Sede:')),
                    Expanded(
                        child: AppText(venta.sedeNombre!,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
              if (venta.cotizacionCodigo != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.link, size: 12, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Desde: ${venta.cotizacionCodigo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (venta.vendedorNombre != null)
                    Text(
                      'Vendedor: ${venta.vendedorNombre}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  Text(
                    '${venta.moneda} ${venta.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 8,
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
