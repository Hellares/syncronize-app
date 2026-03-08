import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../bloc/servicio_list/servicio_list_cubit.dart';
import '../bloc/servicio_list/servicio_list_state.dart';
import '../../domain/entities/servicio_filtros.dart';

class ServiciosPage extends StatelessWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<ServicioListCubit>()
            ..loadServicios(empresaId: empresaId),
          child: _ServiciosPageContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _ServiciosPageContent extends StatelessWidget {
  final String empresaId;
  const _ServiciosPageContent({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      drawer: const EmpresaDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/empresa/servicios/crear'),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ServicioListCubit, ServicioListState>(
        builder: (context, state) {
          if (state is ServicioListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServicioListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ServicioListCubit>().refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final servicios = state is ServicioListLoaded ? state.servicios : [];

          if (servicios.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.room_service, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay servicios',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Crea tu primer servicio para comenzar',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ServicioListCubit>().refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                  context.read<ServicioListCubit>().loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: servicios.length + (state is ServicioListLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= servicios.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                final servicio = servicios[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Icon(Icons.room_service,
                          color: Theme.of(context).primaryColor),
                    ),
                    title: Text(servicio.nombre),
                    subtitle: Text(
                      [
                        servicio.codigoEmpresa,
                        if (servicio.precio != null) 'S/ ${servicio.precio!.toStringAsFixed(2)}',
                        if (servicio.categoria != null) servicio.categoria!.nombre,
                      ].join(' · '),
                    ),
                    trailing: servicio.enOferta
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Oferta',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green.shade700)),
                          )
                        : null,
                    onTap: () => context.push('/empresa/servicios/${servicio.id}/editar'),
                  ),
                );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ServicioSearchDelegate(
        onSearch: (query) {
          context.read<ServicioListCubit>().applyFiltros(
                ServicioFiltros(search: query),
              );
        },
      ),
    );
  }
}

class _ServicioSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  _ServicioSearchDelegate({required this.onSearch});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
