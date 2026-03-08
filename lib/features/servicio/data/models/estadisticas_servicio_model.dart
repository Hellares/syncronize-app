import '../../domain/entities/estadisticas_servicio.dart';

class EstadisticasServicioModel extends EstadisticasServicio {
  const EstadisticasServicioModel({
    required super.totalOrdenes,
    required super.ordenesPorEstado,
    required super.ordenesPorTipo,
    required super.ordenesPorMes,
    required super.tiempoPromedioResolucion,
    required super.ingresoTotal,
  });

  factory EstadisticasServicioModel.fromJson(Map<String, dynamic> json) {
    final estadoMap = <String, int>{};
    if (json['ordenesPorEstado'] is Map) {
      (json['ordenesPorEstado'] as Map).forEach((k, v) {
        estadoMap[k.toString()] = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      });
    }

    final tipoMap = <String, int>{};
    if (json['ordenesPorTipo'] is Map) {
      (json['ordenesPorTipo'] as Map).forEach((k, v) {
        tipoMap[k.toString()] = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      });
    }

    final meses = <OrdenesMes>[];
    if (json['ordenesPorMes'] is List) {
      for (final item in json['ordenesPorMes'] as List) {
        if (item is! Map) continue;
        meses.add(OrdenesMes(
          mes: item['mes']?.toString() ?? '',
          cantidad: item['cantidad'] is num
              ? (item['cantidad'] as num).toInt()
              : int.tryParse(item['cantidad']?.toString() ?? '') ?? 0,
        ));
      }
    }

    return EstadisticasServicioModel(
      totalOrdenes: (json['totalOrdenes'] as num?)?.toInt() ?? 0,
      ordenesPorEstado: estadoMap,
      ordenesPorTipo: tipoMap,
      ordenesPorMes: meses,
      tiempoPromedioResolucion:
          (json['tiempoPromedioResolucion'] as num?)?.toInt() ?? 0,
      ingresoTotal: (json['ingresoTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
