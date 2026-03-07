class PrecioHistorialSede {
  final String id;
  final String sedeId;
  final String sedeName;
  final String? productoId;
  final String? productoNombre;
  final String? productoCodigo;
  final String? varianteId;
  final String? varianteNombre;
  final String? varianteSku;
  final double? precioAnterior;
  final double? precioNuevo;
  final double? precioCostoAnterior;
  final double? precioCostoNuevo;
  final double? precioOfertaAnterior;
  final double? precioOfertaNuevo;
  final String tipoCambio;
  final String? razon;
  final String? origenModulo;
  final String? usuarioNombre;
  final DateTime creadoEn;

  const PrecioHistorialSede({
    required this.id,
    required this.sedeId,
    required this.sedeName,
    this.productoId,
    this.productoNombre,
    this.productoCodigo,
    this.varianteId,
    this.varianteNombre,
    this.varianteSku,
    this.precioAnterior,
    this.precioNuevo,
    this.precioCostoAnterior,
    this.precioCostoNuevo,
    this.precioOfertaAnterior,
    this.precioOfertaNuevo,
    required this.tipoCambio,
    this.razon,
    this.origenModulo,
    this.usuarioNombre,
    required this.creadoEn,
  });
}
