import '../../domain/entities/tercerizacion.dart';

class TercerizacionServicioModel extends TercerizacionServicio {
  TercerizacionServicioModel({
    required super.id,
    required super.empresaOrigenId,
    required super.ordenOrigenId,
    required super.empresaDestinoId,
    super.ordenDestinoId,
    required super.estado,
    required super.datosEquipo,
    super.descripcionProblema,
    super.sintomas,
    super.componentesData,
    super.precioB2B,
    super.metodoPagoB2B,
    super.notasOrigen,
    super.notasDestino,
    super.motivoRechazo,
    required super.fechaSolicitud,
    super.fechaRespuesta,
    super.fechaCompletado,
    super.empresaOrigen,
    super.empresaDestino,
    super.ordenOrigen,
    super.ordenDestino,
  });

  factory TercerizacionServicioModel.fromJson(Map<String, dynamic> json) {
    return TercerizacionServicioModel(
      id: json['id'] as String,
      empresaOrigenId: json['empresaOrigenId'] as String,
      ordenOrigenId: json['ordenOrigenId'] as String,
      empresaDestinoId: json['empresaDestinoId'] as String,
      ordenDestinoId: json['ordenDestinoId'] as String?,
      estado: json['estado'] as String,
      datosEquipo: json['datosEquipo'] as Map<String, dynamic>? ?? {},
      descripcionProblema: json['descripcionProblema'] as String?,
      sintomas: json['sintomas'],
      componentesData: json['componentesData'],
      precioB2B: json['precioB2B'] != null
          ? double.tryParse(json['precioB2B'].toString())
          : null,
      metodoPagoB2B: json['metodoPagoB2B'] as String?,
      notasOrigen: json['notasOrigen'] as String?,
      notasDestino: json['notasDestino'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      fechaSolicitud: DateTime.parse(json['fechaSolicitud'] as String),
      fechaRespuesta: json['fechaRespuesta'] != null
          ? DateTime.parse(json['fechaRespuesta'] as String)
          : null,
      fechaCompletado: json['fechaCompletado'] != null
          ? DateTime.parse(json['fechaCompletado'] as String)
          : null,
      empresaOrigen: json['empresaOrigen'] != null
          ? EmpresaResumenModel.fromJson(
              json['empresaOrigen'] as Map<String, dynamic>)
          : null,
      empresaDestino: json['empresaDestino'] != null
          ? EmpresaResumenModel.fromJson(
              json['empresaDestino'] as Map<String, dynamic>)
          : null,
      ordenOrigen: json['ordenOrigen'] != null
          ? OrdenResumenModel.fromJson(
              json['ordenOrigen'] as Map<String, dynamic>)
          : null,
      ordenDestino: json['ordenDestino'] != null
          ? OrdenResumenModel.fromJson(
              json['ordenDestino'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EmpresaResumenModel extends EmpresaResumen {
  EmpresaResumenModel({
    required super.id,
    required super.nombre,
    super.logo,
    super.telefono,
    super.email,
    super.rubro,
    super.direccionFiscal,
    super.departamento,
    super.provincia,
    super.distrito,
  });

  factory EmpresaResumenModel.fromJson(Map<String, dynamic> json) {
    return EmpresaResumenModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      rubro: json['rubro'] as String?,
      direccionFiscal: json['direccionFiscal'] as String?,
      departamento: json['departamento'] as String?,
      provincia: json['provincia'] as String?,
      distrito: json['distrito'] as String?,
    );
  }
}

class OrdenResumenModel extends OrdenResumen {
  OrdenResumenModel({
    required super.id,
    required super.codigo,
    super.tipoEquipo,
    super.marcaEquipo,
    super.estado,
    super.tipoServicio,
    super.prioridad,
    super.descripcionProblema,
    super.costoTotal,
  });

  factory OrdenResumenModel.fromJson(Map<String, dynamic> json) {
    return OrdenResumenModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      tipoEquipo: json['tipoEquipo'] as String?,
      marcaEquipo: json['marcaEquipo'] as String?,
      estado: json['estado'] as String?,
      tipoServicio: json['tipoServicio'] as String?,
      prioridad: json['prioridad'] as String?,
      descripcionProblema: json['descripcionProblema'] as String?,
      costoTotal: json['costoTotal'] != null
          ? double.tryParse(json['costoTotal'].toString())
          : null,
    );
  }
}
