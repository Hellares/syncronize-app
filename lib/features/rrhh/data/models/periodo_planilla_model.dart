import '../../domain/entities/periodo_planilla.dart';
import '../../domain/entities/boleta_pago.dart';
import 'boleta_pago_model.dart';

class PeriodoPlanillaModel extends PeriodoPlanilla {
  const PeriodoPlanillaModel({
    required super.id,
    required super.empresaId,
    super.sedeId,
    required super.periodo,
    required super.mes,
    required super.anio,
    required super.fechaInicio,
    required super.fechaFin,
    super.estado,
    super.totalBruto,
    super.totalDescuentos,
    super.totalNeto,
    super.totalAportaciones,
    super.calculadoPorId,
    super.aprobadoPorId,
    super.fechaAprobacion,
    super.observaciones,
    super.sedeNombre,
    super.calculadoPorNombre,
    super.aprobadoPorNombre,
    super.totalBoletas,
    super.boletas,
  });

  factory PeriodoPlanillaModel.fromJson(Map<String, dynamic> json) {
    final sede = json['sede'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;

    // Calculado por
    final calculadoPor = json['calculadoPor'] as Map<String, dynamic>?;
    String? calculadoPorNombre;
    if (calculadoPor != null) {
      final p = calculadoPor['persona'] as Map<String, dynamic>?;
      if (p != null) {
        calculadoPorNombre =
            '${p['nombres'] ?? ''} ${p['apellidos'] ?? ''}'.trim();
      }
    }

    // Aprobado por
    final aprobadoPor = json['aprobadoPor'] as Map<String, dynamic>?;
    String? aprobadoPorNombre;
    if (aprobadoPor != null) {
      final p = aprobadoPor['persona'] as Map<String, dynamic>?;
      if (p != null) {
        aprobadoPorNombre =
            '${p['nombres'] ?? ''} ${p['apellidos'] ?? ''}'.trim();
      }
    }

    // Boletas
    final boletasList = json['boletasPago'] as List?;
    List<BoletaPago>? boletas;
    if (boletasList != null) {
      boletas = boletasList
          .map((e) => BoletaPagoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PeriodoPlanillaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String?,
      periodo: json['periodo'] as String? ?? '',
      mes: json['mes'] as int? ?? 1,
      anio: json['anio'] as int? ?? 2026,
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      estado: EstadoPeriodoPlanilla.fromString(
          json['estado'] as String? ?? 'BORRADOR'),
      totalBruto: _toDoubleNullable(json['totalBruto']),
      totalDescuentos: _toDoubleNullable(json['totalDescuentos']),
      totalNeto: _toDoubleNullable(json['totalNeto']),
      totalAportaciones: _toDoubleNullable(json['totalAportaciones']),
      calculadoPorId: json['calculadoPorId'] as String?,
      aprobadoPorId: json['aprobadoPorId'] as String?,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      observaciones: json['observaciones'] as String?,
      sedeNombre: sede?['nombre'] as String?,
      calculadoPorNombre: calculadoPorNombre,
      aprobadoPorNombre: aprobadoPorNombre,
      totalBoletas: count?['boletasPago'] as int?,
      boletas: boletas,
    );
  }

  PeriodoPlanilla toEntity() => this;

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
