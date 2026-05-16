import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'cierre_caja.dart';

/// Tipo de arqueo de caja (conteo intermedio sin cerrar la caja).
enum TipoArqueoCaja {
  rutinario,
  sorpresivo,
  relevo;

  String get label {
    switch (this) {
      case TipoArqueoCaja.rutinario:
        return 'Rutinario';
      case TipoArqueoCaja.sorpresivo:
        return 'Sorpresivo';
      case TipoArqueoCaja.relevo:
        return 'Relevo de turno';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoArqueoCaja.rutinario:
        return 'Conteo de control del cajero durante el turno.';
      case TipoArqueoCaja.sorpresivo:
        return 'Auditoria sin aviso previo. Debe realizarla alguien distinto al cajero titular.';
      case TipoArqueoCaja.relevo:
        return 'Cambio de turno sin cerrar la caja. Se entrega a otro cajero.';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoArqueoCaja.rutinario:
        return Icons.fact_check_rounded;
      case TipoArqueoCaja.sorpresivo:
        return Icons.policy_rounded;
      case TipoArqueoCaja.relevo:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TipoArqueoCaja.rutinario:
        return const Color(0xFF4CAF50);
      case TipoArqueoCaja.sorpresivo:
        return const Color(0xFFF54D85);
      case TipoArqueoCaja.relevo:
        return const Color(0xFF2196F3);
    }
  }

  String get apiValue => name.toUpperCase();

  static TipoArqueoCaja fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RUTINARIO':
        return TipoArqueoCaja.rutinario;
      case 'SORPRESIVO':
        return TipoArqueoCaja.sorpresivo;
      case 'RELEVO':
        return TipoArqueoCaja.relevo;
      default:
        return TipoArqueoCaja.rutinario;
    }
  }
}

/// Arqueo de caja. Reusa la misma estructura de detalles que el cierre
/// (DetalleCierreMetodo) para no duplicar.
class ArqueoCaja extends Equatable {
  final String id;
  final String cajaId;
  final String empresaId;
  final TipoArqueoCaja tipo;
  final double montoApertura;
  final double totalIngresos;
  final double totalEgresos;
  final double totalEsperado;
  final double totalConteoFisico;
  final double diferencia;
  final List<DetalleCierreMetodo> detalles;
  final String? observaciones;
  final String realizadoPorId;
  final String? realizadoPorNombre;
  final String? autorizadoPorId;
  final String? autorizadoPorNombre;
  final String? turnoEntregadoAId;
  final String? turnoEntregadoANombre;
  final bool alertaEnviada;
  final DateTime fechaArqueo;

  const ArqueoCaja({
    required this.id,
    required this.cajaId,
    required this.empresaId,
    required this.tipo,
    required this.montoApertura,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.totalEsperado,
    required this.totalConteoFisico,
    required this.diferencia,
    this.detalles = const [],
    this.observaciones,
    required this.realizadoPorId,
    this.realizadoPorNombre,
    this.autorizadoPorId,
    this.autorizadoPorNombre,
    this.turnoEntregadoAId,
    this.turnoEntregadoANombre,
    this.alertaEnviada = false,
    required this.fechaArqueo,
  });

  @override
  List<Object?> get props => [
        id,
        cajaId,
        tipo,
        diferencia,
        fechaArqueo,
      ];
}
