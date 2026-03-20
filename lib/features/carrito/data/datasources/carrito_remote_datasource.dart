import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/carrito_model.dart';

@lazySingleton
class CarritoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/marketplace/carrito';

  CarritoRemoteDataSource(this._dioClient);

  /// GET /marketplace/carrito
  Future<CarritoModel> getCarrito() async {
    final response = await _dioClient.get(_basePath);
    return CarritoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /marketplace/carrito/contador
  Future<CarritoContadorModel> getContador() async {
    final response = await _dioClient.get('$_basePath/contador');
    return CarritoContadorModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// POST /marketplace/carrito
  Future<CarritoModel> agregarItem({
    required String productoId,
    String? varianteId,
    int cantidad = 1,
  }) async {
    final body = <String, dynamic>{
      'productoId': productoId,
      'cantidad': cantidad,
    };
    if (varianteId != null) {
      body['varianteId'] = varianteId;
    }
    final response = await _dioClient.post(_basePath, data: body);
    return CarritoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /marketplace/carrito/:itemId
  Future<CarritoModel> actualizarCantidad({
    required String itemId,
    required int cantidad,
  }) async {
    final response = await _dioClient.put(
      '$_basePath/$itemId',
      data: {'cantidad': cantidad},
    );
    return CarritoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /marketplace/carrito/:itemId
  Future<CarritoModel> eliminarItem({required String itemId}) async {
    final response = await _dioClient.delete('$_basePath/$itemId');
    return CarritoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /marketplace/carrito
  Future<CarritoModel> vaciarCarrito() async {
    final response = await _dioClient.delete(_basePath);
    return CarritoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
