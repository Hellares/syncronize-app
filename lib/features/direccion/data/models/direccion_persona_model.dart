import '../../domain/entities/direccion_persona.dart';

class DireccionPersonaModel extends DireccionPersona {
  const DireccionPersonaModel({
    required super.id,
    required super.personaId,
    required super.tipo,
    super.etiqueta,
    required super.direccion,
    super.referencia,
    super.distrito,
    super.provincia,
    super.departamento,
    super.pais,
    super.coordenadas,
    required super.esPredeterminada,
    required super.creadoEn,
  });

  factory DireccionPersonaModel.fromJson(Map<String, dynamic> json) {
    return DireccionPersonaModel(
      id: json['id'] as String,
      personaId: json['personaId'] as String,
      tipo: json['tipo'] as String? ?? 'ENVIO',
      etiqueta: json['etiqueta'] as String?,
      direccion: json['direccion'] as String,
      referencia: json['referencia'] as String?,
      distrito: json['distrito'] as String?,
      provincia: json['provincia'] as String?,
      departamento: json['departamento'] as String?,
      pais: json['pais'] as String?,
      coordenadas: json['coordenadas'] != null
          ? Map<String, dynamic>.from(json['coordenadas'] as Map)
          : null,
      esPredeterminada: json['esPredeterminada'] as bool? ?? false,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  DireccionPersona toEntity() => this;
}
