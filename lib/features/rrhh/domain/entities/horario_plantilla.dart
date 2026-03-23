import 'package:equatable/equatable.dart';
import 'turno.dart';

/// Días de la semana
enum DiaSemana {
  lunes,
  martes,
  miercoles,
  jueves,
  viernes,
  sabado,
  domingo;

  String get label {
    switch (this) {
      case lunes:
        return 'Lunes';
      case martes:
        return 'Martes';
      case miercoles:
        return 'Miércoles';
      case jueves:
        return 'Jueves';
      case viernes:
        return 'Viernes';
      case sabado:
        return 'Sábado';
      case domingo:
        return 'Domingo';
    }
  }

  String get abreviatura {
    switch (this) {
      case lunes:
        return 'Lun';
      case martes:
        return 'Mar';
      case miercoles:
        return 'Mié';
      case jueves:
        return 'Jue';
      case viernes:
        return 'Vie';
      case sabado:
        return 'Sáb';
      case domingo:
        return 'Dom';
    }
  }

  String get apiValue => name.toUpperCase();

  static DiaSemana fromString(String value) {
    switch (value.toUpperCase()) {
      case 'LUNES':
        return lunes;
      case 'MARTES':
        return martes;
      case 'MIERCOLES':
        return miercoles;
      case 'JUEVES':
        return jueves;
      case 'VIERNES':
        return viernes;
      case 'SABADO':
        return sabado;
      case 'DOMINGO':
        return domingo;
      default:
        return lunes;
    }
  }
}

/// Entity que representa un día dentro de una plantilla de horario
class HorarioPlantillaDia extends Equatable {
  final String id;
  final DiaSemana diaSemana;
  final String? turnoId;
  final bool esDescanso;
  final String? horaInicioOverride;
  final String? horaFinOverride;
  final Turno? turno;

  const HorarioPlantillaDia({
    required this.id,
    required this.diaSemana,
    this.turnoId,
    this.esDescanso = false,
    this.horaInicioOverride,
    this.horaFinOverride,
    this.turno,
  });

  String get horarioLabel {
    if (esDescanso) return 'Descanso';
    final inicio = horaInicioOverride ?? turno?.horaInicio ?? '--:--';
    final fin = horaFinOverride ?? turno?.horaFin ?? '--:--';
    return '$inicio - $fin';
  }

  @override
  List<Object?> get props => [
        id,
        diaSemana,
        turnoId,
        esDescanso,
        horaInicioOverride,
        horaFinOverride,
        turno,
      ];
}

/// Entity que representa una plantilla de horario semanal
class HorarioPlantilla extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final bool isActive;
  final List<HorarioPlantillaDia> dias;

  const HorarioPlantilla({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    this.isActive = true,
    this.dias = const [],
  });

  int get diasLaborales => dias.where((d) => !d.esDescanso).length;

  int get diasDescanso => dias.where((d) => d.esDescanso).length;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombre,
        descripcion,
        isActive,
        dias,
      ];
}
