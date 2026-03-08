import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/aviso_mantenimiento.dart';
import '../../domain/repositories/aviso_mantenimiento_repository.dart';
import '../datasources/aviso_mantenimiento_remote_datasource.dart';
import '../models/aviso_mantenimiento_model.dart';

@LazySingleton(as: AvisoMantenimientoRepository)
class AvisoMantenimientoRepositoryImpl implements AvisoMantenimientoRepository {
  final AvisoMantenimientoRemoteDataSource _dataSource;

  AvisoMantenimientoRepositoryImpl(this._dataSource);

  @override
  Future<Resource<List<AvisoMantenimiento>>> getAvisos({
    String? estado,
    String? clienteId,
    String? tipoServicio,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dataSource.getAvisos(
        estado: estado,
        clienteId: clienteId,
        tipoServicio: tipoServicio,
        cursor: cursor,
        limit: limit,
      );
      final items = (response['data'] as List)
          .map((e) => AvisoMantenimientoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      return Error('Error al obtener avisos: $e');
    }
  }

  @override
  Future<Resource<AvisoMantenimiento>> getAviso(String id) async {
    try {
      final aviso = await _dataSource.getAviso(id);
      return Success(aviso);
    } catch (e) {
      return Error('Error al obtener aviso: $e');
    }
  }

  @override
  Future<Resource<AvisoMantenimiento>> updateEstado(
    String id, {
    required String nuevoEstado,
    String? notas,
  }) async {
    try {
      final aviso = await _dataSource.updateEstado(
        id,
        nuevoEstado: nuevoEstado,
        notas: notas,
      );
      return Success(aviso);
    } catch (e) {
      return Error('Error al actualizar estado: $e');
    }
  }

  @override
  Future<Resource<ConfiguracionAvisoMantenimiento>> getConfiguracion() async {
    try {
      final config = await _dataSource.getConfiguracion();
      return Success(config);
    } catch (e) {
      return Error('Error al obtener configuración: $e');
    }
  }

  @override
  Future<Resource<ConfiguracionAvisoMantenimiento>> updateConfiguracion({
    Map<String, int>? intervalos,
    int? diasAnticipacion,
    bool? habilitado,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (intervalos != null) data['intervalos'] = intervalos;
      if (diasAnticipacion != null) data['diasAnticipacion'] = diasAnticipacion;
      if (habilitado != null) data['habilitado'] = habilitado;

      final config = await _dataSource.updateConfiguracion(data);
      return Success(config);
    } catch (e) {
      return Error('Error al actualizar configuración: $e');
    }
  }

  @override
  Future<Resource<AvisoResumen>> getResumen() async {
    try {
      final resumen = await _dataSource.getResumen();
      return Success(resumen);
    } catch (e) {
      return Error('Error al obtener resumen: $e');
    }
  }
}
