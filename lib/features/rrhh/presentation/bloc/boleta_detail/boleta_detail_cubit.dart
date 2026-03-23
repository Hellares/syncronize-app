import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/boleta_pago.dart';
import '../../../domain/repositories/planilla_repository.dart';
import 'boleta_detail_state.dart';

@injectable
class BoletaDetailCubit extends Cubit<BoletaDetailState> {
  final PlanillaRepository _repository;

  BoletaDetailCubit(this._repository) : super(const BoletaDetailInitial());

  Future<void> loadBoleta(String boletaId) async {
    emit(const BoletaDetailLoading());

    final result = await _repository.getBoleta(boletaId);
    if (isClosed) return;

    if (result is Success<BoletaPago>) {
      emit(BoletaDetailLoaded(result.data));
    } else if (result is Error) {
      emit(BoletaDetailError((result as Error).message));
    }
  }
}
