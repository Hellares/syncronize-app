import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estados posibles de una caja
enum EstadoCaja {
  abierta,
  cerrada;

  String get label {
    switch (this) {
      case EstadoCaja.abierta:
        return 'Abierta';
      case EstadoCaja.cerrada:
        return 'Cerrada';
    }
  }

  String get apiValue => name.toUpperCase();

  Color get color {
    switch (this) {
      case EstadoCaja.abierta:
        return const Color(0xFF4CAF50);
      case EstadoCaja.cerrada:
        return const Color(0xFF9E9E9E);
    }
  }

  static EstadoCaja fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ABIERTA':
        return EstadoCaja.abierta;
      case 'CERRADA':
        return EstadoCaja.cerrada;
      default:
        return EstadoCaja.cerrada;
    }
  }
}

/// Entity que representa una caja (cash register session)
class Caja extends Equatable {
  final String id;
  final String codigo;
  final String sedeId;
  final String? sedeNombre;
  final String usuarioId;
  final String? usuarioNombre;
  final double montoApertura;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final EstadoCaja estado;
  final String? observaciones;

  const Caja({
    required this.id,
    required this.codigo,
    required this.sedeId,
    this.sedeNombre,
    required this.usuarioId,
    this.usuarioNombre,
    required this.montoApertura,
    required this.fechaApertura,
    this.fechaCierre,
    required this.estado,
    this.observaciones,
  });

  bool get estaAbierta => estado == EstadoCaja.abierta;

  @override
  List<Object?> get props => [
        id,
        codigo,
        sedeId,
        sedeNombre,
        usuarioId,
        usuarioNombre,
        montoApertura,
        fechaApertura,
        fechaCierre,
        estado,
        observaciones,
      ];
}
