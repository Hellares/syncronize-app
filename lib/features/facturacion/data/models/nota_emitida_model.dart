import '../../domain/entities/nota_emitida.dart';

class NotaEmitidaModel extends NotaEmitida {
  const NotaEmitidaModel({
    required super.id,
    required super.tipoComprobante,
    required super.serie,
    required super.correlativo,
    required super.codigoGenerado,
    required super.total,
    required super.estado,
    required super.sunatStatus,
  });

  factory NotaEmitidaModel.fromJson(Map<String, dynamic> json) {
    return NotaEmitidaModel(
      id: json['id'] as String,
      tipoComprobante: json['tipoComprobante'] as String,
      serie: json['serie'] as String,
      correlativo: json['correlativo'] as String,
      codigoGenerado: json['codigoGenerado'] as String,
      total: _toDouble(json['total']),
      estado: json['estado'] as String,
      sunatStatus: json['sunatStatus'] as String? ?? 'PENDIENTE',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
