import '../../domain/entities/pago_suscripcion.dart';

class PagoSuscripcionModel {
  final String id;
  final String empresaId;
  final String planSuscripcionId;
  final double monto;
  final String moneda;
  final String periodo;
  final String metodoPago;
  final String? referencia;
  final String? notas;
  final String estado;
  final DateTime? fechaPago;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? comprobantePagoUrl;
  final String? planNombre;
  final String? motivoRechazo;
  final DateTime? creadoEn;

  const PagoSuscripcionModel({
    required this.id,
    required this.empresaId,
    required this.planSuscripcionId,
    required this.monto,
    required this.moneda,
    required this.periodo,
    required this.metodoPago,
    this.referencia,
    this.notas,
    required this.estado,
    this.fechaPago,
    this.fechaInicio,
    this.fechaFin,
    this.comprobantePagoUrl,
    this.planNombre,
    this.motivoRechazo,
    this.creadoEn,
  });

  factory PagoSuscripcionModel.fromJson(Map<String, dynamic> json) {
    return PagoSuscripcionModel(
      id: json['id'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      planSuscripcionId: json['planSuscripcionId'] as String? ?? '',
      monto: _toDouble(json['monto']),
      moneda: json['moneda'] as String? ?? 'USD',
      periodo: json['periodo'] as String? ?? 'MENSUAL',
      metodoPago: json['metodoPago'] as String? ?? '',
      referencia: json['referencia'] as String?,
      notas: json['notas'] as String?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      fechaPago: _parseDate(json['fechaPago']),
      fechaInicio: _parseDate(json['fechaInicio']),
      fechaFin: _parseDate(json['fechaFin']),
      comprobantePagoUrl: json['comprobantePagoUrl'] as String?,
      planNombre: _extractPlanNombre(json),
      motivoRechazo: json['motivoRechazo'] as String?,
      creadoEn: _parseDate(json['creadoEn']),
    );
  }

  PagoSuscripcion toEntity() {
    return PagoSuscripcion(
      id: id,
      empresaId: empresaId,
      planSuscripcionId: planSuscripcionId,
      monto: monto,
      moneda: moneda,
      periodo: periodo,
      metodoPago: metodoPago,
      referencia: referencia,
      notas: notas,
      estado: estado,
      fechaPago: fechaPago,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      comprobantePagoUrl: comprobantePagoUrl,
      planNombre: planNombre,
      motivoRechazo: motivoRechazo,
      creadoEn: creadoEn,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _extractPlanNombre(Map<String, dynamic> json) {
    // Puede venir como campo directo o dentro del objeto planSuscripcion
    if (json['planNombre'] != null) return json['planNombre'] as String;
    final plan = json['planSuscripcion'];
    if (plan is Map<String, dynamic>) {
      return plan['nombre'] as String?;
    }
    return null;
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
