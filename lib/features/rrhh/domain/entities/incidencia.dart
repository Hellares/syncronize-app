import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de incidencia
enum TipoIncidencia {
  vacacion,
  licenciaMedica,
  permiso,
  descansoMedico,
  licenciaPaternidad,
  licenciaMaternidad,
  otro;

  String get label {
    switch (this) {
      case vacacion:
        return 'Vacación';
      case licenciaMedica:
        return 'Licencia Médica';
      case permiso:
        return 'Permiso';
      case descansoMedico:
        return 'Descanso Médico';
      case licenciaPaternidad:
        return 'Licencia Paternidad';
      case licenciaMaternidad:
        return 'Licencia Maternidad';
      case otro:
        return 'Otro';
    }
  }

  Color get color {
    switch (this) {
      case vacacion:
        return Colors.teal;
      case licenciaMedica:
        return Colors.red;
      case permiso:
        return Colors.blue;
      case descansoMedico:
        return Colors.orange;
      case licenciaPaternidad:
        return Colors.indigo;
      case licenciaMaternidad:
        return Colors.pink;
      case otro:
        return Colors.grey;
    }
  }

  String get apiValue {
    switch (this) {
      case vacacion:
        return 'VACACION';
      case licenciaMedica:
        return 'LICENCIA_MEDICA';
      case permiso:
        return 'PERMISO';
      case descansoMedico:
        return 'DESCANSO_MEDICO';
      case licenciaPaternidad:
        return 'LICENCIA_PATERNIDAD';
      case licenciaMaternidad:
        return 'LICENCIA_MATERNIDAD';
      case otro:
        return 'OTRO';
    }
  }

  static TipoIncidencia fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VACACION':
        return vacacion;
      case 'LICENCIA_MEDICA':
        return licenciaMedica;
      case 'PERMISO':
        return permiso;
      case 'DESCANSO_MEDICO':
        return descansoMedico;
      case 'LICENCIA_PATERNIDAD':
        return licenciaPaternidad;
      case 'LICENCIA_MATERNIDAD':
        return licenciaMaternidad;
      case 'OTRO':
        return otro;
      default:
        return otro;
    }
  }
}

/// Estado de la incidencia
enum EstadoIncidencia {
  pendiente,
  aprobada,
  rechazada,
  cancelada;

  String get label {
    switch (this) {
      case pendiente:
        return 'Pendiente';
      case aprobada:
        return 'Aprobada';
      case rechazada:
        return 'Rechazada';
      case cancelada:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case pendiente:
        return Colors.orange;
      case aprobada:
        return Colors.green;
      case rechazada:
        return Colors.red;
      case cancelada:
        return Colors.grey;
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoIncidencia fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE':
        return pendiente;
      case 'APROBADA':
        return aprobada;
      case 'RECHAZADA':
        return rechazada;
      case 'CANCELADA':
        return cancelada;
      default:
        return pendiente;
    }
  }
}

/// Entity que representa una incidencia (vacación, licencia, permiso)
class Incidencia extends Equatable {
  final String id;
  final String empleadoId;
  final String empresaId;
  final TipoIncidencia tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int diasTotal;
  final String? motivo;
  final String? documentoAdjunto;
  final EstadoIncidencia estado;
  final String? aprobadoPorId;
  final DateTime? fechaAprobacion;
  final String? motivoRechazo;
  final DateTime? creadoEn;

  // Datos del empleado
  final String? empleadoNombre;
  final String? empleadoCodigo;
  final String? empleadoCargo;
  final String? empleadoDni;
  final String? empleadoDepartamento;

  // Datos del aprobador
  final String? aprobadoPorNombre;

  const Incidencia({
    required this.id,
    required this.empleadoId,
    required this.empresaId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diasTotal,
    this.motivo,
    this.documentoAdjunto,
    this.estado = EstadoIncidencia.pendiente,
    this.aprobadoPorId,
    this.fechaAprobacion,
    this.motivoRechazo,
    this.creadoEn,
    this.empleadoNombre,
    this.empleadoCodigo,
    this.empleadoCargo,
    this.empleadoDni,
    this.empleadoDepartamento,
    this.aprobadoPorNombre,
  });

  bool get estaPendiente => estado == EstadoIncidencia.pendiente;

  bool get estaAprobada => estado == EstadoIncidencia.aprobada;

  @override
  List<Object?> get props => [
        id,
        empleadoId,
        empresaId,
        tipo,
        fechaInicio,
        fechaFin,
        diasTotal,
        motivo,
        documentoAdjunto,
        estado,
        aprobadoPorId,
        fechaAprobacion,
        motivoRechazo,
        creadoEn,
        empleadoNombre,
        empleadoCodigo,
        empleadoCargo,
        empleadoDni,
        empleadoDepartamento,
        aprobadoPorNombre,
      ];
}
