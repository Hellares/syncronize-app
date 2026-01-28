import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/enviar_para_revision_usecase.dart';
import '../../../domain/usecases/aprobar_reporte_usecase.dart';
import '../../../domain/usecases/rechazar_reporte_usecase.dart';

part 'gestionar_reporte_state.dart';

@injectable
class GestionarReporteCubit extends Cubit<GestionarReporteState> {
  final EnviarParaRevisionUsecase _enviarParaRevisionUsecase;
  final AprobarReporteUsecase _aprobarReporteUsecase;
  final RechazarReporteUsecase _rechazarReporteUsecase;

  GestionarReporteCubit(
    this._enviarParaRevisionUsecase,
    this._aprobarReporteUsecase,
    this._rechazarReporteUsecase,
  ) : super(const GestionarReporteInitial());

  Future<void> enviarParaRevision(String reporteId) async {
    emit(const GestionarReporteLoading());

    final result = await _enviarParaRevisionUsecase(reporteId);

    if (isClosed) return;

    if (result is Success<ReporteIncidencia>) {
      emit(GestionarReporteSuccess(result.data, 'Reporte enviado para revisión'));
    } else if (result is Error<ReporteIncidencia>) {
      emit(GestionarReporteError(result.message));
    }
  }

  Future<void> aprobarReporte(String reporteId) async {
    emit(const GestionarReporteLoading());

    final result = await _aprobarReporteUsecase(reporteId);

    if (isClosed) return;

    if (result is Success<ReporteIncidencia>) {
      emit(GestionarReporteSuccess(result.data, 'Reporte aprobado exitosamente'));
    } else if (result is Error<ReporteIncidencia>) {
      emit(GestionarReporteError(result.message));
    }
  }

  Future<void> rechazarReporte(String reporteId, String? motivo) async {
    emit(const GestionarReporteLoading());

    final result = await _rechazarReporteUsecase(reporteId, motivo);

    if (isClosed) return;

    if (result is Success<ReporteIncidencia>) {
      emit(GestionarReporteSuccess(result.data, 'Reporte rechazado'));
    } else if (result is Error<ReporteIncidencia>) {
      emit(GestionarReporteError(result.message));
    }
  }
}
