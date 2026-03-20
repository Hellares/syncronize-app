import 'dart:io';
import '../../../../core/utils/resource.dart';
import '../entities/pedido_marketplace.dart';

/// Repository interface para operaciones de pedidos del marketplace
abstract class MisPedidosRepository {
  /// Obtiene la lista de pedidos del comprador, opcionalmente filtrada por estado
  Future<Resource<List<PedidoMarketplace>>> getMisPedidos({
    EstadoPedidoMarketplace? estado,
  });

  /// Obtiene el detalle de un pedido especifico
  Future<Resource<PedidoMarketplace>> getMiPedidoDetalle(String id);

  /// Sube comprobante de pago para un pedido. Retorna la URL del comprobante.
  Future<Resource<String>> subirComprobante(String pedidoId, File file);

  /// Cancela un pedido (solo si esta en estado PENDIENTE_PAGO)
  Future<Resource<void>> cancelarPedido(String pedidoId);

  /// Confirma la recepcion de un pedido (solo si esta en estado ENVIADO)
  Future<Resource<void>> confirmarRecepcion(String pedidoId);
}
