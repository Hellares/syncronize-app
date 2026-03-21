import '../../domain/entities/cuenta_por_cobrar.dart';

class CuentaCobrarModel {
  final String id;
  final String codigo;
  final String nombreCliente;
  final double saldoPendiente;
  final double totalVenta;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final int? numeroCuotas;
  final int? cuotasPagadas;
  final ProximaCuota? proximaCuota;

  const CuentaCobrarModel({
    required this.id,
    required this.codigo,
    required this.nombreCliente,
    required this.saldoPendiente,
    required this.totalVenta,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.numeroCuotas,
    this.cuotasPagadas,
    this.proximaCuota,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory CuentaCobrarModel.fromJson(Map<String, dynamic> json) {
    ProximaCuota? proximaCuota;
    if (json['proximaCuota'] != null) {
      final pc = json['proximaCuota'] as Map<String, dynamic>;
      proximaCuota = ProximaCuota(
        id: pc['id'] as String? ?? '',
        numero: pc['numero'] as int? ?? 0,
        monto: _toDouble(pc['monto']),
        saldoPendiente: _toDouble(pc['saldoPendiente']),
        fechaVencimiento: pc['fechaVencimiento'] != null
            ? DateTime.parse(pc['fechaVencimiento'] as String)
            : DateTime.now(),
        estado: pc['estado'] as String? ?? 'PENDIENTE',
      );
    }

    return CuentaCobrarModel(
      id: json['ventaId'] as String? ?? json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombreCliente: json['nombreCliente'] as String? ?? '',
      saldoPendiente: _toDouble(json['saldoPendiente']),
      totalVenta: _toDouble(json['totalVenta']),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      diasVencimiento: json['diasVencimiento'] as int?,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.tryParse(json['fechaVencimiento'].toString())
          : null,
      numeroCuotas: json['numeroCuotas'] as int?,
      cuotasPagadas: json['cuotasPagadas'] as int?,
      proximaCuota: proximaCuota,
    );
  }

  CuentaPorCobrar toEntity() {
    return CuentaPorCobrar(
      id: id,
      codigo: codigo,
      nombreCliente: nombreCliente,
      saldoPendiente: saldoPendiente,
      totalVenta: totalVenta,
      estado: estado,
      diasVencimiento: diasVencimiento,
      fechaVencimiento: fechaVencimiento,
      numeroCuotas: numeroCuotas,
      cuotasPagadas: cuotasPagadas,
      proximaCuota: proximaCuota,
    );
  }
}

class ResumenCuentasCobrarModel {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;

  const ResumenCuentasCobrarModel({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
  });

  factory ResumenCuentasCobrarModel.fromJson(Map<String, dynamic> json) {
    return ResumenCuentasCobrarModel(
      totalPendiente: CuentaCobrarModel._toDouble(json['totalPendiente']),
      totalVencido: CuentaCobrarModel._toDouble(json['totalVencido']),
      cantidadPendientes: json['cantidadPendientes'] as int? ?? 0,
      cantidadVencidas: json['cantidadVencidas'] as int? ?? 0,
    );
  }

  ResumenCuentasCobrar toEntity() {
    return ResumenCuentasCobrar(
      totalPendiente: totalPendiente,
      totalVencido: totalVencido,
      cantidadPendientes: cantidadPendientes,
      cantidadVencidas: cantidadVencidas,
    );
  }
}
