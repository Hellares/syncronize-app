import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de asistencia
enum TipoAsistencia {
  normal,
  feriado,
  dominical;

  String get label {
    switch (this) {
      case normal:
        return 'Normal';
      case feriado:
        return 'Feriado';
      case dominical:
        return 'Dominical';
    }
  }

  Color get color {
    switch (this) {
      case normal:
        return Colors.blue;
      case feriado:
        return Colors.purple;
      case dominical:
        return Colors.orange;
    }
  }

  String get apiValue => name.toUpperCase();

  static TipoAsistencia fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NORMAL':
        return normal;
      case 'FERIADO':
        return feriado;
      case 'DOMINICAL':
        return dominical;
      default:
        return normal;
    }
  }
}

/// Estado de la asistencia
enum EstadoAsistencia {
  presente,
  tardanza,
  falta,
  justificado,
  vacacion,
  licencia,
  feriado,
  descanso;

  String get label {
    switch (this) {
      case presente:
        return 'Presente';
      case tardanza:
        return 'Tardanza';
      case falta:
        return 'Falta';
      case justificado:
        return 'Justificado';
      case vacacion:
        return 'Vacación';
      case licencia:
        return 'Licencia';
      case feriado:
        return 'Feriado';
      case descanso:
        return 'Descanso';
    }
  }

  Color get color {
    switch (this) {
      case presente:
        return Colors.green;
      case tardanza:
        return Colors.orange;
      case falta:
        return Colors.red;
      case justificado:
        return Colors.blue;
      case vacacion:
        return Colors.teal;
      case licencia:
        return Colors.purple;
      case feriado:
        return Colors.indigo;
      case descanso:
        return Colors.grey;
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoAsistencia fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRESENTE':
        return presente;
      case 'TARDANZA':
        return tardanza;
      case 'FALTA':
        return falta;
      case 'JUSTIFICADO':
        return justificado;
      case 'VACACION':
        return vacacion;
      case 'LICENCIA':
        return licencia;
      case 'FERIADO':
        return feriado;
      case 'DESCANSO':
        return descanso;
      default:
        return presente;
    }
  }
}

/// Entity que representa un registro de asistencia
class Asistencia extends Equatable {
  final String id;
  final String empleadoId;
  final String empresaId;
  final String sedeId;
  final DateTime fecha;
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final DateTime? horaAlmuerzoInicio;
  final DateTime? horaAlmuerzoFin;
  final double? horasTrabajadas;
  final double? horasExtra;
  final TipoAsistencia tipoAsistencia;
  final EstadoAsistencia estado;
  final String? observaciones;

  // Datos del empleado
  final String? empleadoNombre;
  final String? empleadoDni;

  const Asistencia({
    required this.id,
    required this.empleadoId,
    required this.empresaId,
    required this.sedeId,
    required this.fecha,
    this.horaEntrada,
    this.horaSalida,
    this.horaAlmuerzoInicio,
    this.horaAlmuerzoFin,
    this.horasTrabajadas,
    this.horasExtra,
    this.tipoAsistencia = TipoAsistencia.normal,
    this.estado = EstadoAsistencia.presente,
    this.observaciones,
    this.empleadoNombre,
    this.empleadoDni,
  });

  bool get tieneHorasExtra => (horasExtra ?? 0) > 0;

  bool get esFalta => estado == EstadoAsistencia.falta;

  bool get esTardanza => estado == EstadoAsistencia.tardanza;

  @override
  List<Object?> get props => [
        id,
        empleadoId,
        empresaId,
        sedeId,
        fecha,
        horaEntrada,
        horaSalida,
        horaAlmuerzoInicio,
        horaAlmuerzoFin,
        horasTrabajadas,
        horasExtra,
        tipoAsistencia,
        estado,
        observaciones,
        empleadoNombre,
        empleadoDni,
      ];
}

/// Resumen de asistencia para un período
class AsistenciaResumen extends Equatable {
  final int diasPresente;
  final int diasTardanza;
  final int diasFalta;
  final int diasJustificado;
  final int diasVacacion;
  final int diasLicencia;
  final int diasDescanso;
  final int diasFeriado;
  final double totalHorasTrabajadas;
  final double totalHorasExtra;

  const AsistenciaResumen({
    this.diasPresente = 0,
    this.diasTardanza = 0,
    this.diasFalta = 0,
    this.diasJustificado = 0,
    this.diasVacacion = 0,
    this.diasLicencia = 0,
    this.diasDescanso = 0,
    this.diasFeriado = 0,
    this.totalHorasTrabajadas = 0,
    this.totalHorasExtra = 0,
  });

  int get totalDias =>
      diasPresente +
      diasTardanza +
      diasFalta +
      diasJustificado +
      diasVacacion +
      diasLicencia +
      diasDescanso +
      diasFeriado;

  double get porcentajeAsistencia {
    final laborales = totalDias - diasDescanso - diasFeriado;
    if (laborales == 0) return 0;
    return ((diasPresente + diasTardanza) / laborales) * 100;
  }

  @override
  List<Object?> get props => [
        diasPresente,
        diasTardanza,
        diasFalta,
        diasJustificado,
        diasVacacion,
        diasLicencia,
        diasDescanso,
        diasFeriado,
        totalHorasTrabajadas,
        totalHorasExtra,
      ];
}
