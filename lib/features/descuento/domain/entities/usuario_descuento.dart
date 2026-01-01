import 'package:equatable/equatable.dart';
import 'politica_descuento.dart';

class UsuarioDescuento extends Equatable {
  final String id;
  final String usuarioId;
  final String politicaId;
  final String empresaId;
  final bool esFamiliar;
  final String? trabajadorId;
  final Parentesco? parentesco;
  final int? limiteMensualUsos;
  final int? usosDisponibles;
  final String? documentoVerificacion;
  final String? aprobadoPor;
  final DateTime? fechaAprobacion;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Datos relacionados (cuando se incluyen)
  final String? usuarioNombre;
  final String? trabajadorNombre;
  final String? politicaNombre;

  const UsuarioDescuento({
    required this.id,
    required this.usuarioId,
    required this.politicaId,
    required this.empresaId,
    this.esFamiliar = false,
    this.trabajadorId,
    this.parentesco,
    this.limiteMensualUsos,
    this.usosDisponibles,
    this.documentoVerificacion,
    this.aprobadoPor,
    this.fechaAprobacion,
    this.isActive = true,
    required this.creadoEn,
    required this.actualizadoEn,
    this.usuarioNombre,
    this.trabajadorNombre,
    this.politicaNombre,
  });

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        politicaId,
        empresaId,
        esFamiliar,
        trabajadorId,
        parentesco,
        limiteMensualUsos,
        usosDisponibles,
        documentoVerificacion,
        aprobadoPor,
        fechaAprobacion,
        isActive,
        creadoEn,
        actualizadoEn,
        usuarioNombre,
        trabajadorNombre,
        politicaNombre,
      ];

  UsuarioDescuento copyWith({
    String? id,
    String? usuarioId,
    String? politicaId,
    String? empresaId,
    bool? esFamiliar,
    String? trabajadorId,
    Parentesco? parentesco,
    int? limiteMensualUsos,
    int? usosDisponibles,
    String? documentoVerificacion,
    String? aprobadoPor,
    DateTime? fechaAprobacion,
    bool? isActive,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    String? usuarioNombre,
    String? trabajadorNombre,
    String? politicaNombre,
  }) {
    return UsuarioDescuento(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      politicaId: politicaId ?? this.politicaId,
      empresaId: empresaId ?? this.empresaId,
      esFamiliar: esFamiliar ?? this.esFamiliar,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      parentesco: parentesco ?? this.parentesco,
      limiteMensualUsos: limiteMensualUsos ?? this.limiteMensualUsos,
      usosDisponibles: usosDisponibles ?? this.usosDisponibles,
      documentoVerificacion:
          documentoVerificacion ?? this.documentoVerificacion,
      aprobadoPor: aprobadoPor ?? this.aprobadoPor,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      isActive: isActive ?? this.isActive,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      trabajadorNombre: trabajadorNombre ?? this.trabajadorNombre,
      politicaNombre: politicaNombre ?? this.politicaNombre,
    );
  }
}
