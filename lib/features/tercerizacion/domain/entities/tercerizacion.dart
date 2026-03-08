import 'package:equatable/equatable.dart';

class TercerizacionServicio extends Equatable {
  final String id;
  final String empresaOrigenId;
  final String ordenOrigenId;
  final String empresaDestinoId;
  final String? ordenDestinoId;
  final String estado;
  final Map<String, dynamic> datosEquipo;
  final String? descripcionProblema;
  final dynamic sintomas;
  final dynamic componentesData;
  final double? precioB2B;
  final String? metodoPagoB2B;
  final String? notasOrigen;
  final String? notasDestino;
  final String? motivoRechazo;
  final DateTime fechaSolicitud;
  final DateTime? fechaRespuesta;
  final DateTime? fechaCompletado;

  // Relaciones
  final EmpresaResumen? empresaOrigen;
  final EmpresaResumen? empresaDestino;
  final OrdenResumen? ordenOrigen;
  final OrdenResumen? ordenDestino;

  const TercerizacionServicio({
    required this.id,
    required this.empresaOrigenId,
    required this.ordenOrigenId,
    required this.empresaDestinoId,
    this.ordenDestinoId,
    required this.estado,
    required this.datosEquipo,
    this.descripcionProblema,
    this.sintomas,
    this.componentesData,
    this.precioB2B,
    this.metodoPagoB2B,
    this.notasOrigen,
    this.notasDestino,
    this.motivoRechazo,
    required this.fechaSolicitud,
    this.fechaRespuesta,
    this.fechaCompletado,
    this.empresaOrigen,
    this.empresaDestino,
    this.ordenOrigen,
    this.ordenDestino,
  });

  bool get isPendiente => estado == 'PENDIENTE';
  bool get isAceptado => estado == 'ACEPTADO';
  bool get isCompletado => estado == 'COMPLETADO';
  bool get isRechazado => estado == 'RECHAZADO';
  bool get isCancelado => estado == 'CANCELADO';

  @override
  List<Object?> get props => [id, estado];
}

class EmpresaResumen extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? telefono;
  final String? email;
  final String? rubro;
  final String? direccionFiscal;
  final String? departamento;
  final String? provincia;
  final String? distrito;

  const EmpresaResumen({
    required this.id,
    required this.nombre,
    this.logo,
    this.telefono,
    this.email,
    this.rubro,
    this.direccionFiscal,
    this.departamento,
    this.provincia,
    this.distrito,
  });

  @override
  List<Object?> get props => [id];
}

class OrdenResumen extends Equatable {
  final String id;
  final String codigo;
  final String? tipoEquipo;
  final String? marcaEquipo;
  final String? estado;
  final String? tipoServicio;
  final String? prioridad;
  final String? descripcionProblema;
  final double? costoTotal;

  const OrdenResumen({
    required this.id,
    required this.codigo,
    this.tipoEquipo,
    this.marcaEquipo,
    this.estado,
    this.tipoServicio,
    this.prioridad,
    this.descripcionProblema,
    this.costoTotal,
  });

  @override
  List<Object?> get props => [id];
}

class TercerizacionesPaginadas {
  final List<TercerizacionServicio> data;
  final int total;
  final int page;
  final int totalPages;

  const TercerizacionesPaginadas({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
