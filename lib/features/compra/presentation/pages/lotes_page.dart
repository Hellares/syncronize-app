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
import '../widgets/lotes_tabla.dart';

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
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Actualizar',
                onPressed: () => context.read<LoteListCubit>().reload(),
              ),
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
                // El buscador vive FUERA del BlocBuilder: si se reconstruyera
                // con cada carga perdería el foco mientras se escribe.
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
                BlocBuilder<LoteListCubit, LoteListState>(
                  builder: (context, state) => state is LoteListLoaded
                      ? _BarraResumen(state: state)
                      : const SizedBox.shrink(),
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
                        if (state.lotes.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  state.hayFiltro
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

                        return LotesTabla(
                          lotes: state.lotes,
                          hasNext: state.hasNext,
                          cargandoMas: state.cargandoMas,
                          onCargarMas: () =>
                              context.read<LoteListCubit>().loadMore(),
                          onTap: (lote) async {
                            final cambio = await context.push<bool>(
                              '/empresa/compras/lotes/${lote.id}',
                              extra: lote,
                            );
                            // Se dio de baja o se corrigió la fecha adentro:
                            // la tabla tiene que reflejarlo.
                            if (cambio == true && context.mounted) {
                              context.read<LoteListCubit>().reload();
                            }
                          },
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

/// Cuántos lotes se ven de cuántos hay, y el filtro activo con su ✕ para
/// quitarlo (así se sabe por qué la tabla muestra lo que muestra).
class _BarraResumen extends StatelessWidget {
  final LoteListLoaded state;

  const _BarraResumen({required this.state});

  static String? _nombreEstado(String? estado) {
    switch (estado) {
      case 'ACTIVO':
        return 'Activos';
      case 'AGOTADO':
        return 'Agotados';
      case 'VENCIDO':
        return 'Vencidos';
      case 'BLOQUEADO':
        return 'Bloqueados';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filtro = state.proximosVencer
        ? 'Próximos a vencer'
        : _nombreEstado(state.estadoFilter);
    final texto = state.proximosVencer
        ? '${state.lotes.length} ${state.lotes.length == 1 ? 'lote' : 'lotes'}'
        : 'Mostrando ${state.lotes.length} de ${state.total} '
            '${state.total == 1 ? 'lote' : 'lotes'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
          if (filtro != null)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              // Quitar el filtro vuelve a TODOS los estados (y sale de
              // "Próximos a vencer").
              onTap: () => context.read<LoteListCubit>().filterByEstado(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filtro,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.blue1),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close, size: 12, color: AppColors.blue1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
