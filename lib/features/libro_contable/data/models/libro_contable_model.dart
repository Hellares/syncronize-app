import '../../domain/entities/libro_contable.dart';

class LibroContableModel {
  final List<MovimientoContableModel> movimientos;
  final ResumenContableModel resumen;

  const LibroContableModel({
    required this.movimientos,
    required this.resumen,
  });

  factory LibroContableModel.fromJson(Map<String, dynamic> json) {
    final movimientosList = json['movimientos'] as List<dynamic>? ?? [];
    final resumenMap = json['resumen'] as Map<String, dynamic>? ?? {};

    return LibroContableModel(
      movimientos: movimientosList
          .map((e) => MovimientoContableModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      resumen: ResumenContableModel.fromJson(resumenMap),
    );
  }

  LibroContable toEntity() {
    return LibroContable(
      movimientos: movimientos.map((m) => m.toEntity()).toList(),
      resumen: resumen.toEntity(),
    );
  }
}

class MovimientoContableModel {
  final String id;
  final String tipo;
  final String descripcion;
  final double monto;
  final DateTime? fecha;
  final double? saldoAcumulado;
  final String? categoria;
  final String? referencia;

  const MovimientoContableModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.monto,
    this.fecha,
    this.saldoAcumulado,
    this.categoria,
    this.referencia,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory MovimientoContableModel.fromJson(Map<String, dynamic> json) {
    return MovimientoContableModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      monto: _toDouble(json['monto']),
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'].toString()) : null,
      saldoAcumulado: json['saldoAcumulado'] != null ? _toDouble(json['saldoAcumulado']) : null,
      categoria: json['categoria']?.toString(),
      referencia: json['referencia']?.toString(),
    );
  }

  MovimientoContable toEntity() {
    return MovimientoContable(
      id: id,
      tipo: tipo,
      descripcion: descripcion,
      monto: monto,
      fecha: fecha,
      saldoAcumulado: saldoAcumulado,
      categoria: categoria,
      referencia: referencia,
    );
  }
}

class ResumenContableModel {
  final double totalIngresos;
  final double totalEgresos;
  final double saldoFinal;

  const ResumenContableModel({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoFinal,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory ResumenContableModel.fromJson(Map<String, dynamic> json) {
    return ResumenContableModel(
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      saldoFinal: _toDouble(json['saldo']),
    );
  }

  ResumenContable toEntity() {
    return ResumenContable(
      totalIngresos: totalIngresos,
      totalEgresos: totalEgresos,
      saldoFinal: saldoFinal,
    );
  }
}
