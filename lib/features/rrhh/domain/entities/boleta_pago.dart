import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado de la boleta de pago
enum EstadoBoletaPago {
  pendienteBoleta,
  pagadaBoleta,
  anuladaBoleta;

  String get label {
    switch (this) {
      case pendienteBoleta:
        return 'Pendiente';
      case pagadaBoleta:
        return 'Pagada';
      case anuladaBoleta:
        return 'Anulada';
    }
  }

  Color get color {
    switch (this) {
      case pendienteBoleta:
        return Colors.orange;
      case pagadaBoleta:
        return Colors.green;
      case anuladaBoleta:
        return Colors.red;
    }
  }

  String get apiValue {
    switch (this) {
      case pendienteBoleta:
        return 'PENDIENTE_BOLETA';
      case pagadaBoleta:
        return 'PAGADA_BOLETA';
      case anuladaBoleta:
        return 'ANULADA_BOLETA';
    }
  }

  static EstadoBoletaPago fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE_BOLETA':
        return pendienteBoleta;
      case 'PAGADA_BOLETA':
        return pagadaBoleta;
      case 'ANULADA_BOLETA':
        return anuladaBoleta;
      default:
        return pendienteBoleta;
    }
  }
}

/// Tipo de detalle de boleta
enum TipoDetalleBoleta {
  ingreso,
  descuento,
  aporteEmpleador;

  String get label {
    switch (this) {
      case ingreso:
        return 'Ingreso';
      case descuento:
        return 'Descuento';
      case aporteEmpleador:
        return 'Aporte Empleador';
    }
  }

  String get apiValue {
    switch (this) {
      case ingreso:
        return 'INGRESO';
      case descuento:
        return 'DESCUENTO';
      case aporteEmpleador:
        return 'APORTE_EMPLEADOR';
    }
  }

  static TipoDetalleBoleta fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INGRESO':
        return ingreso;
      case 'DESCUENTO':
        return descuento;
      case 'APORTE_EMPLEADOR':
        return aporteEmpleador;
      default:
        return ingreso;
    }
  }
}

/// Detalle de una boleta de pago
class DetalleBoletaPago extends Equatable {
  final String id;
  final String boletaId;
  final TipoDetalleBoleta tipo;
  final String concepto;
  final String? descripcion;
  final double monto;
  final double? porcentaje;

  const DetalleBoletaPago({
    required this.id,
    required this.boletaId,
    required this.tipo,
    required this.concepto,
    this.descripcion,
    required this.monto,
    this.porcentaje,
  });

  @override
  List<Object?> get props => [id, boletaId, tipo, concepto, descripcion, monto, porcentaje];
}

/// Entity que representa una boleta de pago
class BoletaPago extends Equatable {
  final String id;
  final String periodoId;
  final String empleadoId;
  final String empresaId;
  final int diasTrabajados;
  final int diasFalta;
  final int diasTardanza;
  final double horasExtra;
  final double salarioBase;
  final double totalIngresos;
  final double totalDescuentos;
  final double totalAportaciones;
  final double totalNeto;
  final EstadoBoletaPago estado;
  final DateTime? fechaPago;
  final String? metodoPago;
  final String? observaciones;

  // Datos del empleado
  final String? empleadoNombre;
  final String? empleadoCodigo;
  final String? empleadoCargo;
  final String? empleadoDni;
  final String? empleadoDepartamento;

  // Datos del periodo
  final String? periodoPeriodo;
  final String? periodoEstado;

  // Detalles
  final List<DetalleBoletaPago>? detalles;

  const BoletaPago({
    required this.id,
    required this.periodoId,
    required this.empleadoId,
    required this.empresaId,
    required this.diasTrabajados,
    this.diasFalta = 0,
    this.diasTardanza = 0,
    this.horasExtra = 0,
    required this.salarioBase,
    required this.totalIngresos,
    required this.totalDescuentos,
    required this.totalAportaciones,
    required this.totalNeto,
    this.estado = EstadoBoletaPago.pendienteBoleta,
    this.fechaPago,
    this.metodoPago,
    this.observaciones,
    this.empleadoNombre,
    this.empleadoCodigo,
    this.empleadoCargo,
    this.empleadoDni,
    this.empleadoDepartamento,
    this.periodoPeriodo,
    this.periodoEstado,
    this.detalles,
  });

  bool get estaPendiente => estado == EstadoBoletaPago.pendienteBoleta;

  bool get estaPagada => estado == EstadoBoletaPago.pagadaBoleta;

  @override
  List<Object?> get props => [
        id,
        periodoId,
        empleadoId,
        empresaId,
        diasTrabajados,
        diasFalta,
        diasTardanza,
        horasExtra,
        salarioBase,
        totalIngresos,
        totalDescuentos,
        totalAportaciones,
        totalNeto,
        estado,
        fechaPago,
        metodoPago,
        observaciones,
        empleadoNombre,
        empleadoCodigo,
        empleadoCargo,
        empleadoDni,
        empleadoDepartamento,
        periodoPeriodo,
        periodoEstado,
        detalles,
      ];
}
