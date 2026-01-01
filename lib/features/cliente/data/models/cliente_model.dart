import '../../domain/entities/cliente.dart';

/// Model que representa un cliente (extends Entity)
class ClienteModel extends Cliente {
  const ClienteModel({
    required super.id,
    required super.personaId,
    super.usuarioId,
    required super.dni,
    required super.nombres,
    required super.apellidos,
    required super.nombreCompleto,
    required super.telefono,
    super.email,
    super.direccion,
    super.distrito,
    super.provincia,
    super.departamento,
    required super.isActive,
    required super.estado,
    super.emailVerificado,
    super.telefonoVerificado,
    super.dniVerificado,
    required super.yaExistiaEnSistema,
    super.registradoPor,
    super.registradoPorNombre,
    required super.fechaRegistro,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  /// Crea una instancia desde JSON
  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'] as String,
      personaId: json['personaId'] as String,
      usuarioId: json['usuarioId'] as String?,
      dni: json['dni'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      distrito: json['distrito'] as String?,
      provincia: json['provincia'] as String?,
      departamento: json['departamento'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      estado: json['estado'] as String? ?? 'ACTIVO',
      emailVerificado: json['emailVerificado'] as bool?,
      telefonoVerificado: json['telefonoVerificado'] as bool?,
      dniVerificado: json['dniVerificado'] as bool?,
      yaExistiaEnSistema: json['yaExistiaEnSistema'] as bool? ?? false,
      registradoPor: json['registradoPor'] as String?,
      registradoPorNombre: json['registradoPorNombre'] as String?,
      fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personaId': personaId,
      'usuarioId': usuarioId,
      'dni': dni,
      'nombres': nombres,
      'apellidos': apellidos,
      'nombreCompleto': nombreCompleto,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'distrito': distrito,
      'provincia': provincia,
      'departamento': departamento,
      'isActive': isActive,
      'estado': estado,
      'emailVerificado': emailVerificado,
      'telefonoVerificado': telefonoVerificado,
      'dniVerificado': dniVerificado,
      'yaExistiaEnSistema': yaExistiaEnSistema,
      'registradoPor': registradoPor,
      'registradoPorNombre': registradoPorNombre,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  /// Convierte a Entity (ya es una entity, solo retorna this)
  Cliente toEntity() => this;
}
