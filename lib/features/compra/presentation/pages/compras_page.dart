import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/compra_list/compra_list_cubit.dart';
import '../bloc/compra_list/compra_list_state.dart';
import '../widgets/compra_list_tile.dart';

class ComprasPage extends StatelessWidget {
  final String empresaId;

  const ComprasPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CompraListCubit>()
        ..loadCompras(empresaId: empresaId),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Recepciones de Compra',
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
                      context.read<CompraListCubit>().search(value);
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<CompraListCubit, CompraListState>(
                    builder: (context, state) {
                      if (state is CompraListLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is CompraListError) {
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
                                    context.read<CompraListCubit>().reload(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is CompraListLoaded) {
                        final compras = state.filteredCompras;

                        if (compras.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  state.searchQuery != null
                                      ? 'No se encontraron recepciones'
                                      : 'No hay recepciones de compra',
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
                              context.read<CompraListCubit>().reload(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: compras.length,
                            itemBuilder: (context, index) {
                              final compra = compras[index];
                              return CompraListTile(
                                compra: compra,
                                onTap: () async {
                                  final cubit = context.read<CompraListCubit>();
                                  final result = await context.push(
                                    '/empresa/compras/recepciones/${compra.id}',
                                    extra: compra,
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
          floatingActionButton: FloatingButtonText(
            width: 130,
            onPressed: () async {
              final cubit = context.read<CompraListCubit>();
              final result = await context.push(
                '/empresa/compras/recepciones/nueva',
              );
              if(result == true){
                cubit.reload();
              }
            },
            icon: Icons.add,
            label: 'Nueva Compra',
          ),
        ),
      ),
    );
  }
}
