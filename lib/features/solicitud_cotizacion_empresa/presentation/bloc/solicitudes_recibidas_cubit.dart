import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_empresa.dart';
import '../../domain/usecases/get_solicitudes_recibidas_usecase.dart';

abstract class SolicitudesRecibidasState {}

class SolicitudesRecibidasInitial extends SolicitudesRecibidasState {}

class SolicitudesRecibidasLoading extends SolicitudesRecibidasState {}

class SolicitudesRecibidasLoaded extends SolicitudesRecibidasState {
  final List<SolicitudRecibida> solicitudes;
  SolicitudesRecibidasLoaded(this.solicitudes);
}

class SolicitudesRecibidasError extends SolicitudesRecibidasState {
  final String message;
  SolicitudesRecibidasError(this.message);
}

@injectable
class SolicitudesRecibidasCubit extends Cubit<SolicitudesRecibidasState> {
  final GetSolicitudesRecibidasUseCase _getSolicitudesRecibidas;
  String? _filtroEstado;

  SolicitudesRecibidasCubit(this._getSolicitudesRecibidas)
      : super(SolicitudesRecibidasInitial());

  Future<void> load({String? estado}) async {
    _filtroEstado = estado;
    emit(SolicitudesRecibidasLoading());
    final result = await _getSolicitudesRecibidas(estado: estado);
    if (result is Success<List<SolicitudRecibida>>) {
      emit(SolicitudesRecibidasLoaded(result.data));
    } else if (result is Error<List<SolicitudRecibida>>) {
      emit(SolicitudesRecibidasError(result.message));
    }
  }

  Future<void> reload() => load(estado: _filtroEstado);
}
