import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
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
    return BlocProvider(
      create: (_) => locator<ComboCubit>()
        ..loadComponentes(comboId: comboId, empresaId: empresaId),
      child: _ComboComponentesView(
        comboId: comboId,
        empresaId: empresaId,
      ),
    );
  }
}

class _ComboComponentesView extends StatelessWidget {
  final String comboId;
  final String empresaId;

  const _ComboComponentesView({
    required this.comboId,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Componentes del Combo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ComboCubit>().loadComponentes(
                    comboId: comboId,
                    empresaId: empresaId,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarAgregarComponenteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Componente'),
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
