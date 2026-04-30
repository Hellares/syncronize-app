import 'package:equatable/equatable.dart';

class CrearResumenDiarioDetalleRequest extends Equatable {
  final String comprobanteId;
  final String motivoEspecifico;

  const CrearResumenDiarioDetalleRequest({
    required this.comprobanteId,
    required this.motivoEspecifico,
  });

  @override
  List<Object?> get props => [comprobanteId, motivoEspecifico];
}

class CrearResumenDiarioRequest extends Equatable {
  final String sedeId;

  /// Motivo general del lote (max 500 chars).
  final String motivoAnulacion;

  final List<CrearResumenDiarioDetalleRequest> detalles;

  const CrearResumenDiarioRequest({
    required this.sedeId,
    required this.motivoAnulacion,
    required this.detalles,
  });

  @override
  List<Object?> get props => [sedeId, motivoAnulacion, detalles];
}
