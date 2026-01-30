import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/proveedor_list/proveedor_list_cubit.dart';
import '../bloc/proveedor_list/proveedor_list_state.dart';
import '../widgets/proveedor_list_tile.dart';

class ProveedoresPage extends StatelessWidget {
  final String empresaId;

  const ProveedoresPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ProveedorListCubit>()
        ..loadProveedores(empresaId: empresaId),
      child: Scaffold(
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Proveedores',
          actions: [
            BlocBuilder<ProveedorListCubit, ProveedorListState>(
              builder: (context, state) {
                if (state is ProveedorListLoaded) {
                  return IconButton(
                    icon: Icon(state.includeInactive
                        ? Icons.visibility_off
                        : Icons.visibility,
                        size: 18,
                        ),
                    onPressed: () {
                      context
                          .read<ProveedorListCubit>()
                          .toggleIncludeInactive();
                    },
                    tooltip: state.includeInactive
                        ? 'Ocultar inactivos'
                        : 'Mostrar inactivos',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(8.0),
                // child: TextField(
                //   decoration: InputDecoration(
                //     hintText: 'Buscar por nombre, código o documento',
                //     prefixIcon: const Icon(Icons.search),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     filled: true,
                //   ),
                //   onChanged: (value) {
                //     context.read<ProveedorListCubit>().search(value);
                //   },
                // ),
                child: CustomSearchField(
                  borderColor: AppColors.blue1,
                  hintText: 'Buscar por nombre, código o documento',
                  onChanged: (value) {
                    context.read<ProveedorListCubit>().search(value);
                  },
                )
              ),
              // Lista de proveedores
              Expanded(
                child: BlocBuilder<ProveedorListCubit, ProveedorListState>(
                  builder: (context, state) {
                    if (state is ProveedorListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                
                    if (state is ProveedorListError) {
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
                                  context.read<ProveedorListCubit>().reload(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }
                
                    if (state is ProveedorListLoaded) {
                      final proveedores = state.filteredProveedores;
                
                      if (proveedores.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.business_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                state.searchQuery != null
                                    ? 'No se encontraron proveedores'
                                    : 'No hay proveedores registrados',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (state.searchQuery == null)
                                const Text(
                                  'Presiona el botón + para agregar uno',
                                  style:
                                      TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                        );
                      }
                
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<ProveedorListCubit>().reload(),
                        child: ListView.builder(
                          itemCount: proveedores.length,
                          itemBuilder: (context, index) {
                            final proveedor = proveedores[index];
                            return ProveedorListTile(
                              proveedor: proveedor,
                              onTap: () {
                                context.push(
                                  '/empresa/$empresaId/proveedores/${proveedor.id}',
                                  extra: proveedor,
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // Guardar referencia al cubit antes del async gap
            final cubit = context.read<ProveedorListCubit>();
            final result = await context.push(
              '/empresa/$empresaId/proveedores/nuevo',
            );
            if (result == true) {
              cubit.reload();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Proveedor'),
        ),
      ),
    );
  }
}
