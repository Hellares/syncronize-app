import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cotizacion/data/models/cotizacion_model.dart';

/// Datasource remoto del módulo cotización rápida.
///
/// Usa el mismo endpoint base `/cotizaciones` que el módulo compartido,
/// pero vive aquí para que la cadena clean del feature sea independiente.
/// Si el formato de POST/PUT diverge en el futuro (ej. payload mínimo
/// para POS), las llamadas se ajustan acá sin tocar al módulo viejo.
@lazySingleton
class CotizacionRapidaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/cotizaciones';

  CotizacionRapidaRemoteDataSource(this._dioClient);

  Future<CotizacionModel> crear(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CotizacionModel> actualizar(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put(
      '$_basePath/$cotizacionId',
      data: data,
    );
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CotizacionModel> obtener(String cotizacionId) async {
    final response = await _dioClient.get('$_basePath/$cotizacionId');
    return CotizacionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
