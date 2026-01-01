import '../../domain/entities/politica_descuento.dart';
import '../../domain/entities/usuario_descuento.dart';

class UsuarioDescuentoModel extends UsuarioDescuento {
  const UsuarioDescuentoModel({
    required super.id,
    required super.usuarioId,
    required super.politicaId,
    required super.empresaId,
    super.esFamiliar,
    super.trabajadorId,
    super.parentesco,
    super.limiteMensualUsos,
    super.usosDisponibles,
    super.documentoVerificacion,
    super.aprobadoPor,
    super.fechaAprobacion,
    super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
    super.usuarioNombre,
    super.trabajadorNombre,
    super.politicaNombre,
  });

  factory UsuarioDescuentoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioDescuentoModel(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      politicaId: json['politicaId'] as String,
      empresaId: json['empresaId'] as String,
      esFamiliar: json['esFamiliar'] as bool? ?? false,
      trabajadorId: json['trabajadorId'] as String?,
      parentesco: json['parentesco'] != null
          ? _parseParentesco(json['parentesco'] as String)
          : null,
      limiteMensualUsos: json['limiteMensualUsos'] as int?,
      usosDisponibles: json['usosDisponibles'] as int?,
      documentoVerificacion: json['documentoVerificacion'] as String?,
      aprobadoPor: json['aprobadoPor'] as String?,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      usuarioNombre: json['usuario']?['nombre'] as String?,
      trabajadorNombre: json['trabajador']?['nombre'] as String?,
      politicaNombre: json['politica']?['nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'politicaId': politicaId,
      'empresaId': empresaId,
      'esFamiliar': esFamiliar,
      'trabajadorId': trabajadorId,
      'parentesco': parentesco != null ? _serializeParentesco(parentesco!) : null,
      'limiteMensualUsos': limiteMensualUsos,
      'usosDisponibles': usosDisponibles,
      'documentoVerificacion': documentoVerificacion,
      'aprobadoPor': aprobadoPor,
      'fechaAprobacion': fechaAprobacion?.toIso8601String(),
      'isActive': isActive,
    };
  }

  static Parentesco _parseParentesco(String value) {
    switch (value) {
      case 'CONYUGE':
        return Parentesco.conyuge;
      case 'HIJO':
        return Parentesco.hijo;
      case 'HIJA':
        return Parentesco.hija;
      case 'PADRE':
        return Parentesco.padre;
      case 'MADRE':
        return Parentesco.madre;
      case 'HERMANO':
        return Parentesco.hermano;
      case 'HERMANA':
        return Parentesco.hermana;
      case 'ABUELO':
        return Parentesco.abuelo;
      case 'ABUELA':
        return Parentesco.abuela;
      case 'NIETO':
        return Parentesco.nieto;
      case 'NIETA':
        return Parentesco.nieta;
      case 'TIO':
        return Parentesco.tio;
      case 'TIA':
        return Parentesco.tia;
      case 'SOBRINO':
        return Parentesco.sobrino;
      case 'SOBRINA':
        return Parentesco.sobrina;
      case 'PRIMO':
        return Parentesco.primo;
      case 'PRIMA':
        return Parentesco.prima;
      default:
        return Parentesco.conyuge;
    }
  }

  static String _serializeParentesco(Parentesco parentesco) {
    switch (parentesco) {
      case Parentesco.conyuge:
        return 'CONYUGE';
      case Parentesco.hijo:
        return 'HIJO';
      case Parentesco.hija:
        return 'HIJA';
      case Parentesco.padre:
        return 'PADRE';
      case Parentesco.madre:
        return 'MADRE';
      case Parentesco.hermano:
        return 'HERMANO';
      case Parentesco.hermana:
        return 'HERMANA';
      case Parentesco.abuelo:
        return 'ABUELO';
      case Parentesco.abuela:
        return 'ABUELA';
      case Parentesco.nieto:
        return 'NIETO';
      case Parentesco.nieta:
        return 'NIETA';
      case Parentesco.tio:
        return 'TIO';
      case Parentesco.tia:
        return 'TIA';
      case Parentesco.sobrino:
        return 'SOBRINO';
      case Parentesco.sobrina:
        return 'SOBRINA';
      case Parentesco.primo:
        return 'PRIMO';
      case Parentesco.prima:
        return 'PRIMA';
    }
  }

  /// Convierte el modelo a entidad del dominio
  UsuarioDescuento toEntity() {
    return UsuarioDescuento(
      id: id,
      usuarioId: usuarioId,
      politicaId: politicaId,
      empresaId: empresaId,
      esFamiliar: esFamiliar,
      trabajadorId: trabajadorId,
      parentesco: parentesco,
      limiteMensualUsos: limiteMensualUsos,
      usosDisponibles: usosDisponibles,
      documentoVerificacion: documentoVerificacion,
      aprobadoPor: aprobadoPor,
      fechaAprobacion: fechaAprobacion,
      isActive: isActive,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      usuarioNombre: usuarioNombre,
      trabajadorNombre: trabajadorNombre,
      politicaNombre: politicaNombre,
    );
  }
}
