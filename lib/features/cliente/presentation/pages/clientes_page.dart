import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/cliente_list/cliente_list_cubit.dart';
import '../bloc/cliente_list/cliente_list_state.dart';
import '../widgets/cliente_list_tile.dart';

class ClientesPage extends StatelessWidget {
  final String empresaId;

  const ClientesPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Verificar empresaId
    if (empresaId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
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
              const SizedBox(height: 8),
              Text(
                'empresaId recibido: "$empresaId"',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => locator<ClienteListCubit>()
        ..loadClientes(empresaId: empresaId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clientes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implementar búsqueda
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Implementar filtros
              },
            ),
          ],
        ),
        body: BlocBuilder<ClienteListCubit, ClienteListState>(
          builder: (context, state) {
            if (state is ClienteListLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ClienteListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClienteListCubit>().reload();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is ClienteListLoaded) {
              if (state.clientes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay clientes registrados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Presiona el botón + para agregar uno',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<ClienteListCubit>().reload();
                },
                child: ListView.builder(
                  itemCount: state.clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = state.clientes[index];
                    return ClienteListTile(
                      cliente: cliente,
                      onTap: () {
                        // TODO: Implementar página de detalle de cliente
                        // context.push('/empresa/clientes/${cliente.id}');
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push(
              '/empresa/clientes/nuevo',
              extra: {'empresaId': empresaId},
            );

            // Recargar la lista si se registró un cliente
            if (result == true && context.mounted) {
              context.read<ClienteListCubit>().reload();
            }
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Nuevo Cliente'),
        ),
      ),
    );
  }
}
