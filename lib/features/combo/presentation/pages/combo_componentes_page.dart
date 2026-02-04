import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
import '../../domain/entities/componente_combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';
import '../widgets/componente_list_tile.dart';
import '../widgets/agregar_componente_dialog.dart';

class ComboComponentesPage extends StatelessWidget {
  final String comboId;
  final String empresaId;

  const ComboComponentesPage({
    super.key,
    required this.comboId,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    final sedeId = _resolveSedeId(context);
    return BlocProvider(
      create: (_) => locator<ComboCubit>()
        ..loadComponentes(comboId: comboId, empresaId: empresaId, sedeId: sedeId),
      child: _ComboComponentesView(
        comboId: comboId,
        empresaId: empresaId,
        sedeId: sedeId,
      ),
    );
  }

  static String _resolveSedeId(BuildContext ctx) {
    final selected = ctx.read<SedeSelectionCubit>().selectedSedeId;
    if (selected != null) return selected;
    final empresaState = ctx.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded && empresaState.context.sedes.isNotEmpty) {
      return empresaState.context.sedePrincipal!.id;
    }
    return '';
  }
}

class _ComboComponentesView extends StatelessWidget {
  final String comboId;
  final String empresaId;
  final String sedeId;

  const _ComboComponentesView({
    required this.comboId,
    required this.empresaId,
    required this.sedeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'COMPONENTES DEL COMBO',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ComboCubit>().loadComponentes(
                    comboId: comboId,
                    empresaId: empresaId,
                    sedeId: sedeId,
                  );
            },
          ),
        ],
      ),
      body: BlocConsumer<ComboCubit, ComboState>(
        listener: (context, state) {
          if (state is ComboOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Recargar componentes después de agregar/eliminar
            context.read<ComboCubit>().loadComponentes(
                  comboId: comboId,
                  empresaId: empresaId,
                  sedeId: sedeId,
                );
          } else if (state is ComboError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ComboLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ComponentesLoaded) {
            return _buildComponentesList(context, state.componentes);
          }

          return const Center(
            child: Text('No se pudieron cargar los componentes'),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _mostrarAgregarComponenteDialog(context),
      //   icon: const Icon(Icons.add),
      //   label: const Text('Agregar Componente'),
      // ),
      floatingActionButton: FloatingButtonText(
        onPressed: () => _mostrarAgregarComponenteDialog(context), 
        label: 'Agregar Componente', 
        icon: Icons.add,
      ),
    );
  }

  Widget _buildComponentesList(
    BuildContext context,
    List<ComponenteCombo> componentes,
  ) {
    if (componentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay componentes en este combo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos para crear el combo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: componentes.length,
      itemBuilder: (context, index) {
        final componente = componentes[index];
        return ComponenteListTile(
          componente: componente,
          onDelete: () => _confirmarEliminar(context, componente),
        );
      },
    );
  }

  void _mostrarAgregarComponenteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ComboCubit>(),
        child: AgregarComponenteDialog(
          comboId: comboId,
          empresaId: empresaId,
          sedeId: sedeId,
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, ComponenteCombo componente) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Componente'),
        content: Text(
          '¿Estás seguro de eliminar este componente del combo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ComboCubit>().deleteComponente(
                    componenteId: componente.id,
                    empresaId: empresaId,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
