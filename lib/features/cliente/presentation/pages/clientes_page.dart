import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_filtros.dart';
import '../bloc/cliente_list/cliente_list_cubit.dart';
import '../bloc/cliente_list/cliente_list_state.dart';
import '../widgets/cliente_list_tile.dart';
import '../widgets/cliente_detail_sheet.dart';

class ClientesPage extends StatefulWidget {
  final String empresaId;

  const ClientesPage({
    super.key,
    required this.empresaId,
  });

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final ClienteListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<ClienteListCubit>();
    _scrollController.addListener(_onScroll);
    _loadClientes();
  }

  void _loadClientes() {
    if (widget.empresaId.isNotEmpty) {
      _cubit.loadClientes(empresaId: widget.empresaId);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.empresaId.isEmpty) {
      return Scaffold(
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Clientes',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error: ID de empresa no proporcionado',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Clientes',
        actions: [
          BlocBuilder<ClienteListCubit, ClienteListState>(
            bloc: _cubit,
            builder: (context, state) {
              // Indicador visual cuando hay filtros activos (estado u orden
              // distinto del default Nombre A-Z).
              final hayFiltros = state is ClienteListLoaded &&
                  (state.filtros.isActive != null ||
                      (state.filtros.orden != null &&
                          state.filtros.orden != OrdenCliente.nombreAsc));
              return IconButton(
                tooltip: 'Filtros',
                icon: Badge(
                  isLabelVisible: hayFiltros,
                  smallSize: 8,
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: () => _mostrarFiltros(context),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: GradientBackground(
          style: GradientStyle.minimal,
          child: BlocProvider.value(
            value: _cubit,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: BlocBuilder<ClienteListCubit, ClienteListState>(
                    builder: (context, state) {
                      if (state is ClienteListLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is ClienteListError) {
                        return _buildError(state.message);
                      }

                      if (state is ClienteListLoaded) {
                        if (state.clientes.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildList(state.clientes, state.hasMore);
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingButtonIcon(
        onPressed: () => _navigateToForm(context),
        icon: Icons.add,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: CustomSearchField(
        controller: _searchController,
        hintText: 'Buscar por nombre, DNI, teléfono...',
        borderColor: AppColors.blue.withValues(alpha: 0.3),
        iconColor: AppColors.blue.withValues(alpha: 0.7),
        borderRadius: 8.0,
        height: 35.0,
        onChanged: (value) => _cubit.search(value),
        onClear: () => _cubit.search(''),
      ),
    );
  }

  Widget _buildList(List<Cliente> clientes, bool hasMore) {
    return RefreshIndicator(
      onRefresh: () => _cubit.reload(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        cacheExtent: 500,
        itemCount: clientes.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= clientes.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final cliente = clientes[index];
          return ClienteListTile(
            cliente: cliente,
            onTap: () => _showClienteDetail(context, cliente),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _cubit.reload(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay clientes registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar un cliente',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _ordenLabel(OrdenCliente o) {
    switch (o) {
      case OrdenCliente.nombreAsc:
        return 'Nombre A-Z';
      case OrdenCliente.nombreDesc:
        return 'Nombre Z-A';
      case OrdenCliente.recientes:
        return 'Más recientes';
      case OrdenCliente.antiguos:
        return 'Más antiguos';
    }
  }

  /// Bottom sheet de filtros: Estado (Todos/Activos/Inactivos) + Orden.
  /// Pre-selecciona los filtros vigentes del cubit y, al aplicar, construye
  /// un `ClienteFiltros` nuevo (preservando la búsqueda) para que "Todos"
  /// pueda volver `isActive` a null —el copyWith del cubit no lo permite.
  void _mostrarFiltros(BuildContext context) {
    final estadoActual = _cubit.state;
    final actuales = estadoActual is ClienteListLoaded
        ? estadoActual.filtros
        : const ClienteFiltros();

    bool? selIsActive = actuales.isActive;
    OrdenCliente selOrden = actuales.orden ?? OrdenCliente.nombreAsc;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget chip(String label, bool selected, VoidCallback onTap) {
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              showCheckmark: false,
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.blue1.withValues(alpha: 0.15),
              side: BorderSide(
                color: selected
                    ? AppColors.blue1.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.blue1 : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => onTap(),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.filter_list,
                        size: 20, color: AppColors.blue1),
                    const SizedBox(width: 8),
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue1,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        selIsActive = null;
                        selOrden = OrdenCliente.nombreAsc;
                      }),
                      child: Text(
                        'Limpiar',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Estado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    chip('Todos', selIsActive == null,
                        () => setSheetState(() => selIsActive = null)),
                    chip('Activos', selIsActive == true,
                        () => setSheetState(() => selIsActive = true)),
                    chip('Inactivos', selIsActive == false,
                        () => setSheetState(() => selIsActive = false)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in OrdenCliente.values)
                      chip(_ordenLabel(o), selOrden == o,
                          () => setSheetState(() => selOrden = o)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _cubit.loadClientes(
                        empresaId: widget.empresaId,
                        filtros: ClienteFiltros(
                          search: actuales.search,
                          limit: actuales.limit,
                          isActive: selIsActive,
                          orden: selOrden,
                        ),
                      );
                    },
                    child: const Text(
                      'Aplicar filtros',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClienteDetail(BuildContext context, Cliente cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ClienteDetailSheet(
          cliente: cliente,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    context.push(
      '/empresa/clientes/nuevo',
      extra: {'empresaId': widget.empresaId},
    ).then((result) {
      if (result == true) {
        _cubit.reload();
      }
    });
  }
}
