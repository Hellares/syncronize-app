import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        appBar: AppBar(
          title: const Text('Cotizaciones'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Barra de busqueda
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por codigo, cliente...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CotizacionListCubit>().search('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: (query) {
                  context.read<CotizacionListCubit>().search(query);
                },
              ),
            ),

            // Chips de filtro de estado
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _filtroEstado == null,
                    onSelected: () => _filterByEstado(null),
                  ),
                  const SizedBox(width: 6),
                  ...EstadoCotizacion.values.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: e.label,
                          selected: _filtroEstado == e,
                          onSelected: () => _filterByEstado(e),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),

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
                            onTap: () {
                              context.push(
                                '/empresa/cotizaciones/${cotizacion.id}',
                              );
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/empresa/cotizaciones/nueva');
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva Cotizacion'),
        ),
      ),
    );
  }

  void _filterByEstado(EstadoCotizacion? estado) {
    setState(() => _filtroEstado = estado);
    context.read<CotizacionListCubit>().filterByEstado(estado);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtros'),
        content: const Text('Filtros adicionales (fecha, sede, etc.)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    cotizacion.codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CotizacionEstadoChip(estado: cotizacion.estado),
                  const Spacer(),
                  Text(
                    dateFormat.format(cotizacion.fechaEmision),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (cotizacion.nombre != null &&
                  cotizacion.nombre!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  cotizacion.nombre!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                cotizacion.nombreCliente,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (cotizacion.sedeNombre != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Sede: ${cotizacion.sedeNombre}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (cotizacion.vendedorNombre != null)
                    Text(
                      'Vendedor: ${cotizacion.vendedorNombre}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  Text(
                    '${cotizacion.moneda} ${cotizacion.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
