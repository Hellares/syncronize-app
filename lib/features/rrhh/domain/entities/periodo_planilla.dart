import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'boleta_pago.dart';

/// Estado del periodo de planilla
enum EstadoPeriodoPlanilla {
  borrador,
  calculada,
  aprobada,
  pagada,
  cerrada;

  String get label {
    switch (this) {
      case borrador:
        return 'Borrador';
      case calculada:
        return 'Calculada';
      case aprobada:
        return 'Aprobada';
      case pagada:
        return 'Pagada';
      case cerrada:
        return 'Cerrada';
    }
  }

  Color get color {
    switch (this) {
      case borrador:
        return Colors.grey;
      case calculada:
        return Colors.blue;
      case aprobada:
        return Colors.green;
      case pagada:
        return Colors.teal;
      case cerrada:
        return Colors.purple;
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoPeriodoPlanilla fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BORRADOR':
        return borrador;
      case 'CALCULADA':
        return calculada;
      case 'APROBADA':
        return aprobada;
      case 'PAGADA':
        return pagada;
      case 'CERRADA':
        return cerrada;
      default:
        return borrador;
    }
  }
}

/// Entity que representa un periodo de planilla
class PeriodoPlanilla extends Equatable {
  final String id;
  final String empresaId;
  final String? sedeId;
  final String periodo;
  final int mes;
  final int anio;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadoPeriodoPlanilla estado;
  final double? totalBruto;
  final double? totalDescuentos;
  final double? totalNeto;
  final double? totalAportaciones;
  final String? calculadoPorId;
  final String? aprobadoPorId;
  final DateTime? fechaAprobacion;
  final String? observaciones;

  // Relaciones
  final String? sedeNombre;
  final String? calculadoPorNombre;
  final String? aprobadoPorNombre;
  final int? totalBoletas;
  final List<BoletaPago>? boletas;

  const PeriodoPlanilla({
    required this.id,
    required this.empresaId,
    this.sedeId,
    required this.periodo,
    required this.mes,
    required this.anio,
    required this.fechaInicio,
    required this.fechaFin,
    this.estado = EstadoPeriodoPlanilla.borrador,
    this.totalBruto,
    this.totalDescuentos,
    this.totalNeto,
    this.totalAportaciones,
    this.calculadoPorId,
    this.aprobadoPorId,
    this.fechaAprobacion,
    this.observaciones,
    this.sedeNombre,
    this.calculadoPorNombre,
    this.aprobadoPorNombre,
    this.totalBoletas,
    this.boletas,
  });

  bool get esBorrador => estado == EstadoPeriodoPlanilla.borrador;

  bool get estaCalculada => estado == EstadoPeriodoPlanilla.calculada;

  bool get estaAprobada => estado == EstadoPeriodoPlanilla.aprobada;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        periodo,
        mes,
        anio,
        fechaInicio,
        fechaFin,
        estado,
        totalBruto,
        totalDescuentos,
        totalNeto,
        totalAportaciones,
        calculadoPorId,
        aprobadoPorId,
        fechaAprobacion,
        observaciones,
        sedeNombre,
        calculadoPorNombre,
        aprobadoPorNombre,
        totalBoletas,
        boletas,
      ];
}
