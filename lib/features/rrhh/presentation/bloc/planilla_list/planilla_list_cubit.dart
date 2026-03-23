import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/periodo_planilla.dart';
import '../../../domain/repositories/planilla_repository.dart';
import 'planilla_list_state.dart';

@injectable
class PlanillaListCubit extends Cubit<PlanillaListState> {
  final PlanillaRepository _repository;

  Map<String, dynamic> _lastParams = {};

  PlanillaListCubit(this._repository) : super(const PlanillaListInitial());

  Future<void> loadPeriodos({int? anio, String? estado}) async {
    _lastParams = {
      if (anio != null) 'anio': anio.toString(),
      if (estado != null) 'estado': estado,
    };

    emit(const PlanillaListLoading());

    final result = await _repository.getPeriodos(queryParams: _lastParams);
    if (isClosed) return;

    if (result is Success<List<PeriodoPlanilla>>) {
      emit(PlanillaListLoaded(result.data));
    } else if (result is Error) {
      emit(PlanillaListError((result as Error).message));
    }
  }

  Future<void> crearPeriodo(Map<String, dynamic> data) async {
    emit(const PlanillaListLoading());

    final result = await _repository.createPeriodo(data);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(const PlanillaListActionSuccess('Periodo creado exitosamente'));
      await loadPeriodos(
        anio: _lastParams['anio'] != null
            ? int.tryParse(_lastParams['anio'])
            : null,
        estado: _lastParams['estado'],
      );
    } else if (result is Error) {
      emit(PlanillaListError((result as Error).message));
    }
  }

  Future<void> calcularPlanilla(String periodoId) async {
    emit(const PlanillaListLoading());

    final result = await _repository.calcularPlanilla(periodoId);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(const PlanillaListActionSuccess('Planilla calculada exitosamente'));
      await loadPeriodos(
        anio: _lastParams['anio'] != null
            ? int.tryParse(_lastParams['anio'])
            : null,
        estado: _lastParams['estado'],
      );
    } else if (result is Error) {
      emit(PlanillaListError((result as Error).message));
    }
  }

  Future<void> aprobarPeriodo(String id) async {
    emit(const PlanillaListLoading());

    final result = await _repository.aprobarPeriodo(id);
    if (isClosed) return;

    if (result is Success<PeriodoPlanilla>) {
      emit(const PlanillaListActionSuccess('Periodo aprobado exitosamente'));
      await loadPeriodos(
        anio: _lastParams['anio'] != null
            ? int.tryParse(_lastParams['anio'])
            : null,
        estado: _lastParams['estado'],
      );
    } else if (result is Error) {
      emit(PlanillaListError((result as Error).message));
    }
  }

  Future<void> pagarPlanilla(
    String periodoId,
    String metodoPago,
  ) async {
    emit(const PlanillaListLoading());

    final result = await _repository.pagarPlanilla(
      periodoId,
      {'metodoPago': metodoPago},
    );
    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      emit(const PlanillaListActionSuccess('Planilla pagada exitosamente'));
      await loadPeriodos(
        anio: _lastParams['anio'] != null
            ? int.tryParse(_lastParams['anio'])
            : null,
        estado: _lastParams['estado'],
      );
    } else if (result is Error) {
      emit(PlanillaListError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadPeriodos(
      anio: _lastParams['anio'] != null
          ? int.tryParse(_lastParams['anio'])
          : null,
      estado: _lastParams['estado'],
    );
  }
}
