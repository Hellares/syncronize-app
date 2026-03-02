import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/lote_list/lote_list_cubit.dart';
import '../bloc/lote_list/lote_list_state.dart';
import '../widgets/lote_list_tile.dart';

class LotesPage extends StatelessWidget {
  final String empresaId;

  const LotesPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<LoteListCubit>()
        ..loadLotes(empresaId: empresaId),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Lotes',
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, size: 18),
                onSelected: (value) {
                  final cubit = context.read<LoteListCubit>();
                  switch (value) {
                    case 'todos':
                      cubit.filterByEstado(null);
                      break;
                    case 'ACTIVO':
                    case 'AGOTADO':
                    case 'VENCIDO':
                    case 'BLOQUEADO':
                      cubit.filterByEstado(value);
                      break;
                    case 'proximos_vencer':
                      cubit.loadProximosVencer(empresaId: empresaId);
                      break;
                    case 'marcar_vencidos':
                      _marcarVencidos(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'todos', child: Text('Todos')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'ACTIVO', child: Text('Activos')),
                  const PopupMenuItem(value: 'AGOTADO', child: Text('Agotados')),
                  const PopupMenuItem(value: 'VENCIDO', child: Text('Vencidos')),
                  const PopupMenuItem(
                      value: 'BLOQUEADO', child: Text('Bloqueados')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'proximos_vencer',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Próximos a vencer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'marcar_vencidos',
                    child: Row(
                      children: [
                        Icon(Icons.update, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Marcar vencidos'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: GradientContainer(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomSearchField(
                    borderColor: AppColors.blue1,
                    hintText: 'Buscar por código, producto o proveedor',
                    onChanged: (value) {
                      context.read<LoteListCubit>().search(value);
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<LoteListCubit, LoteListState>(
                    builder: (context, state) {
                      if (state is LoteListLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is LoteListError) {
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
                                    context.read<LoteListCubit>().reload(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is LoteListLoaded) {
                        final lotes = state.filteredLotes;

                        if (lotes.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  state.searchQuery != null
                                      ? 'No se encontraron lotes'
                                      : 'No hay lotes registrados',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Los lotes se crean al confirmar una compra',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<LoteListCubit>().reload(),
                          child: ListView.builder(
                            itemCount: lotes.length,
                            itemBuilder: (context, index) {
                              final lote = lotes[index];
                              return LoteListTile(
                                lote: lote,
                                onTap: () {
                                  context.push(
                                    '/empresa/compras/lotes/${lote.id}',
                                    extra: lote,
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
        ),
      ),
    );
  }

  void _marcarVencidos(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar lotes vencidos'),
        content: const Text(
            'Se marcarán como VENCIDO todos los lotes cuya fecha de vencimiento ya pasó. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Marcar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final success =
          await context.read<LoteListCubit>().marcarVencidos();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lotes vencidos actualizados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
