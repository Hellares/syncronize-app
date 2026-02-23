import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_alert_dialog.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';
import '../bloc/plan_suscripcion/plan_suscripcion_cubit.dart';
import '../bloc/plan_suscripcion/plan_suscripcion_state.dart';
import '../widgets/plan_card.dart';

class PlanesPage extends StatelessWidget {
  const PlanesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PlanSuscripcionCubit>()..loadPlanes(),
      child: const _PlanesPageContent(),
    );
  }
}

class _PlanesPageContent extends StatelessWidget {
  const _PlanesPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Planes de Suscripcion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.blue1,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocConsumer<PlanSuscripcionCubit, PlanSuscripcionState>(
        listener: (context, state) {
          if (state is PlanSuscripcionCambiado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plan cambiado exitosamente'),
                backgroundColor: AppColors.green,
              ),
            );
            // Reload empresa context to reflect new plan
            context.read<EmpresaContextCubit>().reloadContext();
            Navigator.of(context).pop();
          }
          if (state is PlanSuscripcionCambioError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PlanSuscripcionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PlanSuscripcionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PlanSuscripcionCubit>().loadPlanes();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final planes = state is PlanSuscripcionLoaded
              ? state.planes
              : state is PlanSuscripcionCambiando
                  ? state.planes
                  : state is PlanSuscripcionCambioError
                      ? state.planes
                      : [];

          if (planes.isEmpty) {
            return const Center(
              child: Text('No hay planes disponibles'),
            );
          }

          // Get current plan id from empresa context
          final empresaContextState =
              context.watch<EmpresaContextCubit>().state;
          String? currentPlanId;
          String? empresaId;
          if (empresaContextState is EmpresaContextLoaded) {
            currentPlanId =
                empresaContextState.context.empresa.planSuscripcionId;
            empresaId = empresaContextState.context.empresa.id;
          }

          final isChanging = state is PlanSuscripcionCambiando;

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<PlanSuscripcionCubit>().loadPlanes();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: planes.length,
              itemBuilder: (context, index) {
                final plan = planes[index];
                final isCurrentPlan = plan.id == currentPlanId;

                return PlanCard(
                  plan: plan,
                  isCurrentPlan: isCurrentPlan,
                  isLoading: isChanging,
                  onSelect: isChanging
                      ? null
                      : () => _onSelectPlan(
                            context,
                            empresaId: empresaId!,
                            planId: plan.id,
                            planNombre: plan.nombre,
                          ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _onSelectPlan(
    BuildContext context, {
    required String empresaId,
    required String planId,
    required String planNombre,
  }) async {
    final confirmed = await CustomAlertDialog.show<bool>(
      context: context,
      title: Text('Cambiar Plan'),
      content: Text('Estas seguro de que deseas cambiar al plan $planNombre?\n\n'
          'El cambio se aplicara inmediatamente.'),
      cancelText: 'Cancelar',
      confirmText: 'Cambiar',
      confirmColor: AppColors.blue1,
    );

    if (confirmed == true && context.mounted) {
      context.read<PlanSuscripcionCubit>().cambiarPlan(
            empresaId: empresaId,
            planId: planId,
          );
    }
  }
}
