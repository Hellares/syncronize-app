import '../../domain/entities/meta_financiera.dart';

class MetaFinancieraModel {
  final String id;
  final String tipo;
  final String nombre;
  final double montoMeta;
  final double montoActual;
  final double porcentaje;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? diasRestantes;
  final double? diferencia;

  const MetaFinancieraModel({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.montoMeta,
    required this.montoActual,
    required this.porcentaje,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.diferencia,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory MetaFinancieraModel.fromJson(Map<String, dynamic> json) {
    return MetaFinancieraModel(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      montoMeta: _toDouble(json['montoMeta']),
      montoActual: _toDouble(json['actual'] ?? json['montoActual']),
      porcentaje: _toDouble(json['porcentaje']),
      estado: json['estado'] as String? ?? 'En progreso',
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.tryParse(json['fechaInicio'].toString())
          : null,
      fechaFin: json['fechaFin'] != null
          ? DateTime.tryParse(json['fechaFin'].toString())
          : null,
      diasRestantes: json['diasRestantes'] as int?,
      diferencia: json['diferencia'] != null ? _toDouble(json['diferencia']) : null,
    );
  }

  MetaFinanciera toEntity() {
    return MetaFinanciera(
      id: id,
      tipo: tipo,
      nombre: nombre,
      montoMeta: montoMeta,
      montoActual: montoActual,
      porcentaje: porcentaje,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      diasRestantes: diasRestantes,
      diferencia: diferencia,
    );
  }
}
