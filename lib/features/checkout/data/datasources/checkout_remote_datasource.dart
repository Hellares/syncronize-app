import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/checkout_model.dart';

@lazySingleton
class CheckoutRemoteDataSource {
  final DioClient _dioClient;

  CheckoutRemoteDataSource(this._dioClient);

  Future<OpcionesEnvioModel> getOpcionesEnvio({required String empresaId}) async {
    final response = await _dioClient.get('/marketplace/carrito/opciones-envio/$empresaId');
    return OpcionesEnvioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CheckoutResultModel> confirmarPedido({
    required String metodoPago,
    String? direccionEnvioId,
    String? notasComprador,
    required List<Map<String, dynamic>> entregaPorEmpresa,
  }) async {
    final data = <String, dynamic>{
      'metodoPago': metodoPago,
      'entregaPorEmpresa': entregaPorEmpresa,
    };
    if (direccionEnvioId != null) data['direccionEnvioId'] = direccionEnvioId;
    if (notasComprador != null && notasComprador.isNotEmpty) {
      data['notasComprador'] = notasComprador;
    }

    final response = await _dioClient.post('/marketplace/checkout', data: data);
    return CheckoutResultModel.fromJson(response.data as Map<String, dynamic>);
  }
}
