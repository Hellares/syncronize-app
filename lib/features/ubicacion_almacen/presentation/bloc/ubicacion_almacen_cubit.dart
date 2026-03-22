import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/ubicacion_almacen_remote_datasource.dart';
import 'ubicacion_almacen_state.dart';

@injectable
class UbicacionAlmacenCubit extends Cubit<UbicacionAlmacenState> {
  final UbicacionAlmacenRemoteDataSource _dataSource;

  String? _currentSedeId;

  UbicacionAlmacenCubit(this._dataSource)
      : super(const UbicacionAlmacenInitial());

  Future<void> loadUbicaciones(String sedeId, {String? tipo, String? parentId, String? search}) async {
    _currentSedeId = sedeId;
    emit(const UbicacionAlmacenLoading());

    try {
      final ubicaciones = await _dataSource.getUbicaciones(
        sedeId,
        tipo: tipo,
        parentId: parentId,
        search: search,
      );
      if (isClosed) return;
      emit(UbicacionAlmacenLoaded(ubicaciones: ubicaciones));
    } catch (e) {
      if (isClosed) return;
      emit(UbicacionAlmacenError(_parseError(e)));
    }
  }

  Future<void> crear(String sedeId, Map<String, dynamic> data) async {
    try {
      await _dataSource.crear(sedeId, data);
      if (isClosed) return;
      await loadUbicaciones(sedeId);
    } catch (e) {
      if (isClosed) return;
      emit(UbicacionAlmacenError(_parseError(e)));
    }
  }

  Future<void> actualizar(String id, Map<String, dynamic> data) async {
    try {
      await _dataSource.actualizar(id, data);
      if (isClosed) return;
      if (_currentSedeId != null) {
        await loadUbicaciones(_currentSedeId!);
      }
    } catch (e) {
      if (isClosed) return;
      emit(UbicacionAlmacenError(_parseError(e)));
    }
  }

  Future<void> desactivar(String id) async {
    try {
      await _dataSource.desactivar(id);
      if (isClosed) return;
      if (_currentSedeId != null) {
        await loadUbicaciones(_currentSedeId!);
      }
    } catch (e) {
      if (isClosed) return;
      emit(UbicacionAlmacenError(_parseError(e)));
    }
  }

  Future<void> reload() async {
    if (_currentSedeId != null) {
      await loadUbicaciones(_currentSedeId!);
    }
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('DioException')) {
        return 'Error de conexion al servidor';
      }
      return msg.replaceAll('Exception: ', '');
    }
    return 'Error inesperado';
  }
}
