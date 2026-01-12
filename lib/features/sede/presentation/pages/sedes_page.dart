import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/sede_list/sede_list_cubit.dart';
import '../bloc/sede_list/sede_list_state.dart';
import '../widgets/sede_list_tile.dart';

class SedesPage extends StatefulWidget {
  const SedesPage({super.key});

  @override
  State<SedesPage> createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> {
  bool _canManageSedes = false;

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  void _loadSedes() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _canManageSedes = empresaState.context.permissions.canManageSedes;

      context.read<SedeListCubit>().loadSedes(
            empresaState.context.empresa.id,
          );
    }
  }

  Future<void> _onRefresh() async {
    await context.read<SedeListCubit>().refresh();
  }

  void _showDeleteConfirmation(String sedeId, String sedeName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Sede'),
        content: Text('¿Estás seguro de eliminar la sede "$sedeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success =
                  await context.read<SedeListCubit>().deleteSede(sedeId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Sede eliminada exitosamente'
                          : 'Error al eliminar sede',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        if (empresaState is! EmpresaContextLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          
          appBar: SmartAppBar(
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            title: 'Sedes',
            actions: [
              Text(empresaState.context.empresa.nombre,maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10),),
              
              SizedBox(width: 16,)
            ],
          ),
          
          body: GradientBackground(
            child: BlocConsumer<SedeListCubit, SedeListState>(
              listener: (context, state) {
                if (state is SedeListError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is SedeListLoading) {
                  return const Center(child: CustomLoading());
                }

                if (state is SedeListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSedes,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SedeListLoaded) {
                  final sedes = state.sedes;

                  if (sedes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sedes registradas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu primera sede',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: sedes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sede = sedes[index];
                        return SedeListTile(
                          sede: sede,
                          canManage: _canManageSedes,
                          onTap: () {
                            // Navegar a detalles o editar
                            if (_canManageSedes) {
                              context.push('/empresa/sedes/${sede.id}/edit');
                            }
                          },
                          onDelete: _canManageSedes && !sede.esPrincipal
                              ? () => _showDeleteConfirmation(
                                  sede.id, sede.nombre)
                              : null,
                        );
                      },
                    ),
                  );
                }

                return const Center(child: Text('Estado desconocido'));
              },
            ),
          ),
          floatingActionButton: _canManageSedes
              ? FloatingButtonIcon(
                  onPressed: () => context.push('/empresa/sedes/create'),
                  icon: Icons.add,
                  // label: 'Nueva Sede',
                )
              : null,
        );
      },
    );
  }
}
