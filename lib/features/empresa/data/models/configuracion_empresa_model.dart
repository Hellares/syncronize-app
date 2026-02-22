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
    );
  }
}
