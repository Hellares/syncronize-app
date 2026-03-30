import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/pago_suscripcion.dart';
import '../../../domain/usecases/get_mis_pagos_usecase.dart';

part 'mis_pagos_state.dart';

@injectable
class MisPagosSuscripcionCubit extends Cubit<MisPagosSuscripcionState> {
  final GetMisPagosUseCase _getMisPagosUseCase;

  MisPagosSuscripcionCubit(this._getMisPagosUseCase)
      : super(const MisPagosSuscripcionInitial());

  Future<void> loadPagos({int page = 1, int pageSize = 20}) async {
    emit(const MisPagosSuscripcionLoading());

    final result = await _getMisPagosUseCase(page: page, pageSize: pageSize);
    if (isClosed) return;

    if (result is Success<List<PagoSuscripcion>>) {
      emit(MisPagosSuscripcionLoaded(pagos: result.data));
    } else if (result is Error<List<PagoSuscripcion>>) {
      emit(MisPagosSuscripcionError(result.message));
    }
  }

  Future<void> reload() async {
    await loadPagos();
  }
}
