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
  final double porcentajeIGV;
  final double igv;
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
    this.porcentajeIGV = 18,
    this.igv = 0,
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
        porcentajeIGV,
        igv,
        subtotal,
        total,
        orden,
      ];
}
