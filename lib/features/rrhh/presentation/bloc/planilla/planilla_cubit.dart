import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';


import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/boleta_pago.dart';
import '../../../domain/entities/periodo_planilla.dart';
import '../../../domain/repositories/planilla_repository.dart';
import 'planilla_state.dart';

@injectable
class PlanillaCubit extends Cubit<PlanillaState> {
  final PlanillaRepository _repository;

  PlanillaCubit(this._repository) : super(const PlanillaInitial());

  Future<void> loadPeriodos({Map<String, dynamic>? queryParams}) async {
    emit(const PlanillaLoading());

    final result = await _repository.getPeriodos(queryParams: queryParams);
    if (isClosed) return;

    if (result is Success<List<PeriodoPlanilla>>) {
      emit(PlanillaPeriodosLoaded(result.data));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> loadPeriodoDetail(String id) async {
    emit(const PlanillaLoading());

    final result = await _repository.getPeriodo(id);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(PlanillaPeriodoDetailLoaded(result.data));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> calcularPlanilla(String periodoId) async {
    emit(const PlanillaLoading());

    final result = await _repository.calcularPlanilla(periodoId);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(const PlanillaActionSuccess('Planilla calculada exitosamente'));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> aprobarPeriodo(String id) async {
    emit(const PlanillaLoading());

    final result = await _repository.aprobarPeriodo(id);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(const PlanillaActionSuccess('Periodo aprobado exitosamente'));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> pagarPlanilla(String periodoId, Map<String, dynamic> data) async {
    emit(const PlanillaLoading());

    final result = await _repository.pagarPlanilla(periodoId, data);
    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      emit(const PlanillaActionSuccess('Planilla pagada exitosamente'));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> loadBoleta(String boletaId) async {
    emit(const PlanillaLoading());

    final result = await _repository.getBoleta(boletaId);
    if (isClosed) return;

    if (result is Success<BoletaPago>) {
      emit(PlanillaBoletaLoaded(result.data));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }

  Future<void> pagarBoleta(String boletaId, Map<String, dynamic> data) async {
    emit(const PlanillaLoading());

    final result = await _repository.pagarBoleta(boletaId, data);
    if (isClosed) return;

    if (result is Success<BoletaPago>) {
      emit(const PlanillaActionSuccess('Boleta pagada exitosamente'));
    } else if (result is Error) {
      emit(PlanillaError((result as Error).message));
    }
  }
}
