import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/solicitud_empresa_remote_datasource.dart';

abstract class SolicitudEmpresaActionState {}

class SolicitudEmpresaActionInitial extends SolicitudEmpresaActionState {}

class SolicitudEmpresaActionLoading extends SolicitudEmpresaActionState {}

class SolicitudEmpresaDetailLoaded extends SolicitudEmpresaActionState {
  final Map<String, dynamic> solicitud;
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
class SolicitudEmpresaActionCubit extends Cubit<SolicitudEmpresaActionState> {
  final SolicitudEmpresaRemoteDataSource _dataSource;

  SolicitudEmpresaActionCubit(this._dataSource) : super(SolicitudEmpresaActionInitial());

  Future<void> loadDetalle(String id) async {
    emit(SolicitudEmpresaActionLoading());
    try {
      final data = await _dataSource.detalle(id);
      emit(SolicitudEmpresaDetailLoaded(data));
    } catch (e) {
      emit(SolicitudEmpresaActionError(e.toString()));
    }
  }

  Future<void> rechazar(String id, String motivo) async {
    emit(SolicitudEmpresaActionLoading());
    try {
      await _dataSource.rechazar(id, motivo);
      emit(SolicitudEmpresaActionSuccess('Solicitud rechazada'));
    } catch (e) {
      emit(SolicitudEmpresaActionError(e.toString()));
    }
  }

  Future<void> vincularCotizacion(String id, String cotizacionId) async {
    emit(SolicitudEmpresaActionLoading());
    try {
      await _dataSource.cotizar(id, cotizacionId);
      emit(SolicitudEmpresaActionSuccess('Cotización vinculada'));
    } catch (e) {
      emit(SolicitudEmpresaActionError(e.toString()));
    }
  }
}
