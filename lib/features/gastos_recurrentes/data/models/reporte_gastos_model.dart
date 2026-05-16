import '../../domain/entities/reporte_gastos.dart';

class ReporteGastosModel extends ReporteGastos {
  const ReporteGastosModel({
    required super.evolucionMensual,
    required super.mesActual,
  });

  factory ReporteGastosModel.fromJson(Map<String, dynamic> json) {
    final evol = (json['evolucionMensual'] as List).cast<Map<String, dynamic>>();
    final mes = json['mesActual'] as Map<String, dynamic>;

    return ReporteGastosModel(
      evolucionMensual: evol
          .map((m) => ReporteEvolucionMes(
                periodo: m['periodo'] as String,
                total: _toDouble(m['total']),
                porCategoria: _toDoubleMap(m['porCategoria']),
              ))
          .toList(),
      mesActual: ReporteMesActual(
        periodo: mes['periodo'] as String,
        totalGastado: _toDouble(mes['totalGastado']),
        porCategoria: (mes['porCategoria'] as List)
            .cast<Map<String, dynamic>>()
            .map((c) => ReporteCategoriaMes(
                  categoriaId: c['categoriaId'] as String? ?? '',
                  nombre: c['nombre'] as String? ?? '',
                  monto: _toDouble(c['monto']),
                  icono: c['icono'] as String?,
                  color: c['color'] as String?,
                ))
            .toList(),
      ),
    );
  }

  ReporteGastos toEntity() => this;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static Map<String, double> _toDoubleMap(dynamic v) {
    if (v is! Map) return {};
    return v.map((k, val) => MapEntry(k as String, _toDouble(val)));
  }
}
