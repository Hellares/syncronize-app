import 'package:equatable/equatable.dart';

/// Comunicación de Baja (RA SUNAT) — anula Facturas/NC-FC/ND-FD ACEPTADOS.
class ComunicacionBaja extends Equatable {
  final String id;
  final String numeroCompleto;
  final String serie;
  final String correlativo;
  final DateTime fechaEmision;
  final DateTime fechaReferencia;
  final String motivoBaja;
  final String estadoSunat;
  final String? ticket;
  final String? errorProveedor;
  final List<DetalleComunicacionBaja> detalles;

  const ComunicacionBaja({
    required this.id,
    required this.numeroCompleto,
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.fechaReferencia,
    required this.motivoBaja,
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

class DetalleComunicacionBaja extends Equatable {
  final String id;
  final String comprobanteId;
  final String comprobanteCodigo;
  final String tipoComprobante;
  final String motivoEspecifico;

  const DetalleComunicacionBaja({
    required this.id,
    required this.comprobanteId,
    required this.comprobanteCodigo,
    required this.tipoComprobante,
    required this.motivoEspecifico,
  });

  @override
  List<Object?> get props => [id, comprobanteId];
}
