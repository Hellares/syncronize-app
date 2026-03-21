import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empresa_banco.dart';
import '../../domain/usecases/get_conciliacion_usecase.dart';
import 'conciliacion_state.dart';

@injectable
class ConciliacionCubit extends Cubit<ConciliacionState> {
  final GetConciliacionUseCase _getConciliacionUseCase;

  ConciliacionCubit(this._getConciliacionUseCase) : super(const ConciliacionInitial());

  Future<void> getConciliacion({
    required String cuentaId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    emit(const ConciliacionLoading());

    final result = await _getConciliacionUseCase(
      cuentaId: cuentaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    if (isClosed) return;

    if (result is Success<ConciliacionBancaria>) {
      emit(ConciliacionLoaded(result.data));
    } else if (result is Error<ConciliacionBancaria>) {
      emit(ConciliacionError(result.message));
    }
  }
}
