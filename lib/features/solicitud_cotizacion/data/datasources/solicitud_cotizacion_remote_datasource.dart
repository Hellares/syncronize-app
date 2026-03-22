import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/solicitud_cotizacion_model.dart';

/// Data source remoto para operaciones de solicitudes de cotizacion
@lazySingleton
class SolicitudCotizacionRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/marketplace/solicitudes-cotizacion';

  SolicitudCotizacionRemoteDataSource(this._dioClient);

  /// POST /marketplace/solicitudes-cotizacion
  Future<SolicitudCotizacionModel> crearSolicitud(
      Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      _basePath,
      data: data,
    );
    return SolicitudCotizacionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// GET /marketplace/solicitudes-cotizacion
  Future<List<SolicitudCotizacionModel>> getMisSolicitudes() async {
    final response = await _dioClient.get(_basePath);

    final data = response.data as List;
    return data
        .map((e) =>
            SolicitudCotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/solicitudes-cotizacion/:id
  Future<SolicitudCotizacionModel> getSolicitudDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return SolicitudCotizacionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// POST /marketplace/solicitudes-cotizacion/:id/cancelar
  Future<void> cancelarSolicitud(String id) async {
    await _dioClient.post('$_basePath/$id/cancelar');
  }

  /// GET /marketplace/solicitudes-cotizacion/items-previos/:empresaId
  Future<List<Map<String, dynamic>>> getItemsPrevios(String empresaId) async {
    final response = await _dioClient.get('$_basePath/items-previos/$empresaId');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
