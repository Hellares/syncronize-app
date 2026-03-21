import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/resumen_financiero.dart';
import '../../domain/usecases/get_resumen_financiero_usecase.dart';
import '../../domain/usecases/get_grafico_diario_usecase.dart';
import 'resumen_financiero_state.dart';

@injectable
class ResumenFinancieroCubit extends Cubit<ResumenFinancieroState> {
  final GetResumenFinancieroUseCase _getResumenUseCase;
  final GetGraficoDiarioUseCase _getGraficoDiarioUseCase;

  ResumenFinancieroCubit(
    this._getResumenUseCase,
    this._getGraficoDiarioUseCase,
  ) : super(const ResumenFinancieroInitial());

  Future<void> loadResumen({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    emit(const ResumenFinancieroLoading());

    final results = await Future.wait([
      _getResumenUseCase(fechaDesde: fechaDesde, fechaHasta: fechaHasta),
      _getGraficoDiarioUseCase(fechaDesde: fechaDesde, fechaHasta: fechaHasta),
    ]);
    if (isClosed) return;

    final resumenResult = results[0] as Resource<ResumenFinanciero>;
    final graficoResult = results[1] as Resource<GraficoDiario>;

    if (resumenResult is Success<ResumenFinanciero>) {
      GraficoDiario? grafico;
      if (graficoResult is Success<GraficoDiario>) {
        grafico = graficoResult.data;
      }
      emit(ResumenFinancieroLoaded(
        resumen: resumenResult.data,
        grafico: grafico,
      ));
    } else if (resumenResult is Error<ResumenFinanciero>) {
      emit(ResumenFinancieroError(resumenResult.message));
    }
  }
}
