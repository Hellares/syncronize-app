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

  // Configuración de venta a crédito
  final bool ventaCreditoHabilitada;
  final bool interesHabilitado;
  final double porcentajeInteresDefault;
  final bool interesEsEditable;

  // Configuración de mora
  final bool moraHabilitada;
  final double porcentajeMoraDiario;
  final double moraMaximaPorcentaje;
  final int diasGraciaMora;

  // Etiquetas personalizables para sección equipo
  final String? etiquetaSeccionEquipo;
  final String? etiquetaTipoEquipo;
  final String? etiquetaMarcaEquipo;
  final String? etiquetaNumeroSerie;
  final String? etiquetaCondicionEquipo;
  final bool mostrarSeccionEquipo;

  // QR de cobro Yape/Plin (imagen estática del comercio)
  final String? qrYapeUrl;
  final String? qrPlinUrl;

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
    this.ventaCreditoHabilitada = false,
    this.interesHabilitado = false,
    this.porcentajeInteresDefault = 0,
    this.interesEsEditable = true,
    this.moraHabilitada = false,
    this.porcentajeMoraDiario = 0.05,
    this.moraMaximaPorcentaje = 30.0,
    this.diasGraciaMora = 0,
    this.etiquetaSeccionEquipo,
    this.etiquetaTipoEquipo,
    this.etiquetaMarcaEquipo,
    this.etiquetaNumeroSerie,
    this.etiquetaCondicionEquipo,
    this.mostrarSeccionEquipo = true,
    this.qrYapeUrl,
    this.qrPlinUrl,
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
        ventaCreditoHabilitada,
        interesHabilitado, porcentajeInteresDefault, interesEsEditable,
        moraHabilitada, porcentajeMoraDiario, moraMaximaPorcentaje, diasGraciaMora,
        etiquetaSeccionEquipo, etiquetaTipoEquipo, etiquetaMarcaEquipo,
        etiquetaNumeroSerie, etiquetaCondicionEquipo, mostrarSeccionEquipo,
        qrYapeUrl, qrPlinUrl,
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
    bool? ventaCreditoHabilitada,
    bool? interesHabilitado,
    double? porcentajeInteresDefault,
    bool? interesEsEditable,
    bool? moraHabilitada,
    double? porcentajeMoraDiario,
    double? moraMaximaPorcentaje,
    int? diasGraciaMora,
    String? etiquetaSeccionEquipo,
    String? etiquetaTipoEquipo,
    String? etiquetaMarcaEquipo,
    String? etiquetaNumeroSerie,
    String? etiquetaCondicionEquipo,
    bool? mostrarSeccionEquipo,
    String? qrYapeUrl,
    String? qrPlinUrl,
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
      ventaCreditoHabilitada: ventaCreditoHabilitada ?? this.ventaCreditoHabilitada,
      interesHabilitado: interesHabilitado ?? this.interesHabilitado,
      porcentajeInteresDefault: porcentajeInteresDefault ?? this.porcentajeInteresDefault,
      interesEsEditable: interesEsEditable ?? this.interesEsEditable,
      moraHabilitada: moraHabilitada ?? this.moraHabilitada,
      porcentajeMoraDiario: porcentajeMoraDiario ?? this.porcentajeMoraDiario,
      moraMaximaPorcentaje: moraMaximaPorcentaje ?? this.moraMaximaPorcentaje,
      diasGraciaMora: diasGraciaMora ?? this.diasGraciaMora,
      etiquetaSeccionEquipo: etiquetaSeccionEquipo ?? this.etiquetaSeccionEquipo,
      etiquetaTipoEquipo: etiquetaTipoEquipo ?? this.etiquetaTipoEquipo,
      etiquetaMarcaEquipo: etiquetaMarcaEquipo ?? this.etiquetaMarcaEquipo,
      etiquetaNumeroSerie: etiquetaNumeroSerie ?? this.etiquetaNumeroSerie,
      etiquetaCondicionEquipo: etiquetaCondicionEquipo ?? this.etiquetaCondicionEquipo,
      mostrarSeccionEquipo: mostrarSeccionEquipo ?? this.mostrarSeccionEquipo,
      qrYapeUrl: qrYapeUrl ?? this.qrYapeUrl,
      qrPlinUrl: qrPlinUrl ?? this.qrPlinUrl,
    );
  }
}
