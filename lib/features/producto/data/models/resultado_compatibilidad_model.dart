import '../../domain/entities/resultado_compatibilidad.dart';

class ResultadoCompatibilidadModel extends ResultadoCompatibilidad {
  const ResultadoCompatibilidadModel({
    required super.compatible,
    required super.conflictos,
  });

  factory ResultadoCompatibilidadModel.fromJson(Map<String, dynamic> json) {
    final conflictosJson = json['conflictos'] as List<dynamic>? ?? [];

    return ResultadoCompatibilidadModel(
      compatible: json['compatible'] as bool? ?? true,
      conflictos: conflictosJson
          .map((e) =>
              ConflictoCompatibilidadModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ResultadoCompatibilidad toEntity() => this;
}

class ConflictoCompatibilidadModel extends ConflictoCompatibilidad {
  const ConflictoCompatibilidadModel({
    required super.reglaId,
    required super.reglaNombre,
    required super.productoOrigenId,
    required super.productoOrigenNombre,
    required super.productoDestinoId,
    required super.productoDestinoNombre,
    required super.atributoClave,
    required super.valorOrigen,
    required super.valorDestino,
    required super.mensaje,
  });

  factory ConflictoCompatibilidadModel.fromJson(Map<String, dynamic> json) {
    final regla = json['regla'] as Map<String, dynamic>? ?? {};
    final productoOrigen =
        json['productoOrigen'] as Map<String, dynamic>? ?? {};
    final productoDestino =
        json['productoDestino'] as Map<String, dynamic>? ?? {};

    return ConflictoCompatibilidadModel(
      reglaId: regla['id'] as String? ?? '',
      reglaNombre: regla['nombre'] as String? ?? '',
      productoOrigenId: productoOrigen['id'] as String? ?? '',
      productoOrigenNombre: productoOrigen['nombre'] as String? ?? '',
      productoDestinoId: productoDestino['id'] as String? ?? '',
      productoDestinoNombre: productoDestino['nombre'] as String? ?? '',
      atributoClave: json['atributoClave'] as String? ?? '',
      valorOrigen: json['valorOrigen'] as String? ?? '',
      valorDestino: json['valorDestino'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
    );
  }
}
