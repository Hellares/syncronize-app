import 'package:equatable/equatable.dart';
import 'venta.dart';

/// Entity que representa un pago registrado en una venta
class PagoVenta extends Equatable {
  final String id;
  final String ventaId;
  final MetodoPago metodoPago;
  final double monto;
  final String? referencia;
  final DateTime fechaPago;

  const PagoVenta({
    required this.id,
    required this.ventaId,
    required this.metodoPago,
    required this.monto,
    this.referencia,
    required this.fechaPago,
  });

  @override
  List<Object?> get props => [id, ventaId, metodoPago, monto, referencia, fechaPago];
}
