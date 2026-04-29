import '../../domain/entities/comprobante_elegible_baja.dart';

class ComprobanteElegibleBajaModel extends ComprobanteElegibleBaja {
  const ComprobanteElegibleBajaModel({
    required super.id,
    required super.codigoGenerado,
    required super.tipoComprobante,
    required super.serie,
    required super.correlativo,
    required super.nombreCliente,
    super.numeroDocumento,
    required super.fechaEmision,
    required super.total,
    super.moneda,
    required super.elegible,
    super.motivoNoElegible,
  });

  factory ComprobanteElegibleBajaModel.fromJson(Map<String, dynamic> json) {
    return ComprobanteElegibleBajaModel(
      id: json['id'] as String,
      codigoGenerado: json['codigoGenerado'] as String,
      tipoComprobante: json['tipoComprobante'] as String,
      serie: json['serie'] as String,
      correlativo: json['correlativo'] as String,
      nombreCliente: json['nombreCliente'] as String? ?? '',
      numeroDocumento: json['numeroDocumento'] as String?,
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      total: _toDouble(json['total']),
      moneda: json['moneda'] as String? ?? 'PEN',
      elegible: json['elegible'] as bool? ?? false,
      motivoNoElegible: json['motivoNoElegible'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
