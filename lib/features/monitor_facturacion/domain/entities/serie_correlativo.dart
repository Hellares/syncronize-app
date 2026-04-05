import 'package:equatable/equatable.dart';

class SerieCorrelativo extends Equatable {
  final String serie;
  final String tipoComprobante;
  final String? sedeId;
  final String sedeNombre;
  final int primerCorrelativo;
  final int ultimoCorrelativo;
  final int contadorSede;
  final int totalEmitidos;
  final int totalAnulados;
  final int duplicados;
  final List<int> faltantes;
  final int totalFaltantes;
  final bool desincronizado;
  final String estado; // OK, GAPS, DESINCRONIZADO

  const SerieCorrelativo({
    required this.serie,
    required this.tipoComprobante,
    this.sedeId,
    required this.sedeNombre,
    required this.primerCorrelativo,
    required this.ultimoCorrelativo,
    required this.contadorSede,
    required this.totalEmitidos,
    required this.totalAnulados,
    required this.duplicados,
    required this.faltantes,
    required this.totalFaltantes,
    required this.desincronizado,
    required this.estado,
  });

  bool get esOk => estado == 'OK';
  bool get tieneGaps => estado == 'GAPS' || totalFaltantes > 0;
  bool get esDesincronizado => estado == 'DESINCRONIZADO';

  String get tipoLabel {
    switch (tipoComprobante) {
      case 'FACTURA': return 'Factura';
      case 'BOLETA': return 'Boleta';
      case 'NOTA_CREDITO': return 'N. Crédito';
      case 'NOTA_DEBITO': return 'N. Débito';
      default: return tipoComprobante;
    }
  }

  String get rango => totalEmitidos == 0
      ? 'Sin emisiones'
      : '$serie-${primerCorrelativo.toString().padLeft(8, '0')} → $serie-${ultimoCorrelativo.toString().padLeft(8, '0')}';

  @override
  List<Object?> get props => [serie, estado, totalFaltantes, contadorSede];
}

class ResumenCorrelativos extends Equatable {
  final int totalSeries;
  final int seriesOk;
  final int seriesConGaps;
  final int seriesDesincronizadas;
  final int totalFaltantes;

  const ResumenCorrelativos({
    required this.totalSeries,
    required this.seriesOk,
    required this.seriesConGaps,
    required this.seriesDesincronizadas,
    required this.totalFaltantes,
  });

  @override
  List<Object?> get props => [totalSeries, seriesOk, seriesConGaps, totalFaltantes];
}

class ReporteCorrelativos extends Equatable {
  final List<SerieCorrelativo> series;
  final ResumenCorrelativos resumen;

  const ReporteCorrelativos({required this.series, required this.resumen});

  @override
  List<Object?> get props => [series, resumen];
}
