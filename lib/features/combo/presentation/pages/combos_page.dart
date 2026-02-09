import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
import '../../domain/entities/combo.dart';
import '../bloc/combo_cubit.dart';
import '../bloc/combo_state.dart';
import '../widgets/combo_card.dart';

class CombosPage extends StatelessWidget {
  final String empresaId;

  const CombosPage({
    super.key,
    required this.empresaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ComboCubit>(),
      child: _CombosView(empresaId: empresaId),
    );
  }
}

class _CombosView extends StatefulWidget {
  final String empresaId;

  const _CombosView({required this.empresaId});

  @override
  State<_CombosView> createState() => _CombosViewState();
}

class _CombosViewState extends State<_CombosView> {
  @override
  void initState() {
    super.initState();
    context.read<ComboCubit>().loadCombos(empresaId: widget.empresaId, sedeId: _getSedeId());
  }

  String _getSedeId() {
    final selected = context.read<SedeSelectionCubit>().selectedSedeId;
    if (selected != null) return selected;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded && empresaState.context.sedes.isNotEmpty) {
      return empresaState.context.sedePrincipal!.id;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combos y Kits'),
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
      body: BlocConsumer<ComboCubit, ComboState>(
        listener: (context, state) {
          if (state is ComboError) {
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

          if (state is CombosLoaded) {
            return _buildCombosList(context, state.combos);
          }

          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'combos_page_fab',
        onPressed: () => context.push('/empresa/combos/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Crear Combo'),
      ),
    );
  }

  Widget _buildCombosList(BuildContext context, List<Combo> combos) {
    if (combos.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ComboCubit>().loadCombos(empresaId: widget.empresaId, sedeId: _getSedeId());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: combos.length,
        itemBuilder: (context, index) {
          final combo = combos[index];
          return ComboCard(
            combo: combo,
            onTap: () {
              // Navegar a detalle del combo
              context.push('/empresa/combos/${combo.id}?empresaId=${widget.empresaId}');
            },
            onEdit: () {
              // Navegar a editar combo (por implementar)
            },
            onManageComponents: () {
              // Navegar a gestión de componentes
              context.push('/empresa/combos/${combo.id}/componentes?empresaId=${widget.empresaId}');
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay combos creados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea combos a partir de tus productos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/empresa/combos/nuevo'),
            icon: const Icon(Icons.add),
            label: const Text('Crear tu primer combo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
