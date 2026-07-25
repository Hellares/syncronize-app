import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/repositories/resumen_financiero_repository.dart';
import '../../domain/usecases/get_resumen_financiero_usecase.dart';
import '../../domain/usecases/get_grafico_diario_usecase.dart';
import 'resumen_financiero_state.dart';

@injectable
class ResumenFinancieroCubit extends Cubit<ResumenFinancieroState> {
  final GetResumenFinancieroUseCase _getResumenUseCase;
  // Ya no se usa (el endpoint consolidado trae también el gráfico), pero
  // se conserva el parámetro para NO tocar el constructor generado por
  // injectable (evita correr build_runner por este cambio).
  // ignore: unused_field
  final GetGraficoDiarioUseCase _getGraficoDiarioUseCase;

  ResumenFinancieroCubit(
    this._getResumenUseCase,
    this._getGraficoDiarioUseCase,
  ) : super(const ResumenFinancieroInitial());

  Future<void> loadResumen({
    String? fechaDesde,
    String? fechaHasta,
    String? sedeId,
  }) async {
    // Con datos ya cargados solo se marca refreshing: las cards los
    // mantienen visibles y se actualizan en sitio (sin flash de loading).
    final current = state;
    if (current is ResumenFinancieroLoaded) {
      emit(current.copyWith(refreshing: true));
    } else {
      emit(const ResumenFinancieroLoading());
    }

    // UN request consolidado: antes resumen + gráfico por separado (dos
    // round-trips móviles que además corren DESPUÉS del contexto).
    final result = await _getResumenUseCase.dashboard(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      sedeId: sedeId,
    );
    if (isClosed) return;

    if (result is Success<DashboardFinanciero>) {
      emit(ResumenFinancieroLoaded(
        resumen: result.data.resumen,
        grafico: result.data.grafico,
      ));
    } else if (result is Error<DashboardFinanciero>) {
      emit(ResumenFinancieroError(result.message));
    }
  }
}
