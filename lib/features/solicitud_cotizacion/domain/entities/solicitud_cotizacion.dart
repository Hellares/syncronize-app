import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estados posibles de una solicitud de cotizacion
enum EstadoSolicitudCotizacion {
  pendiente,
  enRevision,
  cotizada,
  rechazada,
  cancelada,
  vencida;

  String get label {
    switch (this) {
      case EstadoSolicitudCotizacion.pendiente:
        return 'Pendiente';
      case EstadoSolicitudCotizacion.enRevision:
        return 'En Revision';
      case EstadoSolicitudCotizacion.cotizada:
        return 'Cotizada';
      case EstadoSolicitudCotizacion.rechazada:
        return 'Rechazada';
      case EstadoSolicitudCotizacion.cancelada:
        return 'Cancelada';
      case EstadoSolicitudCotizacion.vencida:
        return 'Vencida';
    }
  }

  Color get color {
    switch (this) {
      case EstadoSolicitudCotizacion.pendiente:
        return const Color(0xFFFF9800);
      case EstadoSolicitudCotizacion.enRevision:
        return const Color(0xFF2196F3);
      case EstadoSolicitudCotizacion.cotizada:
        return const Color(0xFF4CAF50);
      case EstadoSolicitudCotizacion.rechazada:
        return const Color(0xFFF44336);
      case EstadoSolicitudCotizacion.cancelada:
        return const Color(0xFF9E9E9E);
      case EstadoSolicitudCotizacion.vencida:
        return const Color(0xFF795548);
    }
  }

  bool get puedeCancelar {
    return this == EstadoSolicitudCotizacion.pendiente ||
        this == EstadoSolicitudCotizacion.enRevision;
  }

  String get apiValue {
    switch (this) {
      case EstadoSolicitudCotizacion.pendiente:
        return 'PENDIENTE';
      case EstadoSolicitudCotizacion.enRevision:
        return 'EN_REVISION';
      case EstadoSolicitudCotizacion.cotizada:
        return 'COTIZADA';
      case EstadoSolicitudCotizacion.rechazada:
        return 'RECHAZADA';
      case EstadoSolicitudCotizacion.cancelada:
        return 'CANCELADA';
      case EstadoSolicitudCotizacion.vencida:
        return 'VENCIDA';
    }
  }

  static EstadoSolicitudCotizacion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE':
        return EstadoSolicitudCotizacion.pendiente;
      case 'EN_REVISION':
        return EstadoSolicitudCotizacion.enRevision;
      case 'COTIZADA':
        return EstadoSolicitudCotizacion.cotizada;
      case 'RECHAZADA':
        return EstadoSolicitudCotizacion.rechazada;
      case 'CANCELADA':
        return EstadoSolicitudCotizacion.cancelada;
      case 'VENCIDA':
        return EstadoSolicitudCotizacion.vencida;
      default:
        return EstadoSolicitudCotizacion.pendiente;
    }
  }
}

/// Item de una solicitud de cotizacion
class SolicitudItem extends Equatable {
  final String? id;
  final String descripcion;
  final int cantidad;
  final String? imagenUrl;
  final bool esManual;
  final String? notasItem;
  final String? productoId;
  final String? varianteId;

  const SolicitudItem({
    this.id,
    required this.descripcion,
    required this.cantidad,
    this.imagenUrl,
    this.esManual = false,
    this.notasItem,
    this.productoId,
    this.varianteId,
  });

  @override
  List<Object?> get props => [
        id,
        descripcion,
        cantidad,
        imagenUrl,
        esManual,
        notasItem,
        productoId,
        varianteId,
      ];
}

/// Informacion basica de la empresa en la solicitud
class SolicitudEmpresa extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String subdominio;

  const SolicitudEmpresa({
    required this.id,
    required this.nombre,
    this.logo,
    required this.subdominio,
  });

  @override
  List<Object?> get props => [id, nombre, logo, subdominio];
}

/// Entity principal de solicitud de cotizacion
class SolicitudCotizacion extends Equatable {
  final String id;
  final String codigo;
  final String solicitanteId;
  final String empresaId;
  final String nombreSolicitante;
  final EstadoSolicitudCotizacion estado;
  final String? observaciones;
  final String? respuestaVendedor;
  final String? cotizacionId;
  final SolicitudEmpresa? empresa;
  final List<SolicitudItem> items;
  final dynamic cotizacion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final DateTime? fechaVencimiento;

  const SolicitudCotizacion({
    required this.id,
    required this.codigo,
    required this.solicitanteId,
    required this.empresaId,
    required this.nombreSolicitante,
    required this.estado,
    this.observaciones,
    this.respuestaVendedor,
    this.cotizacionId,
    this.empresa,
    this.items = const [],
    this.cotizacion,
    this.creadoEn,
    this.actualizadoEn,
    this.fechaVencimiento,
  });

  @override
  List<Object?> get props => [
        id,
        codigo,
        solicitanteId,
        empresaId,
        nombreSolicitante,
        estado,
        observaciones,
        respuestaVendedor,
        cotizacionId,
        empresa,
        items,
        cotizacion,
        creadoEn,
        actualizadoEn,
        fechaVencimiento,
      ];
}
