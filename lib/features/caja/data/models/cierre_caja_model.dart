import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';

class CierreCajaModel extends CierreCaja {
  const CierreCajaModel({
    required super.totalIngresos,
    required super.totalEgresos,
    required super.totalEsperado,
    required super.totalConteoFisico,
    required super.diferencia,
    super.observaciones,
    super.fechaCierre,
    super.detalles,
  });

  /// Parsea el cierre que viene en `caja.cierre` del backend. El backend
  /// guarda `detallePorMetodoPago` como JSON con shape:
  /// `{ EFECTIVO: { apertura, ingresos, egresos, esperado, conteoFisico,
  /// diferencia }, YAPE: {...}, ... }`.
  factory CierreCajaModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detallePorMetodoPago'];
    final detalles = <DetalleCierreMetodo>[];
    if (detallesJson is Map<String, dynamic>) {
      detallesJson.forEach((metodo, valor) {
        if (valor is Map<String, dynamic>) {
          detalles.add(DetalleCierreMetodo(
            metodoPago: MetodoPago.fromString(metodo),
            apertura: _toDouble(valor['apertura']),
            ingresos: _toDouble(valor['ingresos']),
            egresos: _toDouble(valor['egresos']),
            esperado: _toDouble(valor['esperado']),
            conteoFisico: _toDouble(valor['conteoFisico']),
            diferencia: _toDouble(valor['diferencia']),
          ));
        }
      });
    }

    return CierreCajaModel(
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      totalEsperado: _toDouble(json['totalEsperado']),
      totalConteoFisico: _toDouble(json['totalConteoFisico']),
      diferencia: _toDouble(json['diferencia']),
      observaciones: json['observaciones'] as String?,
      fechaCierre: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : null,
      detalles: detalles,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
