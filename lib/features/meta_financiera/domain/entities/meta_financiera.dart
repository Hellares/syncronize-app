import 'package:equatable/equatable.dart';

class MetaFinanciera extends Equatable {
  final String id;
  final String tipo;
  final String nombre;
  final double montoMeta;
  final double montoActual;
  final double porcentaje;
  final String estado; // Cumplida, Vencida, En progreso
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final double? diferencia;

  const MetaFinanciera({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.montoMeta,
    required this.montoActual,
    required this.porcentaje,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.diferencia,
  });

  bool get cumplida => estado == 'Cumplida' || porcentaje >= 100;
  bool get vencida => estado == 'Vencida';

  @override
  List<Object?> get props => [id, tipo, nombre, montoMeta, montoActual, porcentaje, estado];
}
