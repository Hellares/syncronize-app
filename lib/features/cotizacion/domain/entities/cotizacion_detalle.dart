import 'package:equatable/equatable.dart';

/// Entity que representa un item/linea de una cotizacion
class CotizacionDetalle extends Equatable {
  final String id;
  final String cotizacionId;
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;

  /// Precio unitario REGULAR (antes del nivel por mayor / precio VIP).
  /// Null cuando la línea se cotizó a precio normal.
  final double? precioRegular;

  /// Precio normal de sede antes de la OFERTA pública vigente al cotizar.
  /// Informativo (chip "En oferta — antes S/X"): la oferta es precio
  /// público y NO cuenta como descuento de la cotización.
  final double? precioAntesOferta;

  /// Estado de la reserva de stock del item: ACTIVA (apartado), LIBERADA
  /// (anulada/vencida o EXCLUIDO al convertir a venta), CONVERTIDA (vendido).
  /// Null = el item nunca reservó stock.
  final String? reservaEstado;
  final String tipoAfectacion;
  final double porcentajeIGV;
  final double igv;
  final double icbper;
  final double subtotal;
  final double total;
  final int orden;

  // Datos del producto/variante/servicio (snapshot)
  final String? productoNombre;
  final String? productoCodigo;
  final String? varianteNombre;
  final String? varianteSku;
  final String? servicioNombre;
  final String? servicioCodigo;

  const CotizacionDetalle({
    required this.id,
    required this.cotizacionId,
    this.productoId,
    this.varianteId,
    this.servicioId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.precioRegular,
    this.precioAntesOferta,
    this.reservaEstado,
    this.tipoAfectacion = '10',
    this.porcentajeIGV = 18,
    this.igv = 0,
    this.icbper = 0,
    required this.subtotal,
    required this.total,
    this.orden = 0,
    this.productoNombre,
    this.productoCodigo,
    this.varianteNombre,
    this.varianteSku,
    this.servicioNombre,
    this.servicioCodigo,
  });

  /// Tipo de item: producto, variante o servicio
  String get tipoItem {
    if (servicioId != null) return 'servicio';
    if (varianteId != null) return 'variante';
    if (productoId != null) return 'producto';
    return 'personalizado';
  }

  @override
  List<Object?> get props => [
        id,
        cotizacionId,
        productoId,
        varianteId,
        servicioId,
        descripcion,
        cantidad,
        precioUnitario,
        descuento,
        precioRegular,
        tipoAfectacion,
        porcentajeIGV,
        igv,
        icbper,
        subtotal,
        total,
        orden,
      ];
}
