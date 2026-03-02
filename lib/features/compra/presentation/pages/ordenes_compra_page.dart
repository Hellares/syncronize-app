import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/floating_button_text.dart';
import '../bloc/orden_compra_list/orden_compra_list_cubit.dart';
import '../bloc/orden_compra_list/orden_compra_list_state.dart';
import '../widgets/orden_compra_list_tile.dart';

class OrdenesCompraPage extends StatelessWidget {
  final String empresaId;

  const OrdenesCompraPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<OrdenCompraListCubit>()
        ..loadOrdenes(empresaId: empresaId),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Órdenes de Compra',
          ),
          body: GradientContainer(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomSearchField(
                    borderColor: AppColors.blue1,
                    hintText: 'Buscar por código o proveedor',
                    onChanged: (value) {
                      context.read<OrdenCompraListCubit>().search(value);
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<OrdenCompraListCubit, OrdenCompraListState>(
                    builder: (context, state) {
                      if (state is OrdenCompraListLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is OrdenCompraListError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(state.message,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<OrdenCompraListCubit>().reload(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is OrdenCompraListLoaded) {
                        final ordenes = state.filteredOrdenes;

                        if (ordenes.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.description_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  state.searchQuery != null
                                      ? 'No se encontraron órdenes'
                                      : 'No hay órdenes de compra',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                if (state.searchQuery == null)
                                  const Text(
                                    'Presiona el botón + para crear una',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<OrdenCompraListCubit>().reload(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: ordenes.length,
                            itemBuilder: (context, index) {
                              final orden = ordenes[index];
                              return OrdenCompraListTile(
                                orden: orden,
                                onTap: () async {
                                  final cubit = context.read<OrdenCompraListCubit>();
                                  final result = await context.push(
                                    '/empresa/compras/ordenes/${orden.id}',
                                    extra: orden,
                                  );
                                  if (result == true) {
                                    cubit.reload();
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
          // floatingActionButton: FloatingActionButton.extended(
          //   onPressed: () async {
          //     final cubit = context.read<OrdenCompraListCubit>();
          //     final result = await context.push(
          //       '/empresa/compras/ordenes/nueva',
          //     );
          //     if (result == true) {
          //       cubit.reload();
          //     }
          //   },
          //   icon: const Icon(Icons.add),
          //   label: const Text('Nueva OC'),
          // ),
          floatingActionButton: FloatingButtonText(
            width: 110,
            onPressed: () async {
              final cubit = context.read<OrdenCompraListCubit>();
              final result = await context.push(
                '/empresa/compras/ordenes/nueva',
              );
              if(result == true){
                cubit.reload();
              }
            },
            icon: Icons.add,
            label: 'Nueva OC',
          ),
        ),
      ),
    );
  }
}
