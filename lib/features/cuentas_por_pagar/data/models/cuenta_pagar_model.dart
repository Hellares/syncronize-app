import '../../domain/entities/cuenta_por_pagar.dart';

class CuentaPagarModel {
  final String id;
  final String codigo;
  final String nombreProveedor;
  final double saldoPendiente;
  final double totalCompra;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final Map<String, dynamic>? bancoPrincipal;

  const CuentaPagarModel({
    required this.id,
    required this.codigo,
    required this.nombreProveedor,
    required this.saldoPendiente,
    required this.totalCompra,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.bancoPrincipal,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  factory CuentaPagarModel.fromJson(Map<String, dynamic> json) {
    return CuentaPagarModel(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombreProveedor: json['nombreProveedor'] as String? ?? '',
      saldoPendiente: _toDouble(json['saldoPendiente']),
      totalCompra: _toDouble(json['totalCompra']),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      diasVencimiento: json['diasVencimiento'] as int?,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.tryParse(json['fechaVencimiento'].toString())
          : null,
      bancoPrincipal: json['bancoPrincipal'] as Map<String, dynamic>?,
    );
  }

  CuentaPorPagar toEntity() {
    return CuentaPorPagar(
      id: id,
      codigo: codigo,
      nombreProveedor: nombreProveedor,
      saldoPendiente: saldoPendiente,
      totalCompra: totalCompra,
      estado: estado,
      diasVencimiento: diasVencimiento,
      fechaVencimiento: fechaVencimiento,
      bancoPrincipal: bancoPrincipal != null
          ? BancoPrincipal(
              nombreBanco: bancoPrincipal!['nombreBanco'] as String? ?? '',
              numeroCuenta: bancoPrincipal!['numeroCuenta'] as String? ?? '',
            )
          : null,
    );
  }
}

class ResumenCuentasPagarModel {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;

  const ResumenCuentasPagarModel({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
  });

  factory ResumenCuentasPagarModel.fromJson(Map<String, dynamic> json) {
    return ResumenCuentasPagarModel(
      totalPendiente: CuentaPagarModel._toDouble(json['totalPendiente']),
      totalVencido: CuentaPagarModel._toDouble(json['totalVencido']),
      cantidadPendientes: json['cantidadPendientes'] as int? ?? 0,
      cantidadVencidas: json['cantidadVencidas'] as int? ?? 0,
    );
  }

  ResumenCuentasPagar toEntity() {
    return ResumenCuentasPagar(
      totalPendiente: totalPendiente,
      totalVencido: totalVencido,
      cantidadPendientes: cantidadPendientes,
      cantidadVencidas: cantidadVencidas,
    );
  }
}
