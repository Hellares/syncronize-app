import 'package:equatable/equatable.dart';

/// Entity que representa un turno de trabajo
class Turno extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String horaInicio;
  final String horaFin;
  final int duracionAlmuerzoMin;
  final double horasEfectivas;
  final String? color;
  final bool isDefault;
  final bool isActive;

  const Turno({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    this.duracionAlmuerzoMin = 60,
    this.horasEfectivas = 8.0,
    this.color,
    this.isDefault = false,
    this.isActive = true,
  });

  String get rangoHorario => '$horaInicio - $horaFin';

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombre,
        horaInicio,
        horaFin,
        duracionAlmuerzoMin,
        horasEfectivas,
        color,
        isDefault,
        isActive,
      ];
}
