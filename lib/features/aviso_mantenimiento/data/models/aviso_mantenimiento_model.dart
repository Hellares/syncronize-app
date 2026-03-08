import '../../domain/entities/aviso_mantenimiento.dart';

class AvisoMantenimientoModel extends AvisoMantenimiento {
  const AvisoMantenimientoModel({
    required super.id,
    required super.empresaId,
    required super.ordenServicioId,
    required super.clienteId,
    required super.tipoServicio,
    super.equipoDescripcion,
    required super.fechaUltimoServicio,
    required super.fechaRecomendada,
    required super.estado,
    super.ordenGeneradaId,
    super.notificadoEn,
    super.notas,
    required super.creadoEn,
    required super.actualizadoEn,
    super.cliente,
    super.ordenServicio,
  });

  factory AvisoMantenimientoModel.fromJson(Map<String, dynamic> json) {
    return AvisoMantenimientoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      ordenServicioId: json['ordenServicioId'] as String,
      clienteId: json['clienteId'] as String,
      tipoServicio: json['tipoServicio'] as String,
      equipoDescripcion: json['equipoDescripcion'] as String?,
      fechaUltimoServicio: DateTime.parse(json['fechaUltimoServicio'] as String),
      fechaRecomendada: DateTime.parse(json['fechaRecomendada'] as String),
      estado: json['estado'] as String,
      ordenGeneradaId: json['ordenGeneradaId'] as String?,
      notificadoEn: json['notificadoEn'] != null
          ? DateTime.parse(json['notificadoEn'] as String)
          : null,
      notas: json['notas'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      cliente: json['cliente'] != null
          ? AvisoClienteModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      ordenServicio: json['ordenServicio'] != null
          ? AvisoOrdenResumenModel.fromJson(json['ordenServicio'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AvisoClienteModel extends AvisoCliente {
  const AvisoClienteModel({
    required super.id,
    super.nombre,
    super.apellido,
    super.email,
    super.telefono,
  });

  factory AvisoClienteModel.fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return AvisoClienteModel(
      id: json['id'] as String,
      nombre: persona?['nombres'] as String? ?? json['nombre'] as String?,
      apellido: persona?['apellidos'] as String? ?? json['apellido'] as String?,
      email: persona?['email'] as String?,
      telefono: persona?['telefono'] as String?,
    );
  }
}

class AvisoOrdenResumenModel extends AvisoOrdenResumen {
  const AvisoOrdenResumenModel({
    required super.id,
    required super.codigo,
    required super.tipoServicio,
    super.tipoEquipo,
    super.marcaEquipo,
    required super.estado,
  });

  factory AvisoOrdenResumenModel.fromJson(Map<String, dynamic> json) {
    return AvisoOrdenResumenModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      tipoServicio: json['tipoServicio'] as String,
      tipoEquipo: json['tipoEquipo'] as String?,
      marcaEquipo: json['marcaEquipo'] as String?,
      estado: json['estado'] as String,
    );
  }
}

class ConfiguracionAvisoModel extends ConfiguracionAvisoMantenimiento {
  const ConfiguracionAvisoModel({
    super.id,
    required super.empresaId,
    required super.intervalos,
    required super.diasAnticipacion,
    required super.habilitado,
  });

  factory ConfiguracionAvisoModel.fromJson(Map<String, dynamic> json) {
    final rawIntervalos = json['intervalos'] as Map<String, dynamic>;
    final intervalos = rawIntervalos.map((k, v) => MapEntry(k, (v as num).toInt()));

    return ConfiguracionAvisoModel(
      id: json['id'] as String?,
      empresaId: json['empresaId'] as String,
      intervalos: intervalos,
      diasAnticipacion: json['diasAnticipacion'] as int? ?? 7,
      habilitado: json['habilitado'] as bool? ?? true,
    );
  }
}

class AvisoResumenModel extends AvisoResumen {
  const AvisoResumenModel({
    required super.pendientes,
    required super.notificados,
    required super.atendidos,
    required super.proximosSemana,
    required super.totalActivos,
  });

  factory AvisoResumenModel.fromJson(Map<String, dynamic> json) {
    return AvisoResumenModel(
      pendientes: json['pendientes'] as int? ?? 0,
      notificados: json['notificados'] as int? ?? 0,
      atendidos: json['atendidos'] as int? ?? 0,
      proximosSemana: json['proximosSemana'] as int? ?? 0,
      totalActivos: json['totalActivos'] as int? ?? 0,
    );
  }
}
