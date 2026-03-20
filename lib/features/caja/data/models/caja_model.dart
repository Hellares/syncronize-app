import '../../domain/entities/caja.dart';

class CajaModel extends Caja {
  const CajaModel({
    required super.id,
    required super.codigo,
    required super.sedeId,
    super.sedeNombre,
    required super.usuarioId,
    super.usuarioNombre,
    required super.montoApertura,
    required super.fechaApertura,
    super.fechaCierre,
    required super.estado,
    super.observaciones,
  });

  factory CajaModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final usuario = json['usuario'] as Map<String, dynamic>?;

    String? usuarioNombre;
    if (usuario != null) {
      final persona = usuario['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        usuarioNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (usuarioNombre == null || usuarioNombre.isEmpty) {
        usuarioNombre = usuario['email'] as String?;
      }
    }

    return CajaModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      sedeId: json['sedeId'] as String,
      sedeNombre: sede?['nombre'] as String? ?? json['sedeNombre'] as String?,
      usuarioId: json['usuarioId'] as String,
      usuarioNombre: usuarioNombre ?? json['usuarioNombre'] as String?,
      montoApertura: _toDouble(json['montoApertura']),
      fechaApertura: DateTime.parse(json['fechaApertura'] as String),
      fechaCierre: json['fechaCierre'] != null
          ? DateTime.parse(json['fechaCierre'] as String)
          : null,
      estado: EstadoCaja.fromString(json['estado'] as String),
      observaciones: json['observaciones'] as String?,
    );
  }

  Caja toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
