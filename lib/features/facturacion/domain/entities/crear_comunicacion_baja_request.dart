import 'package:equatable/equatable.dart';

class CrearComunicacionBajaDetalleRequest extends Equatable {
  final String comprobanteId;
  final String motivoEspecifico;

  const CrearComunicacionBajaDetalleRequest({
    required this.comprobanteId,
    required this.motivoEspecifico,
  });

  @override
  List<Object?> get props => [comprobanteId, motivoEspecifico];
}

class CrearComunicacionBajaRequest extends Equatable {
  final String sedeId;

  /// "YYYY-MM-DD" — fecha de los documentos a anular (max 7 días atrás).
  final String fechaReferencia;

  /// Motivo general (max 500 chars).
  final String motivoBaja;

  final List<CrearComunicacionBajaDetalleRequest> detalles;

  const CrearComunicacionBajaRequest({
    required this.sedeId,
    required this.fechaReferencia,
    required this.motivoBaja,
    required this.detalles,
  });

  @override
  List<Object?> get props => [sedeId, fechaReferencia, motivoBaja, detalles];
}
