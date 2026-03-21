import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_empresa.dart';
import '../../domain/usecases/cotizar_solicitud_usecase.dart';
import '../../domain/usecases/get_detalle_solicitud_usecase.dart';
import '../../domain/usecases/rechazar_solicitud_usecase.dart';

abstract class SolicitudEmpresaActionState {}

class SolicitudEmpresaActionInitial extends SolicitudEmpresaActionState {}

class SolicitudEmpresaActionLoading extends SolicitudEmpresaActionState {}

class SolicitudEmpresaDetailLoaded extends SolicitudEmpresaActionState {
  final SolicitudRecibida solicitud;
  SolicitudEmpresaDetailLoaded(this.solicitud);
}

class SolicitudEmpresaActionSuccess extends SolicitudEmpresaActionState {
  final String message;
  SolicitudEmpresaActionSuccess(this.message);
}

class SolicitudEmpresaActionError extends SolicitudEmpresaActionState {
  final String message;
  SolicitudEmpresaActionError(this.message);
}

@injectable
class SolicitudEmpresaActionCubit
    extends Cubit<SolicitudEmpresaActionState> {
  final GetDetalleSolicitudUseCase _getDetalleSolicitud;
  final RechazarSolicitudUseCase _rechazarSolicitud;
  final CotizarSolicitudUseCase _cotizarSolicitud;

  SolicitudEmpresaActionCubit(
    this._getDetalleSolicitud,
    this._rechazarSolicitud,
    this._cotizarSolicitud,
  ) : super(SolicitudEmpresaActionInitial());

  Future<void> loadDetalle(String id) async {
    emit(SolicitudEmpresaActionLoading());
    final result = await _getDetalleSolicitud(id);
    if (result is Success<SolicitudRecibida>) {
      emit(SolicitudEmpresaDetailLoaded(result.data));
    } else if (result is Error<SolicitudRecibida>) {
      emit(SolicitudEmpresaActionError(result.message));
    }
  }

  Future<void> rechazar(String id, String motivo) async {
    emit(SolicitudEmpresaActionLoading());
    final result = await _rechazarSolicitud(id, motivo);
    if (result is Success) {
      emit(SolicitudEmpresaActionSuccess('Solicitud rechazada'));
    } else if (result is Error) {
      emit(SolicitudEmpresaActionError((result).message));
    }
  }

  Future<void> vincularCotizacion(String id, String cotizacionId) async {
    emit(SolicitudEmpresaActionLoading());
    final result = await _cotizarSolicitud(id, cotizacionId);
    if (result is Success) {
      emit(SolicitudEmpresaActionSuccess('Cotizacion vinculada'));
    } else if (result is Error) {
      emit(SolicitudEmpresaActionError((result).message));
    }
  }
}
