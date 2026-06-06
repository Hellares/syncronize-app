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

  // Trazabilidad de combo origen: cuando este detalle es un componente
  // que se vendió como parte de un combo expandido, estos campos lo
  // identifican. Null si se vendió suelto.
  final String? origenComboId;
  final String? origenComboNombre;

  /// Etiqueta del precio aplicado al vender (snapshot): nombre del nivel
  /// ("Por Mayor"), "Oferta" o "Liquidación". Null si fue precio base.
  final String? nivelAplicadoSnapshot;

  // Cobro de orden de servicio: esta línea representa el SALDO de una
  // orden (REPARADO/LISTO_ENTREGA). El desglose permite que el ticket
  // muestre el costo total del servicio, los adelantos previos (con su
  // método) y el saldo cobrado en esta venta.
  final String? ordenServicioId;
  final String? ordenCodigo;
  final double? ordenCostoTotal;
  final double? ordenAdelanto;
  final double? ordenDescuento;
  final String? ordenMetodoPagoAdelanto;

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
    this.origenComboId,
    this.origenComboNombre,
    this.nivelAplicadoSnapshot,
    this.ordenServicioId,
    this.ordenCodigo,
    this.ordenCostoTotal,
    this.ordenAdelanto,
    this.ordenDescuento,
    this.ordenMetodoPagoAdelanto,
  });

  /// True si esta línea cobra el saldo de una orden de servicio.
  bool get esOrdenServicio => ordenServicioId != null;

  String get tipoItem {
    if (ordenServicioId != null) return 'orden_servicio';
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
        tipoAfectacion,
        porcentajeIGV,
        igv,
        icbper,
        subtotal,
        total,
        orden,
        origenComboId,
        origenComboNombre,
        nivelAplicadoSnapshot,
        ordenServicioId,
        ordenCodigo,
        ordenCostoTotal,
        ordenAdelanto,
        ordenDescuento,
        ordenMetodoPagoAdelanto,
      ];
}
