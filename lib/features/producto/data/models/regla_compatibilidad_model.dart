import 'dart:convert';

import '../../domain/entities/regla_compatibilidad.dart';

class ReglaCompatibilidadModel extends ReglaCompatibilidad {
  const ReglaCompatibilidadModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    super.descripcion,
    required super.atributoOrigenClave,
    required super.categoriaOrigenId,
    required super.atributoDestinoClave,
    required super.categoriaDestinoId,
    required super.tipoValidacion,
    super.mapeoValores,
    required super.isActive,
    super.categoriaOrigenNombre,
    super.categoriaDestinoNombre,
    super.creadoEn,
    super.actualizadoEn,
  });

  factory ReglaCompatibilidadModel.fromJson(Map<String, dynamic> json) {
    // Parse mapeoValores from JSON string or Map
    Map<String, List<String>>? mapeo;
    if (json['mapeoValores'] != null) {
      final raw = json['mapeoValores'];
      Map<String, dynamic> mapeoRaw;
      if (raw is String) {
        mapeoRaw = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        mapeoRaw = raw as Map<String, dynamic>;
      }
      mapeo = mapeoRaw.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e.toString()).toList(),
        ),
      );
    }

    // Parse category names from nested objects
    String? categoriaOrigenNombre;
    if (json['categoriaOrigen'] != null) {
      final cat = json['categoriaOrigen'] as Map<String, dynamic>;
      categoriaOrigenNombre =
          cat['nombreLocal'] ?? cat['nombrePersonalizado'] ?? '';
    }

    String? categoriaDestinoNombre;
    if (json['categoriaDestino'] != null) {
      final cat = json['categoriaDestino'] as Map<String, dynamic>;
      categoriaDestinoNombre =
          cat['nombreLocal'] ?? cat['nombrePersonalizado'] ?? '';
    }

    return ReglaCompatibilidadModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      atributoOrigenClave: json['atributoOrigenClave'] as String,
      categoriaOrigenId: json['categoriaOrigenId'] as String,
      atributoDestinoClave: json['atributoDestinoClave'] as String,
      categoriaDestinoId: json['categoriaDestinoId'] as String,
      tipoValidacion: json['tipoValidacion'] as String? ?? 'IGUAL',
      mapeoValores: mapeo,
      isActive: json['isActive'] as bool? ?? true,
      categoriaOrigenNombre: categoriaOrigenNombre,
      categoriaDestinoNombre: categoriaDestinoNombre,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : null,
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.parse(json['actualizadoEn'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'atributoOrigenClave': atributoOrigenClave,
      'categoriaOrigenId': categoriaOrigenId,
      'atributoDestinoClave': atributoDestinoClave,
      'categoriaDestinoId': categoriaDestinoId,
      'tipoValidacion': tipoValidacion,
      if (mapeoValores != null) 'mapeoValores': mapeoValores,
      'isActive': isActive,
    };
  }

  ReglaCompatibilidad toEntity() => this;
}
