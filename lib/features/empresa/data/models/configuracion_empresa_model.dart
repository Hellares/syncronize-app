import '../../domain/entities/configuracion_empresa.dart';

class ConfiguracionEmpresaModel extends ConfiguracionEmpresa {
  const ConfiguracionEmpresaModel({
    required super.id,
    required super.empresaId,
    super.impuestoDefaultPorcentaje,
    super.nombreImpuesto,
    super.monedaPrincipal,
    super.simboloMoneda,
    super.monedasPermitidas,
    super.diasVigenciaCotizacion,
    super.condicionesDefault,
    super.interesHabilitado,
    super.porcentajeInteresDefault,
    super.interesEsEditable,
    super.moraHabilitada,
    super.porcentajeMoraDiario,
    super.moraMaximaPorcentaje,
    super.diasGraciaMora,
    super.etiquetaSeccionEquipo,
    super.etiquetaTipoEquipo,
    super.etiquetaMarcaEquipo,
    super.etiquetaNumeroSerie,
    super.etiquetaCondicionEquipo,
    super.mostrarSeccionEquipo,
  });

  factory ConfiguracionEmpresaModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionEmpresaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      impuestoDefaultPorcentaje:
          (json['impuestoDefaultPorcentaje'] as num?)?.toDouble() ?? 18.0,
      nombreImpuesto: json['nombreImpuesto'] as String? ?? 'IGV',
      monedaPrincipal: json['monedaPrincipal'] as String? ?? 'PEN',
      simboloMoneda: json['simboloMoneda'] as String? ?? 'S/',
      monedasPermitidas: (json['monedasPermitidas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['PEN', 'USD'],
      diasVigenciaCotizacion:
          json['diasVigenciaCotizacion'] as int? ?? 30,
      condicionesDefault: json['condicionesDefault'] as String?,
      interesHabilitado: json['interesHabilitado'] as bool? ?? false,
      porcentajeInteresDefault: _toDouble(json['porcentajeInteresDefault']) ?? 0,
      interesEsEditable: json['interesEsEditable'] as bool? ?? true,
      moraHabilitada: json['moraHabilitada'] as bool? ?? false,
      porcentajeMoraDiario: _toDouble(json['porcentajeMoraDiario']) ?? 0.05,
      moraMaximaPorcentaje: _toDouble(json['moraMaximaPorcentaje']) ?? 30.0,
      diasGraciaMora: json['diasGraciaMora'] as int? ?? 0,
      etiquetaSeccionEquipo: json['etiquetaSeccionEquipo'] as String?,
      etiquetaTipoEquipo: json['etiquetaTipoEquipo'] as String?,
      etiquetaMarcaEquipo: json['etiquetaMarcaEquipo'] as String?,
      etiquetaNumeroSerie: json['etiquetaNumeroSerie'] as String?,
      etiquetaCondicionEquipo: json['etiquetaCondicionEquipo'] as String?,
      mostrarSeccionEquipo: json['mostrarSeccionEquipo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'impuestoDefaultPorcentaje': impuestoDefaultPorcentaje,
      'nombreImpuesto': nombreImpuesto,
      'monedaPrincipal': monedaPrincipal,
      'simboloMoneda': simboloMoneda,
      'monedasPermitidas': monedasPermitidas,
      'diasVigenciaCotizacion': diasVigenciaCotizacion,
      if (condicionesDefault != null) 'condicionesDefault': condicionesDefault,
      'interesHabilitado': interesHabilitado,
      'porcentajeInteresDefault': porcentajeInteresDefault,
      'interesEsEditable': interesEsEditable,
      'moraHabilitada': moraHabilitada,
      'porcentajeMoraDiario': porcentajeMoraDiario,
      'moraMaximaPorcentaje': moraMaximaPorcentaje,
      'diasGraciaMora': diasGraciaMora,
      if (etiquetaSeccionEquipo != null) 'etiquetaSeccionEquipo': etiquetaSeccionEquipo,
      if (etiquetaTipoEquipo != null) 'etiquetaTipoEquipo': etiquetaTipoEquipo,
      if (etiquetaMarcaEquipo != null) 'etiquetaMarcaEquipo': etiquetaMarcaEquipo,
      if (etiquetaNumeroSerie != null) 'etiquetaNumeroSerie': etiquetaNumeroSerie,
      if (etiquetaCondicionEquipo != null) 'etiquetaCondicionEquipo': etiquetaCondicionEquipo,
      'mostrarSeccionEquipo': mostrarSeccionEquipo,
    };
  }

  ConfiguracionEmpresa toEntity() => this;

  factory ConfiguracionEmpresaModel.fromEntity(ConfiguracionEmpresa entity) {
    return ConfiguracionEmpresaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      impuestoDefaultPorcentaje: entity.impuestoDefaultPorcentaje,
      nombreImpuesto: entity.nombreImpuesto,
      monedaPrincipal: entity.monedaPrincipal,
      simboloMoneda: entity.simboloMoneda,
      monedasPermitidas: entity.monedasPermitidas,
      diasVigenciaCotizacion: entity.diasVigenciaCotizacion,
      condicionesDefault: entity.condicionesDefault,
      interesHabilitado: entity.interesHabilitado,
      porcentajeInteresDefault: entity.porcentajeInteresDefault,
      interesEsEditable: entity.interesEsEditable,
      moraHabilitada: entity.moraHabilitada,
      porcentajeMoraDiario: entity.porcentajeMoraDiario,
      moraMaximaPorcentaje: entity.moraMaximaPorcentaje,
      diasGraciaMora: entity.diasGraciaMora,
      etiquetaSeccionEquipo: entity.etiquetaSeccionEquipo,
      etiquetaTipoEquipo: entity.etiquetaTipoEquipo,
      etiquetaMarcaEquipo: entity.etiquetaMarcaEquipo,
      etiquetaNumeroSerie: entity.etiquetaNumeroSerie,
      etiquetaCondicionEquipo: entity.etiquetaCondicionEquipo,
      mostrarSeccionEquipo: entity.mostrarSeccionEquipo,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }
}
