import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/asignar_clientes/asignar_clientes_cubit.dart';
import '../bloc/asignar_clientes/asignar_clientes_state.dart';

class AsignarClientesPage extends StatelessWidget {
  final String politicaId;
  final String politicaNombre;

  const AsignarClientesPage({
    super.key,
    required this.politicaId,
    required this.politicaNombre,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AsignarClientesCubit>()..loadData(politicaId),
      child: _AsignarClientesView(
        politicaId: politicaId,
        politicaNombre: politicaNombre,
      ),
    );
  }
}

class _AsignarClientesView extends StatelessWidget {
  final String politicaId;
  final String politicaNombre;

  const _AsignarClientesView({
    required this.politicaId,
    required this.politicaNombre,
  });

  Future<void> _agregarCliente(BuildContext context) async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    final empresaId = empresaState.context.empresa.id;

    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
    );
    if (result == null || !context.mounted) return;

    await context.read<AsignarClientesCubit>().agregarCliente(
          clienteId: result.clienteId,
          clienteEmpresaId: result.clienteEmpresaId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: SmartAppBar(
        showLogo: false,
        title: 'Clientes VIP',
        subtitle: politicaNombre,
      ),
      body: GradientBackground(
        style: GradientStyle.professional,
        child: SafeArea(
          child: BlocConsumer<AsignarClientesCubit, AsignarClientesState>(
            listener: (context, state) {
              if (state is AsignarClientesError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is AsignarClientesLoading ||
                  state is AsignarClientesInitial) {
                return CustomLoading.small(message: 'Cargando clientes...');
              }
              if (state is AsignarClientesError) {
                return _buildError(context, state.message);
              }
              if (state is AsignarClientesLoaded) {
                return _buildList(context, state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingButtonIcon(
        icon: Icons.person_add,
        onPressed: () => _agregarCliente(context),
      ),
    );
  }

  Widget _buildList(BuildContext context, AsignarClientesLoaded state) {
    if (state.clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Sin clientes VIP asignados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca + para asignar un cliente a este precio especial',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: state.clientes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final c = state.clientes[index];
            final tipo = c['tipo'] as String? ?? 'B2C';
            final esB2B = tipo == 'B2B';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.bluechip),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.bluechip,
                  child: Icon(
                    esB2B ? Icons.business : Icons.person,
                    size: 16,
                    color: AppColors.blue1,
                  ),
                ),
                title: Text(
                  c['nombre'] as String? ?? '(sin nombre)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${esB2B ? 'RUC' : 'DNI'}: ${c['documento'] ?? '-'}  ·  $tipo',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  tooltip: 'Quitar',
                  onPressed: state.working
                      ? null
                      : () => _confirmarRemover(context, c),
                ),
              ),
            );
          },
        ),
        if (state.working)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Future<void> _confirmarRemover(
    BuildContext context,
    Map<String, dynamic> cliente,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar cliente'),
        content: Text(
          '¿Quitar a "${cliente['nombre'] ?? 'este cliente'}" del precio especial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context
          .read<AsignarClientesCubit>()
          .removerClienteAsignado(cliente['id'] as String);
    }
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<AsignarClientesCubit>().loadData(politicaId),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
