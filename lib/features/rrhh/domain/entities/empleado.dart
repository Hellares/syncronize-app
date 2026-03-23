import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de contrato del empleado
enum TipoContrato {
  planilla,
  locador,
  reciboHonorarios,
  practicante;

  String get label {
    switch (this) {
      case planilla:
        return 'Planilla';
      case locador:
        return 'Locador';
      case reciboHonorarios:
        return 'Recibo por Honorarios';
      case practicante:
        return 'Practicante';
    }
  }

  String get apiValue {
    switch (this) {
      case planilla:
        return 'PLANILLA';
      case locador:
        return 'LOCADOR';
      case reciboHonorarios:
        return 'RECIBO_HONORARIOS';
      case practicante:
        return 'PRACTICANTE';
    }
  }

  static TipoContrato fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PLANILLA':
        return planilla;
      case 'LOCADOR':
        return locador;
      case 'RECIBO_HONORARIOS':
        return reciboHonorarios;
      case 'PRACTICANTE':
        return practicante;
      default:
        return planilla;
    }
  }
}

/// Estado del empleado
enum EstadoEmpleado {
  activo,
  vacaciones,
  licencia,
  suspendido,
  cesado;

  String get label {
    switch (this) {
      case activo:
        return 'Activo';
      case vacaciones:
        return 'Vacaciones';
      case licencia:
        return 'Licencia';
      case suspendido:
        return 'Suspendido';
      case cesado:
        return 'Cesado';
    }
  }

  Color get color {
    switch (this) {
      case activo:
        return Colors.green;
      case vacaciones:
        return Colors.blue;
      case licencia:
        return Colors.orange;
      case suspendido:
        return Colors.red;
      case cesado:
        return Colors.grey;
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoEmpleado fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVO':
        return activo;
      case 'VACACIONES':
        return vacaciones;
      case 'LICENCIA':
        return licencia;
      case 'SUSPENDIDO':
        return suspendido;
      case 'CESADO':
        return cesado;
      default:
        return activo;
    }
  }
}

/// Entity que representa un empleado
class Empleado extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String usuarioId;
  final String codigo;
  final String? cargo;
  final String? departamento;
  final DateTime fechaIngreso;
  final DateTime? fechaCese;
  final TipoContrato tipoContrato;
  final double salarioBase;
  final String moneda;
  final String? banco;
  final String? numeroCuenta;
  final String? cci;
  final String? horarioPlantillaId;
  final EstadoEmpleado estado;
  final bool isActive;

  // Datos de persona (desde usuario.persona)
  final String? nombres;
  final String? apellidos;
  final String? dni;
  final String? email;
  final String? telefono;

  // Relaciones
  final String? sedeNombre;

  const Empleado({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.usuarioId,
    required this.codigo,
    this.cargo,
    this.departamento,
    required this.fechaIngreso,
    this.fechaCese,
    required this.tipoContrato,
    required this.salarioBase,
    this.moneda = 'PEN',
    this.banco,
    this.numeroCuenta,
    this.cci,
    this.horarioPlantillaId,
    this.estado = EstadoEmpleado.activo,
    this.isActive = true,
    this.nombres,
    this.apellidos,
    this.dni,
    this.email,
    this.telefono,
    this.sedeNombre,
  });

  String get nombreCompleto {
    final n = nombres ?? '';
    final a = apellidos ?? '';
    return '$n $a'.trim();
  }

  String get iniciales {
    final partes = nombreCompleto.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    if (partes.isNotEmpty && partes[0].isNotEmpty) {
      return partes[0][0].toUpperCase();
    }
    return '';
  }

  bool get estaCesado => estado == EstadoEmpleado.cesado;

  bool get estaActivo => estado == EstadoEmpleado.activo;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        usuarioId,
        codigo,
        cargo,
        departamento,
        fechaIngreso,
        fechaCese,
        tipoContrato,
        salarioBase,
        moneda,
        banco,
        numeroCuenta,
        cci,
        horarioPlantillaId,
        estado,
        isActive,
        nombres,
        apellidos,
        dni,
        email,
        telefono,
        sedeNombre,
      ];
}
