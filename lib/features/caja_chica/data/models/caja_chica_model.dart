import '../../domain/entities/caja_chica.dart';

class CajaChicaModel extends CajaChica {
  const CajaChicaModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.sedeNombre,
    required super.nombre,
    required super.fondoFijo,
    required super.saldoActual,
    required super.umbralAlerta,
    required super.estado,
    required super.responsableId,
    required super.responsableNombre,
  });

  factory CajaChicaModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final responsable = json['responsable'] as Map<String, dynamic>?;

    String responsableNombre = '';
    if (responsable != null) {
      final persona = responsable['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        responsableNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (responsableNombre.isEmpty) {
        responsableNombre = responsable['email'] as String? ?? '';
      }
    }
    if (responsableNombre.isEmpty) {
      responsableNombre = json['responsableNombre'] as String? ?? '';
    }

    return CajaChicaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      sedeNombre:
          sede?['nombre'] as String? ?? json['sedeNombre'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      fondoFijo: _toDouble(json['fondoFijo']),
      saldoActual: _toDouble(json['saldoActual']),
      umbralAlerta: _toDouble(json['umbralAlerta']),
      estado: EstadoCajaChica.fromString(json['estado'] as String? ?? ''),
      responsableId: json['responsableId'] as String? ?? '',
      responsableNombre: responsableNombre,
    );
  }

  CajaChica toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
