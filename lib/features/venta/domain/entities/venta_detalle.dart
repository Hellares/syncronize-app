import 'package:equatable/equatable.dart';

import '../../../../core/utils/unidad_presentacion.dart';

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

  /// SKU del producto. OPCIONAL: no todas las empresas lo cargan, y por eso el
  /// ticket cae a [productoCodigo], que sí es obligatorio.
  final String? productoSku;
  final String? varianteNombre;
  final String? varianteSku;
  final String? servicioNombre;
  final String? servicioCodigo;

  /// El código con el que se identifica lo vendido en esta línea, y de dónde
  /// salió. Null cuando no hay ninguno (servicios, ítems libres).
  ///
  /// Prioridad: **SKU de la variante → SKU del producto → código del
  /// producto**. La variante primero porque es lo que de verdad salió del
  /// stock: en un producto con tallas, el SKU del padre no dice cuál se
  /// vendió, y ese es justamente el dato que se necesita en un cambio.
  ({String etiqueta, String valor})? get codigoIdentificador {
    final candidatos = <({String etiqueta, String? valor})>[
      (etiqueta: 'SKU', valor: varianteSku),
      (etiqueta: 'SKU', valor: productoSku),
      (etiqueta: 'Cod', valor: productoCodigo),
    ];
    for (final c in candidatos) {
      final valor = c.valor?.trim() ?? '';
      if (valor.isNotEmpty) return (etiqueta: c.etiqueta, valor: valor);
    }
    return null;
  }

  // Trazabilidad de combo origen: cuando este detalle es un componente
  // que se vendió como parte de un combo expandido, estos campos lo
  // identifican. Null si se vendió suelto.
  final String? origenComboId;
  final String? origenComboNombre;

  /// Etiqueta del precio aplicado al vender (snapshot): nombre del nivel
  /// ("Por Mayor"), "Oferta" o "Liquidación". Null si fue precio base.
  final String? nivelAplicadoSnapshot;

  /// Unidad en la que se le habló al cliente en esta línea (snapshot del
  /// momento de la venta). `cantidad` y `precioUnitario` siguen guardados en
  /// unidad de venta: un granel vendido en kilos llega como 1500 y 0.008, y
  /// es [presentacion] la que lo traduce a "1.5 kg" y "S/8.00/kg".
  ///
  /// Snapshot y no lookup al producto: reimprimir el ticket de una venta
  /// vieja tiene que mostrar lo que se cobró ese día.
  final String? unidadPresentacionSimbolo;
  final double? factorPresentacion;

  /// Unidad SUNAT (catálogo 03) con la que se declaró esta línea, ej. "KGM".
  /// La necesita la nota de crédito: tiene que declararse en la misma unidad
  /// que el comprobante que afecta.
  final String? codigoUnidadSunat;

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
    this.productoSku,
    this.varianteNombre,
    this.varianteSku,
    this.servicioNombre,
    this.servicioCodigo,
    this.origenComboId,
    this.origenComboNombre,
    this.nivelAplicadoSnapshot,
    this.unidadPresentacionSimbolo,
    this.factorPresentacion,
    this.codigoUnidadSunat,
    this.ordenServicioId,
    this.ordenCodigo,
    this.ordenCostoTotal,
    this.ordenAdelanto,
    this.ordenDescuento,
    this.ordenMetodoPagoAdelanto,
  });

  /// True si esta línea cobra el saldo de una orden de servicio.
  bool get esOrdenServicio => ordenServicioId != null;

  /// Traductor de unidades de esta línea. Sin presentación configurada el
  /// factor es 1 y no toca ningún número, así que se puede usar en cualquier
  /// pantalla sin preguntar si el producto la tiene.
  UnidadPresentacion get presentacion => factorPresentacion == null
      ? const UnidadPresentacion.ninguna()
      : UnidadPresentacion(
          factor: factorPresentacion!,
          simbolo: unidadPresentacionSimbolo,
        );

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
        unidadPresentacionSimbolo,
        factorPresentacion,
        codigoUnidadSunat,
        ordenServicioId,
        ordenCodigo,
        ordenCostoTotal,
        ordenAdelanto,
        ordenDescuento,
        ordenMetodoPagoAdelanto,
      ];
}
