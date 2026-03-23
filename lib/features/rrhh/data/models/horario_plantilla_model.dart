import '../../domain/entities/horario_plantilla.dart';
import 'turno_model.dart';

class HorarioPlantillaDiaModel extends HorarioPlantillaDia {
  const HorarioPlantillaDiaModel({
    required super.id,
    required super.diaSemana,
    super.turnoId,
    super.esDescanso,
    super.horaInicioOverride,
    super.horaFinOverride,
    super.turno,
  });

  factory HorarioPlantillaDiaModel.fromJson(Map<String, dynamic> json) {
    return HorarioPlantillaDiaModel(
      id: json['id'] as String,
      diaSemana: DiaSemana.fromString(json['diaSemana'] as String? ?? 'LUNES'),
      turnoId: json['turnoId'] as String?,
      esDescanso: json['esDescanso'] as bool? ?? false,
      horaInicioOverride: json['horaInicioOverride'] as String?,
      horaFinOverride: json['horaFinOverride'] as String?,
      turno: json['turno'] != null
          ? TurnoModel.fromJson(json['turno'] as Map<String, dynamic>)
          : null,
    );
  }

  HorarioPlantillaDia toEntity() => this;
}

class HorarioPlantillaModel extends HorarioPlantilla {
  const HorarioPlantillaModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    super.descripcion,
    super.isActive,
    super.dias,
  });

  factory HorarioPlantillaModel.fromJson(Map<String, dynamic> json) {
    final diasList = json['dias'] as List?;

    return HorarioPlantillaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      dias: diasList != null
          ? diasList
              .map((e) => HorarioPlantillaDiaModel.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  HorarioPlantilla toEntity() => this;
}
