import 'package:equatable/equatable.dart';

/// Resumen Diario (RC SUNAT) — anula Boletas (`03`) ACEPTADAS. Plazo 3 días.
class ResumenDiario extends Equatable {
  final String id;
  final String numeroCompleto;
  final String serie;
  final String correlativo;
  final DateTime fechaEmision;
  final DateTime fechaReferencia;
  final String motivoAnulacion;
  final String estadoSunat;
  final String? ticket;
  final String? errorProveedor;
  final List<DetalleResumenDiario> detalles;

  const ResumenDiario({
    required this.id,
    required this.numeroCompleto,
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.fechaReferencia,
    required this.motivoAnulacion,
    required this.estadoSunat,
    this.ticket,
    this.errorProveedor,
    this.detalles = const [],
  });

  bool get esAceptado => estadoSunat == 'ACEPTADO';
  bool get esRechazado => estadoSunat == 'RECHAZADO';
  bool get esProcesando =>
      estadoSunat == 'PROCESANDO' ||
      estadoSunat == 'PENDIENTE' ||
      estadoSunat == 'ENVIADO';

  @override
  List<Object?> get props => [id, estadoSunat];
}

class DetalleResumenDiario extends Equatable {
  final String id;
  final String comprobanteId;
  final String comprobanteCodigo;
  final String tipoComprobante;
  final String motivoEspecifico;

  const DetalleResumenDiario({
    required this.id,
    required this.comprobanteId,
    required this.comprobanteCodigo,
    required this.tipoComprobante,
    required this.motivoEspecifico,
  });

  @override
  List<Object?> get props => [id, comprobanteId];
}
