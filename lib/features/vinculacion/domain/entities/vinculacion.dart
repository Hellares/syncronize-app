import 'package:equatable/equatable.dart';

class VinculacionEmpresa extends Equatable {
  final String id;
  final String empresaSolicitanteId;
  final String empresaVinculadaId;
  final String clienteEmpresaId;
  final String estado;
  final String? mensaje;
  final String? motivoRechazo;
  final DateTime fechaSolicitud;
  final DateTime? fechaRespuesta;

  // Relaciones
  final EmpresaVinculable? empresaSolicitante;
  final EmpresaVinculable? empresaVinculada;
  final ClienteEmpresaResumen? clienteEmpresa;

  const VinculacionEmpresa({
    required this.id,
    required this.empresaSolicitanteId,
    required this.empresaVinculadaId,
    required this.clienteEmpresaId,
    required this.estado,
    this.mensaje,
    this.motivoRechazo,
    required this.fechaSolicitud,
    this.fechaRespuesta,
    this.empresaSolicitante,
    this.empresaVinculada,
    this.clienteEmpresa,
  });

  bool get isPendiente => estado == 'PENDIENTE';
  bool get isAceptada => estado == 'ACEPTADA';
  bool get isRechazada => estado == 'RECHAZADA';
  bool get isCancelada => estado == 'CANCELADA';
  bool get isDesvinculada => estado == 'DESVINCULADA';

  @override
  List<Object?> get props => [id, estado];
}

class EmpresaVinculable extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? rubro;
  final String? telefono;
  final String? email;
  final String? direccionFiscal;

  const EmpresaVinculable({
    required this.id,
    required this.nombre,
    this.logo,
    this.rubro,
    this.telefono,
    this.email,
    this.direccionFiscal,
  });

  @override
  List<Object?> get props => [id];
}

class ClienteEmpresaResumen extends Equatable {
  final String id;
  final String razonSocial;
  final String? nombreComercial;
  final String numeroDocumento;
  final String? email;
  final String? telefono;

  const ClienteEmpresaResumen({
    required this.id,
    required this.razonSocial,
    this.nombreComercial,
    required this.numeroDocumento,
    this.email,
    this.telefono,
  });

  @override
  List<Object?> get props => [id];
}

class VinculacionesPaginadas {
  final List<VinculacionEmpresa> data;
  final int total;
  final int page;
  final int totalPages;

  const VinculacionesPaginadas({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
