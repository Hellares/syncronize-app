import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';

class ArqueoCajaModel extends ArqueoCaja {
  const ArqueoCajaModel({
    required super.id,
    required super.cajaId,
    required super.empresaId,
    required super.tipo,
    required super.montoApertura,
    required super.totalIngresos,
    required super.totalEgresos,
    required super.totalEsperado,
    required super.totalConteoFisico,
    required super.diferencia,
    super.detalles,
    super.observaciones,
    required super.realizadoPorId,
    super.realizadoPorNombre,
    super.autorizadoPorId,
    super.autorizadoPorNombre,
    super.turnoEntregadoAId,
    super.turnoEntregadoANombre,
    super.alertaEnviada,
    required super.fechaArqueo,
  });

  factory ArqueoCajaModel.fromJson(Map<String, dynamic> json) {
    // detalles: JSON Map<metodo, {apertura, ingresos, egresos, ...}>
    final detallesRaw = json['detallePorMetodoPago'];
    final detalles = <DetalleCierreMetodo>[];
    if (detallesRaw is Map<String, dynamic>) {
      detallesRaw.forEach((metodo, valor) {
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

    return ArqueoCajaModel(
      id: json['id'] as String,
      cajaId: json['cajaId'] as String,
      empresaId: json['empresaId'] as String,
      tipo: TipoArqueoCaja.fromString(json['tipo'] as String),
      montoApertura: _toDouble(json['montoApertura']),
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      totalEsperado: _toDouble(json['totalEsperado']),
      totalConteoFisico: _toDouble(json['totalConteoFisico']),
      diferencia: _toDouble(json['diferencia']),
      detalles: detalles,
      observaciones: json['observaciones'] as String?,
      realizadoPorId: json['realizadoPorId'] as String,
      realizadoPorNombre: _parsePersonaNombre(json['realizadoPor']),
      autorizadoPorId: json['autorizadoPorId'] as String?,
      autorizadoPorNombre: _parsePersonaNombre(json['autorizadoPor']),
      turnoEntregadoAId: json['turnoEntregadoAId'] as String?,
      turnoEntregadoANombre: _parsePersonaNombre(json['turnoEntregadoA']),
      alertaEnviada: json['alertaEnviada'] as bool? ?? false,
      fechaArqueo: DateTime.parse(json['fechaArqueo'] as String),
    );
  }

  static String? _parsePersonaNombre(dynamic user) {
    if (user is! Map<String, dynamic>) return null;
    final persona = user['persona'] as Map<String, dynamic>?;
    if (persona == null) return null;
    final nombres = persona['nombres']?.toString() ?? '';
    final apellidos = persona['apellidos']?.toString() ?? '';
    final completo = '$nombres $apellidos'.trim();
    return completo.isEmpty ? null : completo;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
