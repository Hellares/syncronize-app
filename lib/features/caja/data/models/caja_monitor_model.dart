import '../../domain/entities/caja_monitor.dart';

class CajaMonitorDataModel {
  static CajaMonitorData fromJson(Map<String, dynamic> json) {
    final resumenJson = json['resumen'] as Map<String, dynamic>;
    final cajasJson = json['cajas'] as List;

    final resumen = CajaMonitorResumen(
      totalCajasAbiertas: resumenJson['totalCajasAbiertas'] as int? ?? 0,
      totalIngresos: _toDouble(resumenJson['totalIngresos']),
      totalEgresos: _toDouble(resumenJson['totalEgresos']),
      totalSaldo: _toDouble(resumenJson['totalSaldo']),
    );

    final cajas = cajasJson.map((c) {
      final caja = c as Map<String, dynamic>;
      final sede = caja['sede'] as Map<String, dynamic>?;
      final usuario = caja['usuario'] as Map<String, dynamic>?;
      final persona = usuario?['persona'] as Map<String, dynamic>?;
      final count = caja['_count'] as Map<String, dynamic>?;
      final ultimoMov = caja['ultimoMovimiento'] as Map<String, dynamic>?;

      return CajaMonitorItem(
        id: caja['id'] as String,
        codigo: caja['codigo'] as String? ?? '',
        sedeId: caja['sedeId'] as String? ?? '',
        sedeNombre: sede?['nombre'] as String? ?? '',
        usuarioNombre: '${persona?['nombres'] ?? ''} ${persona?['apellidos'] ?? ''}'.trim(),
        montoApertura: _toDouble(caja['montoApertura']),
        fechaApertura: DateTime.parse(caja['fechaApertura'] as String),
        totalIngresos: _toDouble(caja['totalIngresos']),
        totalEgresos: _toDouble(caja['totalEgresos']),
        saldoActual: _toDouble(caja['saldoActual']),
        totalMovimientos: count?['movimientos'] as int? ?? 0,
        ultimoMovimiento: ultimoMov != null
            ? UltimoMovimiento(
                tipo: ultimoMov['tipo'] as String? ?? '',
                categoria: ultimoMov['categoria'] as String? ?? '',
                monto: _toDouble(ultimoMov['monto']),
                descripcion: ultimoMov['descripcion'] as String?,
                fechaMovimiento: DateTime.parse(ultimoMov['fechaMovimiento'] as String),
              )
            : null,
      );
    }).toList();

    return CajaMonitorData(resumen: resumen, cajas: cajas);
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
