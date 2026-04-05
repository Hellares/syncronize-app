import '../../domain/entities/serie_correlativo.dart';

class SerieCorrelativoModel extends SerieCorrelativo {
  const SerieCorrelativoModel({
    required super.serie,
    required super.tipoComprobante,
    super.sedeId,
    required super.sedeNombre,
    required super.primerCorrelativo,
    required super.ultimoCorrelativo,
    required super.contadorSede,
    required super.totalEmitidos,
    required super.totalAnulados,
    required super.duplicados,
    required super.faltantes,
    required super.totalFaltantes,
    required super.desincronizado,
    required super.estado,
  });

  factory SerieCorrelativoModel.fromJson(Map<String, dynamic> json) {
    return SerieCorrelativoModel(
      serie: json['serie'] as String,
      tipoComprobante: json['tipoComprobante'] as String,
      sedeId: json['sedeId'] as String?,
      sedeNombre: json['sedeNombre'] as String? ?? 'Principal',
      primerCorrelativo: json['primerCorrelativo'] as int? ?? 0,
      ultimoCorrelativo: json['ultimoCorrelativo'] as int? ?? 0,
      contadorSede: json['contadorSede'] as int? ?? 0,
      totalEmitidos: json['totalEmitidos'] as int? ?? 0,
      totalAnulados: json['totalAnulados'] as int? ?? 0,
      duplicados: json['duplicados'] as int? ?? 0,
      faltantes: (json['faltantes'] as List?)?.map((e) => e as int).toList() ?? [],
      totalFaltantes: json['totalFaltantes'] as int? ?? 0,
      desincronizado: json['desincronizado'] as bool? ?? false,
      estado: json['estado'] as String? ?? 'OK',
    );
  }
}

class ResumenCorrelativosModel extends ResumenCorrelativos {
  const ResumenCorrelativosModel({
    required super.totalSeries,
    required super.seriesOk,
    required super.seriesConGaps,
    required super.seriesDesincronizadas,
    required super.totalFaltantes,
  });

  factory ResumenCorrelativosModel.fromJson(Map<String, dynamic> json) {
    return ResumenCorrelativosModel(
      totalSeries: json['totalSeries'] as int? ?? 0,
      seriesOk: json['seriesOk'] as int? ?? 0,
      seriesConGaps: json['seriesConGaps'] as int? ?? 0,
      seriesDesincronizadas: json['seriesDesincronizadas'] as int? ?? 0,
      totalFaltantes: json['totalFaltantes'] as int? ?? 0,
    );
  }
}

class ReporteCorrelativosModel extends ReporteCorrelativos {
  const ReporteCorrelativosModel({
    required List<SerieCorrelativoModel> super.series,
    required ResumenCorrelativosModel super.resumen,
  });

  factory ReporteCorrelativosModel.fromJson(Map<String, dynamic> json) {
    return ReporteCorrelativosModel(
      series: (json['series'] as List)
          .map((e) => SerieCorrelativoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      resumen: ResumenCorrelativosModel.fromJson(
          json['resumen'] as Map<String, dynamic>),
    );
  }
}
