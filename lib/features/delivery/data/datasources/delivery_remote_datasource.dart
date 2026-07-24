import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/delivery_local_model.dart';

@lazySingleton
class DeliveryRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/delivery-local';

  DeliveryRemoteDataSource(this._dioClient);

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
}
