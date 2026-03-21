import '../../../../core/utils/resource.dart';
import '../entities/checkout.dart';

abstract class CheckoutRepository {
  Future<Resource<OpcionesEnvio>> getOpcionesEnvio({required String empresaId});

  Future<Resource<CheckoutResult>> confirmarPedido({
    required String metodoPago,
    String? direccionEnvioId,
    String? notasComprador,
    required List<Map<String, dynamic>> entregaPorEmpresa,
  });
}
