import 'package:equatable/equatable.dart';

class TipoCambio extends Equatable {
  final String? id;
  final double compra;
  final double venta;
  final DateTime fecha;
  final String? fuente;

  const TipoCambio({
    this.id,
    required this.compra,
    required this.venta,
    required this.fecha,
    this.fuente,
  });

  @override
  List<Object?> get props => [id, compra, venta, fecha, fuente];
}

class ConfiguracionMoneda extends Equatable {
  final String monedaPrincipal;
  final String simboloMoneda;
  final List<String> monedasPermitidas;

  const ConfiguracionMoneda({
    required this.monedaPrincipal,
    required this.simboloMoneda,
    required this.monedasPermitidas,
  });

  bool get soportaUSD => monedasPermitidas.contains('USD');

  @override
  List<Object?> get props => [monedaPrincipal, simboloMoneda, monedasPermitidas];
}
