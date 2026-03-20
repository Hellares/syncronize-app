import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/solicitud_empresa_remote_datasource.dart';

abstract class SolicitudesRecibidasState {}

class SolicitudesRecibidasInitial extends SolicitudesRecibidasState {}

class SolicitudesRecibidasLoading extends SolicitudesRecibidasState {}

class SolicitudesRecibidasLoaded extends SolicitudesRecibidasState {
  final List<Map<String, dynamic>> solicitudes;
  SolicitudesRecibidasLoaded(this.solicitudes);
}

class SolicitudesRecibidasError extends SolicitudesRecibidasState {
  final String message;
  SolicitudesRecibidasError(this.message);
}

@injectable
class SolicitudesRecibidasCubit extends Cubit<SolicitudesRecibidasState> {
  final SolicitudEmpresaRemoteDataSource _dataSource;
  String? _filtroEstado;

  SolicitudesRecibidasCubit(this._dataSource) : super(SolicitudesRecibidasInitial());

  Future<void> load({String? estado}) async {
    _filtroEstado = estado;
    emit(SolicitudesRecibidasLoading());
    try {
      final data = await _dataSource.listar(estado: estado);
      emit(SolicitudesRecibidasLoaded(data));
    } catch (e) {
      emit(SolicitudesRecibidasError(e.toString()));
    }
  }

  Future<void> reload() => load(estado: _filtroEstado);
}
