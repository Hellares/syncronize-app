import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/flujo_proyectado.dart';
import '../../domain/usecases/get_flujo_proyectado_usecase.dart';
import 'flujo_proyectado_state.dart';

@injectable
class FlujoProyectadoCubit extends Cubit<FlujoProyectadoState> {
  final GetFlujoProyectadoUseCase _getFlujoProyectadoUseCase;

  FlujoProyectadoCubit(this._getFlujoProyectadoUseCase)
      : super(const FlujoProyectadoInitial());

  Future<void> loadProyeccion({int? meses}) async {
    emit(const FlujoProyectadoLoading());

    final result = await _getFlujoProyectadoUseCase(meses: meses);
    if (isClosed) return;

    if (result is Success<List<PeriodoFlujo>>) {
      emit(FlujoProyectadoLoaded(periodos: result.data));
    } else if (result is Error<List<PeriodoFlujo>>) {
      emit(FlujoProyectadoError(result.message));
    }
  }
}
