import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/consulta_ruc.dart';
import '../../domain/usecases/consultar_ruc_usecase.dart';

part 'consulta_ruc_state.dart';

@injectable
class ConsultaRucCubit extends Cubit<ConsultaRucState> {
  final ConsultarRucUseCase _consultarRucUseCase;

  ConsultaRucCubit(this._consultarRucUseCase)
      : super(const ConsultaRucState());

  Future<void> consultarRuc(String ruc) async {
    if (ruc.length != 11) return;

    emit(state.copyWith(
      status: ConsultaRucStatus.loading,
      clearData: true,
      clearError: true,
    ));

    final result = await _consultarRucUseCase(ruc);

    if (result is Success<ConsultaRuc>) {
      final data = result.data;
      if (data.esHabido) {
        emit(state.copyWith(
          status: ConsultaRucStatus.success,
          data: data,
        ));
      } else {
        emit(state.copyWith(
          status: ConsultaRucStatus.condicionInvalida,
          data: data,
          errorMessage:
              'La empresa tiene condición "${data.condicion}". Solo se permiten empresas con condición HABIDO.',
        ));
      }
    } else if (result is Error<ConsultaRuc>) {
      emit(state.copyWith(
        status: ConsultaRucStatus.error,
        errorMessage: result.message,
      ));
    }
  }

  void reset() {
    emit(const ConsultaRucState());
  }
}
