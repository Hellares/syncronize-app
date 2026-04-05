import 'package:equatable/equatable.dart';

class SlotDisponibilidad extends Equatable {
  final String horaInicio;
  final String horaFin;
  final bool disponible;
  final int tecnicosDisponibles;

  const SlotDisponibilidad({
    required this.horaInicio,
    required this.horaFin,
    required this.disponible,
    this.tecnicosDisponibles = 0,
  });

  @override
  List<Object?> get props => [horaInicio, horaFin, disponible, tecnicosDisponibles];
}

class DisponibilidadResponse extends Equatable {
  final List<SlotDisponibilidad> slots;
  final int duracionMinutos;
  final String? mensaje;

  const DisponibilidadResponse({
    required this.slots,
    required this.duracionMinutos,
    this.mensaje,
  });

  @override
  List<Object?> get props => [slots, duracionMinutos, mensaje];
}

class TecnicoDisponible extends Equatable {
  final String tecnicoId;
  final String nombre;
  final bool disponible;

  const TecnicoDisponible({
    required this.tecnicoId,
    required this.nombre,
    required this.disponible,
  });

  @override
  List<Object?> get props => [tecnicoId, nombre, disponible];
}
