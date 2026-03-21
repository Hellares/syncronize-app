import '../../../../core/utils/resource.dart';
import '../entities/pedido_empresa.dart';

abstract class PedidoEmpresaRepository {
  Future<Resource<List<PedidoMarketplaceEmpresa>>> listarPedidos({
    String? estado,
    String? search,
  });

  Future<Resource<PedidoMarketplaceEmpresa>> detallePedido(String id);

  Future<Resource<void>> validarPago(
    String id, {
    required String accion,
    String? motivoRechazo,
  });

  Future<Resource<void>> cambiarEstado(
    String id, {
    required String estado,
    String? codigoSeguimiento,
  });

  Future<Resource<ResumenPedidos>> getResumen();
}
