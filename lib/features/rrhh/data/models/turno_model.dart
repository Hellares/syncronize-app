import '../../domain/entities/turno.dart';

class TurnoModel extends Turno {
  const TurnoModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    required super.horaInicio,
    required super.horaFin,
    super.duracionAlmuerzoMin,
    super.horasEfectivas,
    super.color,
    super.isDefault,
    super.isActive,
  });

  factory TurnoModel.fromJson(Map<String, dynamic> json) {
    return TurnoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      horaInicio: json['horaInicio'] as String? ?? '',
      horaFin: json['horaFin'] as String? ?? '',
      duracionAlmuerzoMin: json['duracionAlmuerzoMin'] as int? ?? 60,
      horasEfectivas: _toDouble(json['horasEfectivas']),
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Turno toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 8.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 8.0;
    return 8.0;
  }
}
