import '../../domain/entities/vinculacion.dart';

class VinculacionEmpresaModel extends VinculacionEmpresa {
  const VinculacionEmpresaModel({
    required super.id,
    required super.empresaSolicitanteId,
    required super.empresaVinculadaId,
    required super.clienteEmpresaId,
    required super.estado,
    super.mensaje,
    super.motivoRechazo,
    required super.fechaSolicitud,
    super.fechaRespuesta,
    super.empresaSolicitante,
    super.empresaVinculada,
    super.clienteEmpresa,
  });

  factory VinculacionEmpresaModel.fromJson(Map<String, dynamic> json) {
    return VinculacionEmpresaModel(
      id: json['id'] as String,
      empresaSolicitanteId: json['empresaSolicitanteId'] as String,
      empresaVinculadaId: json['empresaVinculadaId'] as String,
      clienteEmpresaId: json['clienteEmpresaId'] as String,
      estado: json['estado'] as String,
      mensaje: json['mensaje'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      fechaRespuesta: json['fechaRespuesta'] != null
          ? DateTime.parse(json['fechaRespuesta'] as String)
          : null,
      empresaSolicitante: json['empresaSolicitante'] != null
          ? EmpresaVinculableModel.fromJson(
              json['empresaSolicitante'] as Map<String, dynamic>)
          : null,
      empresaVinculada: json['empresaVinculada'] != null
          ? EmpresaVinculableModel.fromJson(
              json['empresaVinculada'] as Map<String, dynamic>)
          : null,
      clienteEmpresa: json['clienteEmpresa'] != null
          ? ClienteEmpresaResumenModel.fromJson(
              json['clienteEmpresa'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EmpresaVinculableModel extends EmpresaVinculable {
  const EmpresaVinculableModel({
    required super.id,
    required super.nombre,
    super.logo,
    super.rubro,
    super.telefono,
    super.email,
    super.direccionFiscal,
  });

  factory EmpresaVinculableModel.fromJson(Map<String, dynamic> json) {
    return EmpresaVinculableModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      rubro: json['rubro'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccionFiscal: json['direccionFiscal'] as String?,
    );
  }
}

class ClienteEmpresaResumenModel extends ClienteEmpresaResumen {
  const ClienteEmpresaResumenModel({
    required super.id,
    required super.razonSocial,
    super.nombreComercial,
    required super.numeroDocumento,
    super.email,
    super.telefono,
  });

  factory ClienteEmpresaResumenModel.fromJson(Map<String, dynamic> json) {
    return ClienteEmpresaResumenModel(
      id: json['id'] as String,
      razonSocial: json['razonSocial'] as String? ?? '',
      nombreComercial: json['nombreComercial'] as String?,
      numeroDocumento: json['numeroDocumento'] as String? ?? '',
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
    );
  }
}
