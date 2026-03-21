import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TipoInventario {
  completo, parcial, ciclico, sorpresa, temporal;

  String get label {
    switch (this) {
      case completo: return 'Completo';
      case parcial: return 'Parcial';
      case ciclico: return 'Ciclico';
      case sorpresa: return 'Sorpresa';
      case temporal: return 'Temporal';
    }
  }

  String get apiValue => name.toUpperCase();

  static TipoInventario fromString(String v) {
    switch (v.toUpperCase()) {
      case 'COMPLETO': return completo;
      case 'PARCIAL': return parcial;
      case 'CICLICO': return ciclico;
      case 'SORPRESA': return sorpresa;
      case 'TEMPORAL': return temporal;
      default: return completo;
    }
  }
}

enum EstadoInventario {
  planificado, enProceso, conteoCompleto, enRevision, aprobado, ajustado, cancelado, rechazado;

  String get label {
    switch (this) {
      case planificado: return 'Planificado';
      case enProceso: return 'En Proceso';
      case conteoCompleto: return 'Conteo Completo';
      case enRevision: return 'En Revision';
      case aprobado: return 'Aprobado';
      case ajustado: return 'Ajustado';
      case cancelado: return 'Cancelado';
      case rechazado: return 'Rechazado';
    }
  }

  String get apiValue {
    switch (this) {
      case planificado: return 'PLANIFICADO';
      case enProceso: return 'EN_PROCESO';
      case conteoCompleto: return 'CONTEO_COMPLETO';
      case enRevision: return 'EN_REVISION';
      case aprobado: return 'APROBADO';
      case ajustado: return 'AJUSTADO';
      case cancelado: return 'CANCELADO';
      case rechazado: return 'RECHAZADO';
    }
  }

  Color get color {
    switch (this) {
      case planificado: return Colors.grey;
      case enProceso: return Colors.blue;
      case conteoCompleto: return Colors.orange;
      case enRevision: return Colors.purple;
      case aprobado: return Colors.teal;
      case ajustado: return Colors.green;
      case cancelado: return Colors.red;
      case rechazado: return Colors.red;
    }
  }

  static EstadoInventario fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PLANIFICADO': return planificado;
      case 'EN_PROCESO': return enProceso;
      case 'CONTEO_COMPLETO': return conteoCompleto;
      case 'EN_REVISION': return enRevision;
      case 'APROBADO': return aprobado;
      case 'AJUSTADO': return ajustado;
      case 'CANCELADO': return cancelado;
      case 'RECHAZADO': return rechazado;
      default: return planificado;
    }
  }
}

class Inventario extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final TipoInventario tipoInventario;
  final EstadoInventario estado;
  final String sedeId;
  final String? sedeNombre;
  final String? responsableNombre;
  final DateTime? fechaPlanificada;
  final DateTime? fechaInicio;
  final DateTime? fechaFinConteo;
  final int totalProductosEsperados;
  final int totalProductosContados;
  final int totalDiferencias;
  final int totalSobrantes;
  final int totalFaltantes;
  final String? observaciones;
  final List<InventarioItem>? items;
  final DateTime creadoEn;

  const Inventario({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipoInventario,
    required this.estado,
    required this.sedeId,
    this.sedeNombre,
    this.responsableNombre,
    this.fechaPlanificada,
    this.fechaInicio,
    this.fechaFinConteo,
    this.totalProductosEsperados = 0,
    this.totalProductosContados = 0,
    this.totalDiferencias = 0,
    this.totalSobrantes = 0,
    this.totalFaltantes = 0,
    this.observaciones,
    this.items,
    required this.creadoEn,
  });

  double get progreso => totalProductosEsperados > 0
      ? totalProductosContados / totalProductosEsperados
      : 0;

  @override
  List<Object?> get props => [id, codigo, estado, totalProductosContados];
}

class InventarioItem extends Equatable {
  final String id;
  final String? productoStockId;
  final String nombreProducto;
  final String? codigoProducto;
  final String? codigoBarras;
  final int cantidadSistema;
  final int? cantidadContada;
  final int? diferencia;
  final bool esDiferencia;
  final String? tipoRestante; // SOBRANTE, FALTANTE, SIN_DIFERENCIA
  final String estadoConteo; // PENDIENTE, CONTADO, VERIFICADO, EN_REVISION, AJUSTADO
  final String? ubicacionFisica;
  final String? observaciones;
  final bool ajusteAplicado;

  const InventarioItem({
    required this.id,
    this.productoStockId,
    required this.nombreProducto,
    this.codigoProducto,
    this.codigoBarras,
    required this.cantidadSistema,
    this.cantidadContada,
    this.diferencia,
    this.esDiferencia = false,
    this.tipoRestante,
    required this.estadoConteo,
    this.ubicacionFisica,
    this.observaciones,
    this.ajusteAplicado = false,
  });

  bool get pendiente => estadoConteo == 'PENDIENTE';
  bool get contado => estadoConteo != 'PENDIENTE';

  @override
  List<Object?> get props => [id, estadoConteo, cantidadContada, codigoBarras];
}
