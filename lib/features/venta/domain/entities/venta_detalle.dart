import 'package:equatable/equatable.dart';

/// Entity que representa un item/linea de una venta
class VentaDetalle extends Equatable {
  final String id;
  final String ventaId;
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String? comboId;
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

  const VentaDetalle({
    required this.id,
    required this.ventaId,
    this.productoId,
    this.varianteId,
    this.servicioId,
    this.comboId,
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

  String get tipoItem {
    if (servicioId != null) return 'servicio';
    if (comboId != null) return 'combo';
    if (varianteId != null) return 'variante';
    if (productoId != null) return 'producto';
    return 'personalizado';
  }

  @override
  List<Object?> get props => [
        id,
        ventaId,
        productoId,
        varianteId,
        servicioId,
        comboId,
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
