/// Modelo tipado para items del formulario de cotización.
/// A diferencia de [CotizacionDetalle], no incluye campos calculados
/// del servidor (id, cotizacionId, igv, subtotal, total).
class CotizacionDetalleInput {
  final String? productoId;
  final String? varianteId;
  final String? servicioId;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double porcentajeIGV;

  const CotizacionDetalleInput({
    this.productoId,
    this.varianteId,
    this.servicioId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.porcentajeIGV = 18.0,
  });

  double get subtotal => cantidad * precioUnitario - descuento;

  Map<String, dynamic> toMap() => {
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        if (servicioId != null) 'servicioId': servicioId,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        if (descuento > 0) 'descuento': descuento,
        'porcentajeIGV': porcentajeIGV,
      };
}
