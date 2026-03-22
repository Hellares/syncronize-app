import '../../domain/entities/tipo_cambio.dart';

class TipoCambioModel {
  final String? id;
  final double compra;
  final double venta;
  final DateTime fecha;
  final String? fuente;

  const TipoCambioModel({
    this.id,
    required this.compra,
    required this.venta,
    required this.fecha,
    this.fuente,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory TipoCambioModel.fromJson(Map<String, dynamic> json) {
    return TipoCambioModel(
      id: json['id'] as String?,
      compra: _toDouble(json['compra']),
      venta: _toDouble(json['venta']),
      fecha: DateTime.parse(json['fecha'] as String),
      fuente: json['fuente'] as String?,
    );
  }

  TipoCambio toEntity() {
    return TipoCambio(
      id: id,
      compra: compra,
      venta: venta,
      fecha: fecha,
      fuente: fuente,
    );
  }
}

class ConfiguracionMonedaModel {
  final String monedaPrincipal;
  final String simboloMoneda;
  final List<String> monedasPermitidas;

  const ConfiguracionMonedaModel({
    required this.monedaPrincipal,
    required this.simboloMoneda,
    required this.monedasPermitidas,
  });

  factory ConfiguracionMonedaModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionMonedaModel(
      monedaPrincipal: json['monedaPrincipal'] as String? ?? 'PEN',
      simboloMoneda: json['simboloMoneda'] as String? ?? 'S/',
      monedasPermitidas: (json['monedasPermitidas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? ['PEN', 'USD'],
    );
  }

  ConfiguracionMoneda toEntity() {
    return ConfiguracionMoneda(
      monedaPrincipal: monedaPrincipal,
      simboloMoneda: simboloMoneda,
      monedasPermitidas: monedasPermitidas,
    );
  }
}
