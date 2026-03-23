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
  final int? stockDisponible; // Solo para validación en UI, no se envía al backend

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
    if (precioIncluyeIgv) {
      return subtotalBruto;
    }
    return subtotal + igv;
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
      };
}
