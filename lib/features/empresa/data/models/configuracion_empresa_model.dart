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
      etiquetaSeccionEquipo: entity.etiquetaSeccionEquipo,
      etiquetaTipoEquipo: entity.etiquetaTipoEquipo,
      etiquetaMarcaEquipo: entity.etiquetaMarcaEquipo,
      etiquetaNumeroSerie: entity.etiquetaNumeroSerie,
      etiquetaCondicionEquipo: entity.etiquetaCondicionEquipo,
      mostrarSeccionEquipo: entity.mostrarSeccionEquipo,
    );
  }
}
