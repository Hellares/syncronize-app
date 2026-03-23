import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado del adelanto
enum EstadoAdelanto {
  pendienteAdelanto,
  aprobadoAdelanto,
  pagadoAdelanto,
  descontadoAdelanto,
  rechazadoAdelanto;

  String get label {
    switch (this) {
      case pendienteAdelanto:
        return 'Pendiente';
      case aprobadoAdelanto:
        return 'Aprobado';
      case pagadoAdelanto:
        return 'Pagado';
      case descontadoAdelanto:
        return 'Descontado';
      case rechazadoAdelanto:
        return 'Rechazado';
    }
  }

  Color get color {
    switch (this) {
      case pendienteAdelanto:
        return Colors.orange;
      case aprobadoAdelanto:
        return Colors.blue;
      case pagadoAdelanto:
        return Colors.green;
      case descontadoAdelanto:
        return Colors.teal;
      case rechazadoAdelanto:
        return Colors.red;
    }
  }

  String get apiValue {
    switch (this) {
      case pendienteAdelanto:
        return 'PENDIENTE_ADELANTO';
      case aprobadoAdelanto:
        return 'APROBADO_ADELANTO';
      case pagadoAdelanto:
        return 'PAGADO_ADELANTO';
      case descontadoAdelanto:
        return 'DESCONTADO_ADELANTO';
      case rechazadoAdelanto:
        return 'RECHAZADO_ADELANTO';
    }
  }

  static EstadoAdelanto fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE_ADELANTO':
        return pendienteAdelanto;
      case 'APROBADO_ADELANTO':
        return aprobadoAdelanto;
      case 'PAGADO_ADELANTO':
        return pagadoAdelanto;
      case 'DESCONTADO_ADELANTO':
        return descontadoAdelanto;
      case 'RECHAZADO_ADELANTO':
        return rechazadoAdelanto;
      default:
        return pendienteAdelanto;
    }
  }
}

/// Entity que representa un adelanto de pago
class Adelanto extends Equatable {
  final String id;
  final String empleadoId;
  final String empresaId;
  final double monto;
  final String? motivo;
  final DateTime fechaSolicitud;
  final EstadoAdelanto estado;
  final String? aprobadoPorId;
  final DateTime? fechaAprobacion;
  final String? metodoPago;
  final String? pagadoPorId;
  final String? motivoRechazo;

  // Datos del empleado
  final String? empleadoNombre;
  final String? empleadoCodigo;
  final String? empleadoCargo;
  final String? empleadoDni;

  // Datos del aprobador
  final String? aprobadoPorNombre;

  const Adelanto({
    required this.id,
    required this.empleadoId,
    required this.empresaId,
    required this.monto,
    this.motivo,
    required this.fechaSolicitud,
    this.estado = EstadoAdelanto.pendienteAdelanto,
    this.aprobadoPorId,
    this.fechaAprobacion,
    this.metodoPago,
    this.pagadoPorId,
    this.motivoRechazo,
    this.empleadoNombre,
    this.empleadoCodigo,
    this.empleadoCargo,
    this.empleadoDni,
    this.aprobadoPorNombre,
  });

  bool get estaPendiente => estado == EstadoAdelanto.pendienteAdelanto;

  bool get estaAprobado => estado == EstadoAdelanto.aprobadoAdelanto;

  bool get estaPagado => estado == EstadoAdelanto.pagadoAdelanto;

  @override
  List<Object?> get props => [
        id,
        empleadoId,
        empresaId,
        monto,
        motivo,
        fechaSolicitud,
        estado,
        aprobadoPorId,
        fechaAprobacion,
        metodoPago,
        pagadoPorId,
        motivoRechazo,
        empleadoNombre,
        empleadoCodigo,
        empleadoCargo,
        empleadoDni,
        aprobadoPorNombre,
      ];
}
