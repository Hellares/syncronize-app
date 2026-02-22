import 'package:equatable/equatable.dart';

/// Entity que representa la configuración fiscal/operativa de una empresa
class ConfiguracionEmpresa extends Equatable {
  final String id;
  final String empresaId;
  final double impuestoDefaultPorcentaje;
  final String nombreImpuesto;
  final String monedaPrincipal;
  final String simboloMoneda;
  final List<String> monedasPermitidas;
  final int diasVigenciaCotizacion;
  final String? condicionesDefault;

  const ConfiguracionEmpresa({
    required this.id,
    required this.empresaId,
    this.impuestoDefaultPorcentaje = 18.0,
    this.nombreImpuesto = 'IGV',
    this.monedaPrincipal = 'PEN',
    this.simboloMoneda = 'S/',
    this.monedasPermitidas = const ['PEN', 'USD'],
    this.diasVigenciaCotizacion = 30,
    this.condicionesDefault,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        impuestoDefaultPorcentaje,
        nombreImpuesto,
        monedaPrincipal,
        simboloMoneda,
        monedasPermitidas,
        diasVigenciaCotizacion,
        condicionesDefault,
      ];

  ConfiguracionEmpresa copyWith({
    String? id,
    String? empresaId,
    double? impuestoDefaultPorcentaje,
    String? nombreImpuesto,
    String? monedaPrincipal,
    String? simboloMoneda,
    List<String>? monedasPermitidas,
    int? diasVigenciaCotizacion,
    String? condicionesDefault,
  }) {
    return ConfiguracionEmpresa(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      impuestoDefaultPorcentaje:
          impuestoDefaultPorcentaje ?? this.impuestoDefaultPorcentaje,
      nombreImpuesto: nombreImpuesto ?? this.nombreImpuesto,
      monedaPrincipal: monedaPrincipal ?? this.monedaPrincipal,
      simboloMoneda: simboloMoneda ?? this.simboloMoneda,
      monedasPermitidas: monedasPermitidas ?? this.monedasPermitidas,
      diasVigenciaCotizacion:
          diasVigenciaCotizacion ?? this.diasVigenciaCotizacion,
      condicionesDefault: condicionesDefault ?? this.condicionesDefault,
    );
  }
}
