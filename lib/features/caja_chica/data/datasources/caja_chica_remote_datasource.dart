import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/caja_chica_model.dart';
import '../models/gasto_caja_chica_model.dart';
import '../models/rendicion_caja_chica_model.dart';

@lazySingleton
class CajaChicaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/caja-chica';

  CajaChicaRemoteDataSource(this._dioClient);

  Future<CajaChicaModel> crearCajaChica({
    required String sedeId,
    required String nombre,
    required double fondoFijo,
    double? umbralAlerta,
    required String responsableId,
  }) async {
    final data = <String, dynamic>{
      'sedeId': sedeId,
      'nombre': nombre,
      'fondoFijo': fondoFijo,
      'responsableId': responsableId,
    };
    if (umbralAlerta != null) {
      data['umbralAlerta'] = umbralAlerta;
    }

    final response = await _dioClient.post(_basePath, data: data);
    return CajaChicaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CajaChicaModel>> listarCajasChicas({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) => CajaChicaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CajaChicaModel> getCajaChica(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return CajaChicaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> actualizarEstado({
    required String id,
    required String estado,
  }) async {
    await _dioClient.patch(
      '$_basePath/$id/estado',
      data: {'estado': estado},
    );
  }

  Future<GastoCajaChicaModel> registrarGasto({
    required String cajaChicaId,
    required double monto,
    required String descripcion,
    required String categoriaGastoId,
    String? comprobanteUrl,
  }) async {
    final data = <String, dynamic>{
      'monto': monto,
      'descripcion': descripcion,
      'categoriaGastoId': categoriaGastoId,
    };
    if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) {
      data['comprobanteUrl'] = comprobanteUrl;
    }

    final response = await _dioClient.post(
      '$_basePath/$cajaChicaId/gastos',
      data: data,
    );
    return GastoCajaChicaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<GastoCajaChicaModel>> listarGastos({
    required String cajaChicaId,
    bool? pendientes,
  }) async {
    final queryParams = <String, dynamic>{};
    if (pendientes != null) queryParams['pendientes'] = pendientes;

    final response = await _dioClient.get(
      '$_basePath/$cajaChicaId/gastos',
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) => GastoCajaChicaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RendicionCajaChicaModel> crearRendicion({
    required String cajaChicaId,
    required List<String> gastoIds,
    String? observaciones,
  }) async {
    final data = <String, dynamic>{
      'gastoIds': gastoIds,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      data['observaciones'] = observaciones;
    }

    final response = await _dioClient.post(
      '$_basePath/$cajaChicaId/rendiciones',
      data: data,
    );
    return RendicionCajaChicaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<RendicionCajaChicaModel>> listarRendiciones({
    String? cajaChicaId,
    String? estado,
  }) async {
    final queryParams = <String, dynamic>{};
    if (cajaChicaId != null) queryParams['cajaChicaId'] = cajaChicaId;
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dioClient.get(
      '$_basePath/rendiciones/lista',
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) =>
            RendicionCajaChicaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RendicionCajaChicaModel> getRendicion(String rendicionId) async {
    final response =
        await _dioClient.get('$_basePath/rendiciones/$rendicionId');
    return RendicionCajaChicaModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> aprobarRendicion({
    required String rendicionId,
    String? observaciones,
  }) async {
    final data = <String, dynamic>{};
    if (observaciones != null && observaciones.isNotEmpty) {
      data['observaciones'] = observaciones;
    }

    await _dioClient.post(
      '$_basePath/rendiciones/$rendicionId/aprobar',
      data: data,
    );
  }

  Future<void> rechazarRendicion({
    required String rendicionId,
    required String observaciones,
  }) async {
    await _dioClient.post(
      '$_basePath/rendiciones/$rendicionId/rechazar',
      data: {'observaciones': observaciones},
    );
  }
}
