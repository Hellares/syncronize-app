import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../../domain/usecases/get_mis_solicitudes_usecase.dart';
import '../../domain/usecases/cancelar_solicitud_usecase.dart';
import 'mis_solicitudes_state.dart';

@injectable
class MisSolicitudesCubit extends Cubit<MisSolicitudesState> {
  final GetMisSolicitudesUseCase _getMisSolicitudesUseCase;
  final CancelarSolicitudUseCase _cancelarSolicitudUseCase;

  MisSolicitudesCubit(
    this._getMisSolicitudesUseCase,
    this._cancelarSolicitudUseCase,
  ) : super(const MisSolicitudesInitial());

  EstadoSolicitudCotizacion? _filtroEstado;
  List<SolicitudCotizacion> _allSolicitudes = [];

  /// Carga la lista de solicitudes
  Future<void> loadSolicitudes() async {
    emit(const MisSolicitudesLoading());

    final result = await _getMisSolicitudesUseCase();
    if (isClosed) return;

    if (result is Success<List<SolicitudCotizacion>>) {
      _allSolicitudes = result.data;
      emit(MisSolicitudesLoaded(
        solicitudes: _allSolicitudes,
        filtroEstado: _filtroEstado,
      ));
    } else if (result is Error<List<SolicitudCotizacion>>) {
      emit(MisSolicitudesError(result.message));
    }
  }

  /// Filtra por estado
  void filterByEstado(EstadoSolicitudCotizacion? estado) {
    _filtroEstado = estado;
    if (_allSolicitudes.isNotEmpty) {
      emit(MisSolicitudesLoaded(
        solicitudes: _allSolicitudes,
        filtroEstado: _filtroEstado,
      ));
    }
  }

  /// Cancela una solicitud y recarga la lista
  Future<void> cancelarSolicitud(String solicitudId) async {
    final result =
        await _cancelarSolicitudUseCase(solicitudId: solicitudId);
    if (isClosed) return;

    if (result is Success) {
      await loadSolicitudes();
    } else if (result is Error) {
      emit(MisSolicitudesError((result).message));
    }
  }

  /// Recarga la lista
  Future<void> reload() async {
    await loadSolicitudes();
  }
}
