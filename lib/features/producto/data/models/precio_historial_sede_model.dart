import '../../domain/entities/precio_historial_sede.dart';

class PrecioHistorialSedeModel extends PrecioHistorialSede {
  const PrecioHistorialSedeModel({
    required super.id,
    required super.sedeId,
    required super.sedeName,
    super.productoId,
    super.productoNombre,
    super.productoCodigo,
    super.varianteId,
    super.varianteNombre,
    super.varianteSku,
    super.precioAnterior,
    super.precioNuevo,
    super.precioCostoAnterior,
    super.precioCostoNuevo,
    super.precioOfertaAnterior,
    super.precioOfertaNuevo,
    required super.tipoCambio,
    super.razon,
    super.origenModulo,
    super.usuarioNombre,
    required super.creadoEn,
  });

  factory PrecioHistorialSedeModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final ps = json['productoStock'] as Map<String, dynamic>?;
    final producto = ps?['producto'] as Map<String, dynamic>?;
    final variante = ps?['variante'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;

    String? usuarioNombre;
    if (persona != null) {
      usuarioNombre = '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
    }

    return PrecioHistorialSedeModel(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String,
      sedeName: sede?['nombre'] as String? ?? '',
      productoId: ps?['productoId'] as String?,
      productoNombre: producto?['nombre'] as String?,
      productoCodigo: producto?['codigoEmpresa'] as String?,
      varianteId: ps?['varianteId'] as String?,
      varianteNombre: variante?['nombre'] as String?,
      varianteSku: variante?['sku'] as String?,
      precioAnterior: _toDouble(json['precioAnterior']),
      precioNuevo: _toDouble(json['precioNuevo']),
      precioCostoAnterior: _toDouble(json['precioCostoAnterior']),
      precioCostoNuevo: _toDouble(json['precioCostoNuevo']),
      precioOfertaAnterior: _toDouble(json['precioOfertaAnterior']),
      precioOfertaNuevo: _toDouble(json['precioOfertaNuevo']),
      tipoCambio: json['tipoCambio'] as String? ?? '',
      razon: json['razon'] as String?,
      origenModulo: json['origenModulo'] as String?,
      usuarioNombre: usuarioNombre,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
