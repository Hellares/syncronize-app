import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/aviso_mantenimiento.dart';
import '../../../domain/usecases/get_avisos_usecase.dart';
import '../../../domain/usecases/get_aviso_resumen_usecase.dart';
import '../../../domain/usecases/update_estado_aviso_usecase.dart';
import 'aviso_list_state.dart';

@injectable
class AvisoListCubit extends Cubit<AvisoListState> {
  final GetAvisosUseCase _getAvisosUseCase;
  final GetAvisoResumenUseCase _getResumenUseCase;
  final UpdateEstadoAvisoUseCase _updateEstadoUseCase;

  AvisoListCubit(
    this._getAvisosUseCase,
    this._getResumenUseCase,
    this._updateEstadoUseCase,
  ) : super(const AvisoListInitial());

  String? _filtroEstado;

  Future<void> loadAvisos({String? estado}) async {
    _filtroEstado = estado;
    emit(const AvisoListLoading());

    final results = await Future.wait([
      _getAvisosUseCase(estado: _filtroEstado),
      _getResumenUseCase(),
    ]);

    if (isClosed) return;

    final avisosResult = results[0] as Resource<List<AvisoMantenimiento>>;
    final resumenResult = results[1] as Resource<AvisoResumen>;

    if (avisosResult is Success<List<AvisoMantenimiento>>) {
      emit(AvisoListLoaded(
        avisos: avisosResult.data,
        resumen: resumenResult is Success<AvisoResumen>
            ? resumenResult.data
            : null,
        filtroEstado: _filtroEstado,
      ));
    } else if (avisosResult is Error<List<AvisoMantenimiento>>) {
      emit(AvisoListError(avisosResult.message));
    }
  }

  Future<void> filterByEstado(String? estado) async {
    await loadAvisos(estado: estado);
  }

  Future<bool> updateEstado(String avisoId, String nuevoEstado, {String? notas}) async {
    final result = await _updateEstadoUseCase(
      avisoId,
      nuevoEstado: nuevoEstado,
      notas: notas,
    );

    if (result is Success) {
      await loadAvisos(estado: _filtroEstado);
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    await loadAvisos(estado: _filtroEstado);
  }
}
