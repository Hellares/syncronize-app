import 'package:equatable/equatable.dart';

/// Entity que representa un prestamo
class Prestamo extends Equatable {
  final String id;
  final String tipo;
  final String estado;
  final String entidadPrestamo;
  final String? descripcion;
  final double montoOriginal;
  final double? tasaInteres;
  final String? moneda;
  final int? cantidadCuotas;
  final double? montoCuota;
  final String fechaDesembolso;
  final String? fechaVencimiento;
  final double totalPagado;
  final double saldoPendiente;
  final String? observaciones;
  final List<PagoPrestamo> pagos;

  const Prestamo({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.entidadPrestamo,
    this.descripcion,
    required this.montoOriginal,
    this.tasaInteres,
    this.moneda,
    this.cantidadCuotas,
    this.montoCuota,
    required this.fechaDesembolso,
    this.fechaVencimiento,
    this.totalPagado = 0,
    this.saldoPendiente = 0,
    this.observaciones,
    this.pagos = const [],
  });

  @override
  List<Object?> get props => [
        id,
        tipo,
        estado,
        entidadPrestamo,
        descripcion,
        montoOriginal,
        tasaInteres,
        moneda,
        cantidadCuotas,
        montoCuota,
        fechaDesembolso,
        fechaVencimiento,
        totalPagado,
        saldoPendiente,
        observaciones,
        pagos,
      ];
}

/// Entity que representa un pago de prestamo
class PagoPrestamo extends Equatable {
  final String id;
  final String metodoPago;
  final double monto;
  final String? referencia;
  final String? fechaPago;

  const PagoPrestamo({
    required this.id,
    required this.metodoPago,
    required this.monto,
    this.referencia,
    this.fechaPago,
  });

  @override
  List<Object?> get props => [id, metodoPago, monto, referencia, fechaPago];
}

/// Entity que representa el resumen de prestamos
class ResumenPrestamos extends Equatable {
  final int cantidadActivos;
  final double totalDeuda;
  final double totalOriginal;
  final double totalPagado;
  final double porcentajePagado;

  const ResumenPrestamos({
    required this.cantidadActivos,
    required this.totalDeuda,
    required this.totalOriginal,
    required this.totalPagado,
    required this.porcentajePagado,
  });

  @override
  List<Object?> get props => [
        cantidadActivos,
        totalDeuda,
        totalOriginal,
        totalPagado,
        porcentajePagado,
      ];
}
