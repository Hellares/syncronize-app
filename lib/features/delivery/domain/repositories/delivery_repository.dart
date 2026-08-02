import '../../../../core/utils/resource.dart';
import '../entities/delivery_local.dart';

abstract class DeliveryRepository {
  Future<Resource<DeliveryLocal>> solicitar(Map<String, dynamic> data);

  /// Edita la dirección de entrega (staff): dirección equivocada o el
  /// cliente pidió otro punto. El backend avisa al repartidor si ya tomó.
  Future<Resource<DeliveryLocal>> actualizarDireccion(
    String deliveryId,
    Map<String, dynamic> data,
  );

  /// Comparte la ubicación de entrega por WhatsApp de la empresa a
  /// cualquier celular (empleado, familiar…) — sin salir del app.
  Future<Resource<void>> compartirUbicacion(
    String deliveryId,
    String empresaId,
    String celular,
  );

  /// Delivery INTERNO: transiciones del staff (sin pool, sin PIN).
  Future<Resource<DeliveryLocal>> enCaminoInterno(
    String deliveryId,
    String empresaId,
  );

  Future<Resource<DeliveryLocal>> entregadoInterno(
    String deliveryId,
    String empresaId,
  );

  Future<Resource<List<DeliveryLocal>>> getDisponibles(
    String empresaId, {
    String? sedeId,
  });

  Future<Resource<List<DeliveryLocal>>> getMisEntregas(String empresaId);

  Future<Resource<DeliveryLocal>> tomar(String id, String empresaId);

  Future<Resource<DeliveryLocal>> marcarEnCamino(String id, String empresaId);

  Future<Resource<DeliveryLocal>> marcarEntregado(
    String id,
    String empresaId, {
    String? pin,
  });

  // ── Pool externo (freelance) ──

  Future<Resource<List<DeliveryLocal>>> getExternoDisponibles();

  Future<Resource<List<DeliveryLocal>>> getExternoMisEntregas();

  Future<Resource<DeliveryLocal>> tomarExterno(String id);

  /// Precio de referencia de una zona según su historial de ofertas.
  Future<Resource<TarifaSugerida>> tarifaSugerida(String distrito);

  /// Subasta: propongo mi precio para un pedido en `modoOferta`.
  Future<Resource<void>> ofertar(
    String deliveryId,
    String empresaId,
    double monto, {
    String? comentario,
  });

  Future<Resource<void>> retirarOferta(String deliveryId);

  /// Ofertas vigentes de un pedido (staff), de la más barata a la más cara.
  Future<Resource<List<Map<String, dynamic>>>> ofertasDe(
    String deliveryId,
    String empresaId,
  );

  Future<Resource<DeliveryLocal>> aceptarOferta(
    String ofertaId,
    String empresaId,
  );
}
