import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';

/// Sincroniza la config de impresoras del dispositivo con el backend
/// (POST /impresoras-dispositivo/:deviceId). Auth + x-tenant-id los agrega
/// el interceptor automáticamente.
@lazySingleton
class ImpresorasRemoteDataSource {
  final DioClient _dio;
  static const _base = '/impresoras-dispositivo';

  ImpresorasRemoteDataSource(this._dio);

  /// Lista de configs guardada en el servidor para este dispositivo (o vacía).
  Future<List<Map<String, dynamic>>> obtener(String deviceId) async {
    final res = await _dio.get('$_base/$deviceId');
    final data = res.data as Map<String, dynamic>?;
    final config = data?['config'] as List<dynamic>? ?? [];
    return config.cast<Map<String, dynamic>>();
  }

  /// Reemplaza en el servidor la lista de impresoras del dispositivo.
  Future<void> guardar(String deviceId, List<Map<String, dynamic>> config) async {
    await _dio.put('$_base/$deviceId', data: {'config': config});
  }
}
