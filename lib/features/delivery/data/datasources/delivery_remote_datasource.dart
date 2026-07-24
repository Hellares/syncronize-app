import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/delivery_local_model.dart';

@lazySingleton
class DeliveryRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/delivery-local';

  DeliveryRemoteDataSource(this._dioClient);

  /// Publica el delivery de una venta PAGADA al 100% (staff). El backend
  /// valida el pago, aplica la tarifa de la sede si no se manda costo y
  /// notifica a los repartidores por push.
  Future<DeliveryLocalModel> solicitar(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '$_basePath/solicitar',
      data: data,
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Pool de deliveries SOLICITADOS listos para tomar.
  Future<List<DeliveryLocalModel>> getDisponibles(
    String empresaId, {
    String? sedeId,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/disponibles',
      queryParameters: {
        'empresaId': empresaId,
        if (sedeId != null) 'sedeId': sedeId,
      },
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DeliveryLocalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Entregas del repartidor autenticado (activas + historial reciente).
  Future<List<DeliveryLocalModel>> getMisEntregas(String empresaId) async {
    final response = await _dioClient.get(
      '$_basePath/mis-entregas',
      queryParameters: {'empresaId': empresaId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DeliveryLocalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tomar un delivery (atómico en backend: el primero gana, el resto 409).
  Future<DeliveryLocalModel> tomar(String id, String empresaId) async {
    final response = await _dioClient.post(
      '$_basePath/$id/tomar',
      data: {'empresaId': empresaId},
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeliveryLocalModel> marcarEnCamino(String id, String empresaId) async {
    final response = await _dioClient.post(
      '$_basePath/$id/en-camino',
      data: {'empresaId': empresaId},
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeliveryLocalModel> marcarEntregado(
      String id, String empresaId) async {
    final response = await _dioClient.post(
      '$_basePath/$id/entregado',
      data: {'empresaId': empresaId},
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Pool EXTERNO (repartidor freelance de Syncronize) ──

  /// Pool cross-empresa del freelance: empresas con opt-in, en SUS zonas.
  Future<List<DeliveryLocalModel>> getExternoDisponibles() async {
    final response = await _dioClient.get('$_basePath/externo/disponibles');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DeliveryLocalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DeliveryLocalModel>> getExternoMisEntregas() async {
    final response = await _dioClient.get('$_basePath/externo/mis-entregas');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DeliveryLocalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeliveryLocalModel> tomarExterno(String id) async {
    final response = await _dioClient.post('$_basePath/$id/tomar-externo');
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GPS: posición del repartidor mientras va EN_CAMINO (best-effort, el
  /// backend ignora reportes tardíos o de no-dueños sin error).
  Future<void> reportarPosicion(
    String id,
    String empresaId,
    double lat,
    double lon,
  ) async {
    await _dioClient.post(
      '$_basePath/$id/posicion',
      data: {'empresaId': empresaId, 'lat': lat, 'lon': lon},
    );
  }
}
