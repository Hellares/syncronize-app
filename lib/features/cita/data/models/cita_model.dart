import '../../domain/entities/cita.dart';

class CitaModel extends Cita {
  const CitaModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.servicioId,
    required super.tecnicoId,
    super.clienteId,
    super.clienteEmpresaId,
    required super.codigo,
    required super.fecha,
    required super.horaInicio,
    required super.horaFin,
    required super.estado,
    super.notas,
    super.ordenServicioId,
    super.creadoPor,
    super.canceladoPor,
    super.motivoCancelacion,
    required super.creadoEn,
    required super.actualizadoEn,
    super.servicio,
    super.tecnico,
    super.cliente,
    super.clienteEmpresa,
    super.sede,
    super.ordenServicio,
  });

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    return CitaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      servicioId: json['servicioId'] as String,
      tecnicoId: json['tecnicoId'] as String,
      clienteId: json['clienteId'] as String?,
      clienteEmpresaId: json['clienteEmpresaId'] as String?,
      codigo: json['codigo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
      estado: json['estado'] as String,
      notas: json['notas'] as String?,
      ordenServicioId: json['ordenServicioId'] as String?,
      creadoPor: json['creadoPor'] as String?,
      canceladoPor: json['canceladoPor'] as String?,
      motivoCancelacion: json['motivoCancelacion'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      servicio: json['servicio'] != null
          ? _parseServicio(json['servicio'] as Map<String, dynamic>)
          : null,
      tecnico: json['tecnico'] != null
          ? _parseTecnico(json['tecnico'] as Map<String, dynamic>)
          : null,
      cliente: json['cliente'] != null
          ? _parseCliente(json['cliente'] as Map<String, dynamic>)
          : null,
      clienteEmpresa: json['clienteEmpresa'] != null
          ? _parseClienteEmpresa(json['clienteEmpresa'] as Map<String, dynamic>)
          : null,
      sede: json['sede'] != null
          ? _parseSede(json['sede'] as Map<String, dynamic>)
          : null,
      ordenServicio: json['ordenServicio'] != null
          ? _parseOrdenServicio(json['ordenServicio'] as Map<String, dynamic>)
          : null,
    );
  }

  static CitaServicioResumen _parseServicio(Map<String, dynamic> json) {
    return CitaServicioResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      duracionMinutos: json['duracionMinutos'] as int?,
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString())
          : null,
    );
  }

  static CitaTecnicoResumen _parseTecnico(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return CitaTecnicoResumen(
      id: json['id'] as String,
      nombres: persona?['nombres'] as String? ?? '',
      apellidos: persona?['apellidos'] as String? ?? '',
    );
  }

  static CitaClienteResumen _parseCliente(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return CitaClienteResumen(
      id: json['id'] as String,
      nombres: persona?['nombres'] as String? ?? '',
      apellidos: persona?['apellidos'] as String? ?? '',
      telefono: persona?['telefono'] as String?,
      email: persona?['email'] as String?,
    );
  }

  static CitaClienteEmpresaResumen _parseClienteEmpresa(
      Map<String, dynamic> json) {
    return CitaClienteEmpresaResumen(
      id: json['id'] as String,
      razonSocial: json['razonSocial'] as String,
      nombreComercial: json['nombreComercial'] as String?,
      telefono: json['telefono'] as String?,
    );
  }

  static CitaSedeResumen _parseSede(Map<String, dynamic> json) {
    return CitaSedeResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String? ?? '',
    );
  }

  static CitaOrdenResumen _parseOrdenServicio(Map<String, dynamic> json) {
    return CitaOrdenResumen(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      estado: json['estado'] as String,
    );
  }

  Cita toEntity() => this;
}
