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

  /// Edita la dirección de entrega (staff). Si el delivery ya fue tomado o
  /// va en camino, el backend avisa al repartidor por push.
  Future<DeliveryLocalModel> actualizarDireccion(
    String deliveryId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.patch(
      '$_basePath/$deliveryId/direccion',
      data: data,
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Comparte la ubicación de entrega por WhatsApp (instancia de la
  /// empresa) a cualquier celular — pin nativo + texto, sin salir del app.
  Future<void> compartirUbicacion(
    String deliveryId,
    String empresaId,
    String celular,
  ) async {
    await _dioClient.post(
      '$_basePath/$deliveryId/compartir-ubicacion',
      data: {'empresaId': empresaId, 'celular': celular},
    );
  }

  /// Delivery INTERNO: el empleado salió con el pedido (staff marca).
  Future<DeliveryLocalModel> enCaminoInterno(
    String deliveryId,
    String empresaId,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/$deliveryId/interno/en-camino',
      data: {'empresaId': empresaId},
    );
    return DeliveryLocalModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delivery INTERNO: el empleado entregó (staff marca, sin PIN).
  Future<DeliveryLocalModel> entregadoInterno(
    String deliveryId,
    String empresaId,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/$deliveryId/interno/entregado',
      data: {'empresaId': empresaId},
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

  /// Entregar exige el PIN que el cliente recibió (prueba de entrega).
  Future<DeliveryLocalModel> marcarEntregado(
    String id,
    String empresaId, {
    String? pin,
  }) async {
    final response = await _dioClient.post(
      '$_basePath/$id/entregado',
      data: {
        'empresaId': empresaId,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
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

  /// Subasta: propone mi precio. Re-ofertar pisa la anterior.
  Future<void> ofertar(
    String deliveryId,
    String empresaId,
    double monto, {
    String? comentario,
  }) async {
    await _dioClient.post('$_basePath/ofertas/$deliveryId', data: {
      'empresaId': empresaId,
      'monto': monto,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    });
  }

  Future<void> retirarOferta(String deliveryId) async {
    await _dioClient.delete('$_basePath/ofertas/$deliveryId');
  }

  /// Ofertas vigentes de un pedido (staff), de la más barata a la más cara.
  Future<List<Map<String, dynamic>>> ofertasDe(
    String deliveryId,
    String empresaId,
  ) async {
    final r = await _dioClient.get(
      '$_basePath/$deliveryId/ofertas',
      queryParameters: {'empresaId': empresaId},
    );
    return (r.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<DeliveryLocalModel> aceptarOferta(
    String ofertaId,
    String empresaId,
  ) async {
    final r = await _dioClient.post(
      '$_basePath/ofertas/$ofertaId/aceptar',
      data: {'empresaId': empresaId},
    );
    return DeliveryLocalModel.fromJson(r.data as Map<String, dynamic>);
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
