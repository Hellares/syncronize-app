import '../../domain/entities/resumen_diario.dart';

class DetalleResumenDiarioModel extends DetalleResumenDiario {
  const DetalleResumenDiarioModel({
    required super.id,
    required super.comprobanteId,
    required super.comprobanteCodigo,
    required super.tipoComprobante,
    required super.motivoEspecifico,
  });

  factory DetalleResumenDiarioModel.fromJson(Map<String, dynamic> json) {
    final comprobante = (json['comprobante'] as Map<String, dynamic>?) ?? {};
    return DetalleResumenDiarioModel(
      id: json['id'] as String,
      comprobanteId: json['comprobanteId'] as String,
      comprobanteCodigo: comprobante['codigoGenerado'] as String? ?? '',
      tipoComprobante: comprobante['tipoComprobante'] as String? ?? '',
      motivoEspecifico: json['motivoEspecifico'] as String? ?? '',
    );
  }
}

class ResumenDiarioModel extends ResumenDiario {
  const ResumenDiarioModel({
    required super.id,
    required super.numeroCompleto,
    required super.serie,
    required super.correlativo,
    required super.fechaEmision,
    required super.fechaReferencia,
    required super.motivoAnulacion,
    required super.estadoSunat,
    super.ticket,
    super.errorProveedor,
    super.detalles,
  });

  factory ResumenDiarioModel.fromJson(Map<String, dynamic> json) {
    return ResumenDiarioModel(
      id: json['id'] as String,
      numeroCompleto: json['numeroCompleto'] as String? ?? '',
      serie: json['serie'] as String? ?? '',
      correlativo: json['correlativo'] as String? ?? '',
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      fechaReferencia: DateTime.parse(json['fechaReferencia'] as String),
      motivoAnulacion: json['motivoAnulacion'] as String? ?? '',
      estadoSunat: json['estadoSunat'] as String? ?? 'PENDIENTE',
      ticket: json['ticket'] as String?,
      errorProveedor: json['errorProveedor'] as String?,
      detalles: (json['detalles'] as List?)
              ?.map((e) => DetalleResumenDiarioModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
