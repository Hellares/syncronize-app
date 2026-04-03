/// Modelo tipado para items del formulario de venta.
/// A diferencia de [VentaDetalle], no incluye campos calculados
/// del servidor (id, ventaId, igv, subtotal, total).
class VentaDetalleInput {
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String? comboId;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double porcentajeIGV;
  final bool precioIncluyeIgv;
  final String tipoAfectacion;
  final double icbper;
  final int? stockDisponible;

  const VentaDetalleInput({
    this.productoId,
    this.varianteId,
    this.servicioId,
    this.comboId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.porcentajeIGV = 18.0,
    this.precioIncluyeIgv = false,
    this.tipoAfectacion = '10',
    this.icbper = 0,
    this.stockDisponible,
  });

  bool get exceedsStock => stockDisponible != null && cantidad > stockDisponible!;

  double get subtotalBruto => cantidad * precioUnitario - descuento;

  double get subtotal {
    if (precioIncluyeIgv) {
      return subtotalBruto / (1 + porcentajeIGV / 100);
    }
    return subtotalBruto;
  }

  double get igv => subtotal * (porcentajeIGV / 100);

  double get total {
    final base = precioIncluyeIgv ? subtotalBruto : subtotal + igv;
    return base + icbper;
  }

  Map<String, dynamic> toMap() => {
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        if (servicioId != null) 'servicioId': servicioId,
        if (comboId != null) 'comboId': comboId,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        if (descuento > 0) 'descuento': descuento,
        'porcentajeIGV': porcentajeIGV,
        'precioIncluyeIgv': precioIncluyeIgv,
        'tipoAfectacion': tipoAfectacion,
        if (icbper > 0) 'icbper': icbper,
      };
}
