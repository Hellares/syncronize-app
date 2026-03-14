import '../../domain/entities/slot_disponibilidad.dart';

class SlotDisponibilidadModel extends SlotDisponibilidad {
  const SlotDisponibilidadModel({
    required super.horaInicio,
    required super.horaFin,
    required super.disponible,
    super.tecnicosDisponibles,
  });

  factory SlotDisponibilidadModel.fromJson(Map<String, dynamic> json) {
    return SlotDisponibilidadModel(
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      disponible: json['disponible'] as bool,
      tecnicosDisponibles: json['tecnicosDisponibles'] as int? ?? 0,
    );
  }
}

class DisponibilidadResponseModel extends DisponibilidadResponse {
  const DisponibilidadResponseModel({
    required super.slots,
    required super.duracionMinutos,
    super.mensaje,
  });

  factory DisponibilidadResponseModel.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List? ?? [];
    return DisponibilidadResponseModel(
      slots: slotsJson
          .map((s) =>
              SlotDisponibilidadModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      duracionMinutos: json['duracionMinutos'] as int? ?? 30,
      mensaje: json['mensaje'] as String?,
    );
  }
}

class TecnicoDisponibleModel extends TecnicoDisponible {
  const TecnicoDisponibleModel({
    required super.tecnicoId,
    required super.nombre,
    required super.disponible,
  });

  factory TecnicoDisponibleModel.fromJson(Map<String, dynamic> json) {
    return TecnicoDisponibleModel(
      tecnicoId: json['tecnicoId'] as String,
      nombre: json['nombre'] as String,
      disponible: json['disponible'] as bool,
    );
  }
}
