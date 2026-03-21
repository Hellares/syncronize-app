import '../../domain/entities/flujo_proyectado.dart';

class PeriodoFlujoModel {
  final String label;
  final double cobrosEsperados;
  final double pagosEsperados;
  final double cuotasPrestamos;
  final double saldoProyectado;
  final double? flujoNeto;

  const PeriodoFlujoModel({
    required this.label,
    required this.cobrosEsperados,
    required this.pagosEsperados,
    required this.cuotasPrestamos,
    required this.saldoProyectado,
    this.flujoNeto,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory PeriodoFlujoModel.fromJson(Map<String, dynamic> json) {
    return PeriodoFlujoModel(
      label: json['label']?.toString() ?? '',
      cobrosEsperados: _toDouble(json['cobrosEsperados']),
      pagosEsperados: _toDouble(json['pagosEsperados']),
      cuotasPrestamos: _toDouble(json['cuotasPrestamos']),
      saldoProyectado: _toDouble(json['saldoProyectado']),
      flujoNeto: json['flujoNeto'] != null ? _toDouble(json['flujoNeto']) : null,
    );
  }

  PeriodoFlujo toEntity() {
    return PeriodoFlujo(
      label: label,
      cobrosEsperados: cobrosEsperados,
      pagosEsperados: pagosEsperados,
      cuotasPrestamos: cuotasPrestamos,
      saldoProyectado: saldoProyectado,
      flujoNeto: flujoNeto,
    );
  }
}
