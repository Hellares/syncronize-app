import '../../domain/entities/empresa_banco.dart';

class EmpresaBancoModel extends EmpresaBanco {
  const EmpresaBancoModel({
    required super.id,
    required super.nombreBanco,
    required super.tipoCuenta,
    required super.numeroCuenta,
    super.cci,
    super.moneda,
    super.titular,
    super.esPrincipal,
    super.saldoActual,
    super.isActive,
  });

  factory EmpresaBancoModel.fromJson(Map<String, dynamic> json) {
    return EmpresaBancoModel(
      id: json['id'] as String,
      nombreBanco: json['nombreBanco'] as String? ?? '',
      tipoCuenta: json['tipoCuenta'] as String? ?? '',
      numeroCuenta: json['numeroCuenta'] as String? ?? '',
      cci: json['cci'] as String?,
      moneda: json['moneda'] as String?,
      titular: json['titular'] as String?,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      saldoActual: _toDouble(json['saldoActual']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  EmpresaBanco toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class ConciliacionBancariaModel extends ConciliacionBancaria {
  const ConciliacionBancariaModel({
    required super.cuenta,
    required super.periodo,
    required super.movimientosSistema,
    required super.conciliacion,
    required super.movimientos,
  });

  factory ConciliacionBancariaModel.fromJson(Map<String, dynamic> json) {
    final cuentaJson = json['cuenta'] as Map<String, dynamic>? ?? {};
    final periodoJson = json['periodo'] as Map<String, dynamic>? ?? {};
    final movSistemaJson = json['movimientosSistema'] as Map<String, dynamic>? ?? {};
    final conciliacionJson = json['conciliacion'] as Map<String, dynamic>? ?? {};
    final movimientosJson = json['movimientos'] as List<dynamic>? ?? [];

    return ConciliacionBancariaModel(
      cuenta: ConciliacionCuentaModel.fromJson(cuentaJson),
      periodo: ConciliacionPeriodoModel.fromJson(periodoJson),
      movimientosSistema: ConciliacionMovimientosSistemaModel.fromJson(movSistemaJson),
      conciliacion: ConciliacionResultadoModel.fromJson(conciliacionJson),
      movimientos: movimientosJson
          .map((e) => ConciliacionMovimientoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ConciliacionBancaria toEntity() => this;
}

class ConciliacionCuentaModel extends ConciliacionCuenta {
  const ConciliacionCuentaModel({
    required super.id,
    required super.nombreBanco,
    required super.numeroCuenta,
    required super.moneda,
    required super.saldoActual,
  });

  factory ConciliacionCuentaModel.fromJson(Map<String, dynamic> json) {
    return ConciliacionCuentaModel(
      id: json['id'] as String? ?? '',
      nombreBanco: json['nombreBanco'] as String? ?? '',
      numeroCuenta: json['numeroCuenta'] as String? ?? '',
      moneda: json['moneda'] as String? ?? 'PEN',
      saldoActual: _toDouble(json['saldoActual']),
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

class ConciliacionPeriodoModel extends ConciliacionPeriodo {
  const ConciliacionPeriodoModel({
    required super.desde,
    required super.hasta,
  });

  factory ConciliacionPeriodoModel.fromJson(Map<String, dynamic> json) {
    return ConciliacionPeriodoModel(
      desde: json['desde'] as String? ?? '',
      hasta: json['hasta'] as String? ?? '',
    );
  }
}

class ConciliacionMovimientosSistemaModel extends ConciliacionMovimientosSistema {
  const ConciliacionMovimientosSistemaModel({
    required super.cantidad,
    required super.totalIngresos,
    required super.totalEgresos,
    required super.saldoSistema,
  });

  factory ConciliacionMovimientosSistemaModel.fromJson(Map<String, dynamic> json) {
    return ConciliacionMovimientosSistemaModel(
      cantidad: json['cantidad'] as int? ?? 0,
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      saldoSistema: _toDouble(json['saldoSistema']),
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

class ConciliacionResultadoModel extends ConciliacionResultado {
  const ConciliacionResultadoModel({
    required super.saldoBanco,
    required super.saldoSistema,
    required super.diferencia,
    required super.conciliado,
  });

  factory ConciliacionResultadoModel.fromJson(Map<String, dynamic> json) {
    return ConciliacionResultadoModel(
      saldoBanco: _toDouble(json['saldoBanco']),
      saldoSistema: _toDouble(json['saldoSistema']),
      diferencia: _toDouble(json['diferencia']),
      conciliado: json['conciliado'] as bool? ?? false,
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

class ConciliacionMovimientoModel extends ConciliacionMovimiento {
  const ConciliacionMovimientoModel({
    required super.id,
    required super.tipo,
    required super.monto,
    required super.descripcion,
    super.fechaMovimiento,
    super.esManual,
  });

  factory ConciliacionMovimientoModel.fromJson(Map<String, dynamic> json) {
    return ConciliacionMovimientoModel(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      monto: _toDouble(json['monto']),
      descripcion: json['descripcion'] as String? ?? '',
      fechaMovimiento: json['fechaMovimiento'] as String? ?? json['fecha'] as String?,
      esManual: json['esManual'] as bool? ?? false,
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
