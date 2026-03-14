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

  // Etiquetas personalizables para sección equipo
  final String? etiquetaSeccionEquipo;
  final String? etiquetaTipoEquipo;
  final String? etiquetaMarcaEquipo;
  final String? etiquetaNumeroSerie;
  final String? etiquetaCondicionEquipo;
  final bool mostrarSeccionEquipo;

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
    this.etiquetaSeccionEquipo,
    this.etiquetaTipoEquipo,
    this.etiquetaMarcaEquipo,
    this.etiquetaNumeroSerie,
    this.etiquetaCondicionEquipo,
    this.mostrarSeccionEquipo = true,
  });

  // Getters con defaults
  String get labelSeccionEquipo => etiquetaSeccionEquipo ?? 'EQUIPO';
  String get labelTipoEquipo => etiquetaTipoEquipo ?? 'Tipo de equipo';
  String get labelMarcaEquipo => etiquetaMarcaEquipo ?? 'Marca';
  String get labelNumeroSerie => etiquetaNumeroSerie ?? 'Número de serie';
  String get labelCondicionEquipo => etiquetaCondicionEquipo ?? 'Condición del equipo';

  @override
  List<Object?> get props => [
        id, empresaId, impuestoDefaultPorcentaje, nombreImpuesto,
        monedaPrincipal, simboloMoneda, monedasPermitidas,
        diasVigenciaCotizacion, condicionesDefault,
        etiquetaSeccionEquipo, etiquetaTipoEquipo, etiquetaMarcaEquipo,
        etiquetaNumeroSerie, etiquetaCondicionEquipo, mostrarSeccionEquipo,
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
    String? etiquetaSeccionEquipo,
    String? etiquetaTipoEquipo,
    String? etiquetaMarcaEquipo,
    String? etiquetaNumeroSerie,
    String? etiquetaCondicionEquipo,
    bool? mostrarSeccionEquipo,
  }) {
    return ConfiguracionEmpresa(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      impuestoDefaultPorcentaje: impuestoDefaultPorcentaje ?? this.impuestoDefaultPorcentaje,
      nombreImpuesto: nombreImpuesto ?? this.nombreImpuesto,
      monedaPrincipal: monedaPrincipal ?? this.monedaPrincipal,
      simboloMoneda: simboloMoneda ?? this.simboloMoneda,
      monedasPermitidas: monedasPermitidas ?? this.monedasPermitidas,
      diasVigenciaCotizacion: diasVigenciaCotizacion ?? this.diasVigenciaCotizacion,
      condicionesDefault: condicionesDefault ?? this.condicionesDefault,
      etiquetaSeccionEquipo: etiquetaSeccionEquipo ?? this.etiquetaSeccionEquipo,
      etiquetaTipoEquipo: etiquetaTipoEquipo ?? this.etiquetaTipoEquipo,
      etiquetaMarcaEquipo: etiquetaMarcaEquipo ?? this.etiquetaMarcaEquipo,
      etiquetaNumeroSerie: etiquetaNumeroSerie ?? this.etiquetaNumeroSerie,
      etiquetaCondicionEquipo: etiquetaCondicionEquipo ?? this.etiquetaCondicionEquipo,
      mostrarSeccionEquipo: mostrarSeccionEquipo ?? this.mostrarSeccionEquipo,
    );
  }
}
