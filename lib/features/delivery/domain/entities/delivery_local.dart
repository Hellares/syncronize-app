import 'package:equatable/equatable.dart';

/// Un delivery local: venta YA PAGADA al 100% que un repartidor de la
/// empresa lleva al cliente. El repartidor cobra SOLO la tarifa de envío
/// ([costoDelivery]) al entregar — jamás el producto.
class DeliveryLocal extends Equatable {
  final String id;
  final String estado; // SOLICITADO | TOMADO | EN_CAMINO | ENTREGADO | CANCELADO
  final String? ventaCodigo;
  final String destinatarioNombre;
  final String? destinatarioCelular;
  final String direccion;
  final String? referencia;
  final String? distrito;
  final double costoDelivery;
  final DateTime? creadoEn;
  final DateTime? tomadoEn;
  final DateTime? enCaminoEn;
  final DateTime? entregadoEn;

  /// Coordenadas del destino (si el pedido las trae) — botón Navegar.
  final double? destinoLat;
  final double? destinoLon;

  const DeliveryLocal({
    required this.id,
    required this.estado,
    this.ventaCodigo,
    required this.destinatarioNombre,
    this.destinatarioCelular,
    required this.direccion,
    this.referencia,
    this.distrito,
    required this.costoDelivery,
    this.creadoEn,
    this.tomadoEn,
    this.enCaminoEn,
    this.entregadoEn,
    this.destinoLat,
    this.destinoLon,
  });

  /// Link de NAVEGACIÓN de Google Maps (turn-by-turn, gratis — deep link,
  /// no API): coordenadas si existen, si no la dirección en texto.
  String get urlNavegacion {
    if (destinoLat != null && destinoLon != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destinoLat,$destinoLon&travelmode=driving';
    }
    final consulta = Uri.encodeComponent(
      [direccion, distrito].where((s) => s != null && s.isNotEmpty).join(', '),
    );
    return 'https://www.google.com/maps/dir/?api=1&destination=$consulta&travelmode=driving';
  }

  bool get esSolicitado => estado == 'SOLICITADO';
  bool get esTomado => estado == 'TOMADO';
  bool get esEnCamino => estado == 'EN_CAMINO';
  bool get esEntregado => estado == 'ENTREGADO';
  bool get esCancelado => estado == 'CANCELADO';

  /// Sigue en manos del repartidor (muestra botón de acción).
  bool get esActivo => esTomado || esEnCamino;

  String get estadoLabel {
    switch (estado) {
      case 'SOLICITADO':
        return 'Disponible';
      case 'TOMADO':
        return 'Tomado';
      case 'EN_CAMINO':
        return 'En camino';
      case 'ENTREGADO':
        return 'Entregado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  @override
  List<Object?> get props => [id, estado, ventaCodigo, costoDelivery];
}
