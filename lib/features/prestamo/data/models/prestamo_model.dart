import '../../domain/entities/prestamo.dart';

class PrestamoModel extends Prestamo {
  const PrestamoModel({
    required super.id,
    required super.tipo,
    required super.estado,
    required super.entidadPrestamo,
    super.descripcion,
    required super.montoOriginal,
    super.tasaInteres,
    super.moneda,
    super.cantidadCuotas,
    super.montoCuota,
    required super.fechaDesembolso,
    super.fechaVencimiento,
    super.totalPagado,
    super.saldoPendiente,
    super.observaciones,
    super.pagos,
  });

  factory PrestamoModel.fromJson(Map<String, dynamic> json) {
    final pagosJson = json['pagos'] as List<dynamic>? ?? [];

    return PrestamoModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      entidadPrestamo: json['entidadPrestamo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      montoOriginal: _toDouble(json['montoOriginal']),
      tasaInteres: json['tasaInteres'] != null ? _toDouble(json['tasaInteres']) : null,
      moneda: json['moneda'] as String?,
      cantidadCuotas: json['cantidadCuotas'] as int?,
      montoCuota: json['montoCuota'] != null ? _toDouble(json['montoCuota']) : null,
      fechaDesembolso: json['fechaDesembolso'] as String? ?? '',
      fechaVencimiento: json['fechaVencimiento'] as String?,
      totalPagado: _toDouble(json['totalPagado']),
      saldoPendiente: _toDouble(json['saldoPendiente']),
      observaciones: json['observaciones'] as String?,
      pagos: pagosJson
          .map((e) => PagoPrestamoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Prestamo toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class PagoPrestamoModel extends PagoPrestamo {
  const PagoPrestamoModel({
    required super.id,
    required super.metodoPago,
    required super.monto,
    super.referencia,
    super.fechaPago,
  });

  factory PagoPrestamoModel.fromJson(Map<String, dynamic> json) {
    return PagoPrestamoModel(
      id: json['id'] as String? ?? '',
      metodoPago: json['metodoPago'] as String? ?? '',
      monto: _toDouble(json['monto']),
      referencia: json['referencia'] as String?,
      fechaPago: json['fechaPago'] as String? ?? json['createdAt'] as String?,
    );
  }

  PagoPrestamo toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class ResumenPrestamosModel extends ResumenPrestamos {
  const ResumenPrestamosModel({
    required super.cantidadActivos,
    required super.totalDeuda,
    required super.totalOriginal,
    required super.totalPagado,
    required super.porcentajePagado,
  });

  factory ResumenPrestamosModel.fromJson(Map<String, dynamic> json) {
    return ResumenPrestamosModel(
      cantidadActivos: json['cantidadActivos'] as int? ?? 0,
      totalDeuda: _toDouble(json['totalDeuda']),
      totalOriginal: _toDouble(json['totalOriginal']),
      totalPagado: _toDouble(json['totalPagado']),
      porcentajePagado: _toDouble(json['porcentajePagado']),
    );
  }

  ResumenPrestamos toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
