import '../../domain/entities/usuario.dart';

/// Model que extiende de Usuario Entity y maneja serialización JSON
class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.personaId,
    required super.dni,
    required super.nombres,
    required super.apellidos,
    required super.nombreCompleto,
    super.email,
    super.telefono,
    required super.rolEnEmpresa,
    super.rolGlobal,
    required super.isActive,
    required super.emailVerificado,
    required super.telefonoVerificado,
    required super.dniVerificado,
    required super.requiereCambioPassword,
    super.lastLoginAt,
    required super.estado,
    super.registradoPor,
    super.registradoPorNombre,
    required super.creadoEn,
    required super.actualizadoEn,
    super.sedes = const [],
  });

  /// Crea un UsuarioModel desde JSON
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    try {
      return UsuarioModel(
        id: json['id']?.toString() ?? '',
        personaId: json['personaId']?.toString() ?? '',
        dni: json['dni']?.toString() ?? '',
        nombres: json['nombres']?.toString() ?? '',
        apellidos: json['apellidos']?.toString() ?? '',
        nombreCompleto: json['nombreCompleto']?.toString() ?? '',
        email: json['email']?.toString(),
        telefono: json['telefono']?.toString(),
        rolEnEmpresa: json['rolEnEmpresa']?.toString() ?? 'LECTURA',
        rolGlobal: json['rolGlobal']?.toString(),
        isActive: json['isActive'] as bool? ?? true,
        emailVerificado: json['emailVerificado'] as bool? ?? false,
        telefonoVerificado: json['telefonoVerificado'] as bool? ?? false,
        dniVerificado: json['dniVerificado'] as bool? ?? false,
        requiereCambioPassword: json['requiereCambioPassword'] as bool? ?? false,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'].toString())
            : null,
        estado: json['estado']?.toString() ?? 'ACTIVO',
        registradoPor: json['registradoPor']?.toString(),
        registradoPorNombre: json['registradoPorNombre']?.toString(),
        creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? '') ?? DateTime.now(),
        actualizadoEn: DateTime.tryParse(json['actualizadoEn']?.toString() ?? '') ?? DateTime.now(),
        sedes: json['sedes'] != null
            ? (json['sedes'] as List)
                .map((s) => UsuarioSedeModel.fromJson(s as Map<String, dynamic>))
                .toList()
            : [],
      );
    } catch (e) {
      print('Error en UsuarioModel.fromJson: $e');
      print('JSON recibido: $json');
      rethrow;
    }
  }

  /// Convierte el UsuarioModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personaId': personaId,
      'dni': dni,
      'nombres': nombres,
      'apellidos': apellidos,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'rolEnEmpresa': rolEnEmpresa,
      'rolGlobal': rolGlobal,
      'isActive': isActive,
      'emailVerificado': emailVerificado,
      'telefonoVerificado': telefonoVerificado,
      'dniVerificado': dniVerificado,
      'requiereCambioPassword': requiereCambioPassword,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'estado': estado,
      'registradoPor': registradoPor,
      'registradoPorNombre': registradoPorNombre,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
      'sedes': sedes.map((s) => (s as UsuarioSedeModel).toJson()).toList(),
    };
  }

  /// Convierte el model a entity
  Usuario toEntity() => this;
}

/// Model para UsuarioSede
class UsuarioSedeModel extends UsuarioSede {
  const UsuarioSedeModel({
    required super.id,
    required super.sedeId,
    required super.sedeNombre,
    required super.rol,
    required super.puedeAbrirCaja,
    required super.puedeCerrarCaja,
    super.limiteCreditoVenta,
    super.permisos = const [],
    required super.isActive,
  });

  /// Crea un UsuarioSedeModel desde JSON
  factory UsuarioSedeModel.fromJson(Map<String, dynamic> json) {
    try {
      return UsuarioSedeModel(
        id: json['id']?.toString() ?? '',
        sedeId: json['sedeId']?.toString() ?? '',
        sedeNombre: json['sedeNombre']?.toString() ?? '',
        rol: json['rol']?.toString() ?? 'ASISTENTE',
        puedeAbrirCaja: json['puedeAbrirCaja'] as bool? ?? false,
        puedeCerrarCaja: json['puedeCerrarCaja'] as bool? ?? false,
        limiteCreditoVenta: json['limiteCreditoVenta'] != null
            ? (json['limiteCreditoVenta'] as num?)?.toDouble()
            : null,
        permisos: json['permisos'] != null
            ? List<String>.from(json['permisos'] as List)
            : [],
        isActive: json['isActive'] as bool? ?? true,
      );
    } catch (e) {
      print('Error en UsuarioSedeModel.fromJson: $e');
      print('JSON recibido: $json');
      rethrow;
    }
  }

  /// Convierte el UsuarioSedeModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sedeId': sedeId,
      'sedeNombre': sedeNombre,
      'rol': rol,
      'puedeAbrirCaja': puedeAbrirCaja,
      'puedeCerrarCaja': puedeCerrarCaja,
      'limiteCreditoVenta': limiteCreditoVenta,
      'permisos': permisos,
      'isActive': isActive,
    };
  }

  /// Convierte el model a entity
  UsuarioSede toEntity() => this;
}
