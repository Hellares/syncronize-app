import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/aviso_mantenimiento_model.dart';

@lazySingleton
class AvisoMantenimientoRemoteDataSource {
  final DioClient _dioClient;

  AvisoMantenimientoRemoteDataSource(this._dioClient);

  static const _base = ApiConstants.avisosMantenimiento;

  Future<Map<String, dynamic>> getAvisos({
    String? estado,
    String? clienteId,
    String? tipoServicio,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (estado != null) params['estado'] = estado;
    if (clienteId != null) params['clienteId'] = clienteId;
    if (tipoServicio != null) params['tipoServicio'] = tipoServicio;
    if (cursor != null) params['cursor'] = cursor;

    final response = await _dioClient.get(_base, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<AvisoMantenimientoModel> getAviso(String id) async {
    final response = await _dioClient.get('$_base/$id');
    return AvisoMantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AvisoMantenimientoModel> updateEstado(
    String id, {
    required String nuevoEstado,
    String? notas,
  }) async {
    final data = <String, dynamic>{'nuevoEstado': nuevoEstado};
    if (notas != null) data['notas'] = notas;

    final response = await _dioClient.patch('$_base/$id/estado', data: data);
    return AvisoMantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConfiguracionAvisoModel> getConfiguracion() async {
    final response = await _dioClient.get('$_base/configuracion');
    return ConfiguracionAvisoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConfiguracionAvisoModel> updateConfiguracion(Map<String, dynamic> data) async {
    final response = await _dioClient.put('$_base/configuracion', data: data);
    return ConfiguracionAvisoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AvisoResumenModel> getResumen() async {
    final response = await _dioClient.get('$_base/resumen');
    return AvisoResumenModel.fromJson(response.data as Map<String, dynamic>);
  }
}
