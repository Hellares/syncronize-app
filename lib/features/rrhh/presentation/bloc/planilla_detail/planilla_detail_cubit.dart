import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/boleta_pago.dart';
import '../../../domain/repositories/planilla_repository.dart';
import 'planilla_detail_state.dart';

@injectable
class PlanillaDetailCubit extends Cubit<PlanillaDetailState> {
  final PlanillaRepository _repository;

  String? _lastPeriodoId;

  PlanillaDetailCubit(this._repository)
      : super(const PlanillaDetailInitial());

  Future<void> loadBoletas(String periodoId) async {
    _lastPeriodoId = periodoId;

    emit(const PlanillaDetailLoading());

    final result = await _repository.getBoletas(
      queryParams: {'periodoId': periodoId},
    );
    if (isClosed) return;

    if (result is Success<List<BoletaPago>>) {
      emit(PlanillaDetailLoaded(result.data));
    } else if (result is Error) {
      emit(PlanillaDetailError((result as Error).message));
    }
  }

  Future<void> pagarBoleta(String boletaId, String metodoPago) async {
    emit(const PlanillaDetailLoading());

    final result = await _repository.pagarBoleta(
      boletaId,
      {'metodoPago': metodoPago},
    );
    if (isClosed) return;

    if (result is Success<BoletaPago>) {
      emit(const PlanillaDetailActionSuccess('Boleta pagada exitosamente'));
      if (_lastPeriodoId != null) {
        await loadBoletas(_lastPeriodoId!);
      }
    } else if (result is Error) {
      emit(PlanillaDetailError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    if (_lastPeriodoId != null) {
      await loadBoletas(_lastPeriodoId!);
    }
  }
}
