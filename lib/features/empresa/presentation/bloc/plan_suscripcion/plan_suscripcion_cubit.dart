import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/repositories/plan_suscripcion_repository.dart';
import 'plan_suscripcion_state.dart';

@injectable
class PlanSuscripcionCubit extends Cubit<PlanSuscripcionState> {
  final PlanSuscripcionRepository _repository;

  PlanSuscripcionCubit(this._repository)
      : super(const PlanSuscripcionInitial());

  /// Carga los planes de suscripcion disponibles
  Future<void> loadPlanes() async {
    emit(const PlanSuscripcionLoading());

    final result = await _repository.getPlanes();

    if (result is Success) {
      emit(PlanSuscripcionLoaded((result as Success).data));
    } else if (result is Error) {
      emit(PlanSuscripcionError((result as Error).message));
    }
  }

  /// Cambia el plan de suscripcion de la empresa
  Future<void> cambiarPlan({
    required String empresaId,
    required String planId,
  }) async {
    final currentState = state;
    final planes = currentState is PlanSuscripcionLoaded
        ? currentState.planes
        : currentState is PlanSuscripcionCambioError
            ? currentState.planes
            : <dynamic>[];

    emit(PlanSuscripcionCambiando(List.from(planes)));

    final result = await _repository.cambiarPlan(
      empresaId: empresaId,
      planId: planId,
    );

    if (result is Success) {
      emit(const PlanSuscripcionCambiado());
    } else if (result is Error) {
      emit(PlanSuscripcionCambioError(
        (result as Error).message,
        List.from(planes),
      ));
    }
  }
}
