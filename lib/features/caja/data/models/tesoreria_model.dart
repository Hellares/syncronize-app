import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/tesoreria.dart';
import 'movimiento_caja_model.dart';

class TesoreriaResumenModel extends TesoreriaResumen {
  const TesoreriaResumenModel({
    required super.caja,
    required super.sede,
    required super.saldoEfectivo,
    required super.saldoDigital,
    required super.saldoTotal,
    required super.totalIngresos,
    required super.totalEgresos,
    required super.totalMovimientos,
    super.ultimoMovimiento,
  });

  factory TesoreriaResumenModel.fromJson(Map<String, dynamic> json) {
    final cajaJson = json['caja'] as Map<String, dynamic>;
    final sedeJson = json['sede'] as Map<String, dynamic>;
    final ultimoJson = json['ultimoMovimiento'] as Map<String, dynamic>?;

    return TesoreriaResumenModel(
      caja: TesoreriaCaja(
        id: cajaJson['id'] as String,
        codigo: cajaJson['codigo'] as String,
        sedeId: cajaJson['sedeId'] as String,
        fechaApertura: DateTime.parse(cajaJson['fechaApertura'] as String),
      ),
      sede: TesoreriaSede(
        id: sedeJson['id'] as String,
        nombre: sedeJson['nombre'] as String,
        codigo: sedeJson['codigo'] as String?,
      ),
      saldoEfectivo: _toDouble(json['saldoEfectivo']),
      saldoDigital: _toDouble(json['saldoDigital']),
      saldoTotal: _toDouble(json['saldoTotal']),
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      totalMovimientos: (json['totalMovimientos'] as num?)?.toInt() ?? 0,
      ultimoMovimiento: ultimoJson == null
          ? null
          : TesoreriaUltimoMovimiento(
              id: ultimoJson['id'] as String,
              tipo: TipoMovimientoCaja.fromString(ultimoJson['tipo'] as String),
              categoria: CategoriaMovimientoCaja.fromString(
                ultimoJson['categoria'] as String,
              ),
              metodoPago: MetodoPago.fromString(
                ultimoJson['metodoPago'] as String,
              ),
              monto: _toDouble(ultimoJson['monto']),
              descripcion: ultimoJson['descripcion'] as String?,
              fechaMovimiento: DateTime.parse(
                ultimoJson['fechaMovimiento'] as String,
              ),
            ),
    );
  }

  TesoreriaResumen toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class TesoreriaMovimientosPageModel extends TesoreriaMovimientosPage {
  const TesoreriaMovimientosPageModel({
    required super.items,
    required super.total,
    required super.page,
    required super.pageSize,
    required super.totalPages,
  });

  factory TesoreriaMovimientosPageModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((e) => MovimientoCajaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return TesoreriaMovimientosPageModel(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  TesoreriaMovimientosPage toEntity() => this;
}
