import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pedido_marketplace_model.dart';

@lazySingleton
class MisPedidosRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/marketplace/mis-pedidos';

  MisPedidosRemoteDataSource(this._dioClient);

  /// GET /marketplace/mis-pedidos
  Future<List<PedidoMarketplaceModel>> getMisPedidos({
    String? estado,
  }) async {
    final queryParams = <String, dynamic>{};
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    // Soporta respuesta paginada {data: [...]} o lista directa [...]
    final responseData = response.data;
    final List items;
    if (responseData is Map && responseData['data'] is List) {
      items = responseData['data'] as List;
    } else if (responseData is List) {
      items = responseData;
    } else {
      items = [];
    }
    return items
        .map((e) => PedidoMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/mis-pedidos/:id
  Future<PedidoMarketplaceModel> getMiPedidoDetalle(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return PedidoMarketplaceModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /marketplace/mis-pedidos/:id/comprobante (multipart)
  Future<String> subirComprobante(String pedidoId, File file) async {
    final fileName = file.path.split('/').last.isNotEmpty
        ? file.path.split('/').last
        : file.path.split('\\').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dioClient.post(
      '$_basePath/$pedidoId/comprobante-pago',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    // La API puede retornar la URL directamente o dentro de un objeto
    final responseData = response.data;
    if (responseData is String) return responseData;
    if (responseData is Map) {
      return responseData['comprobantePagoUrl'] as String? ??
          responseData['url'] as String? ??
          '';
    }
    return '';
  }

  /// POST /marketplace/mis-pedidos/:id/cancelar
  Future<void> cancelarPedido(String pedidoId) async {
    await _dioClient.post('$_basePath/$pedidoId/cancelar');
  }

  /// POST /marketplace/mis-pedidos/:id/confirmar-recepcion
  Future<void> confirmarRecepcion(String pedidoId) async {
    await _dioClient.post('$_basePath/$pedidoId/confirmar-recepcion');
  }
}
