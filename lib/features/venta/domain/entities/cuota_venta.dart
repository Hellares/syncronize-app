import 'package:equatable/equatable.dart';

class CuotaVenta extends Equatable {
  final String id;
  final String ventaId;
  final int numero;
  final double monto;
  final double montoPagado;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado; // PENDIENTE, PAGADA_PARCIAL, PAGADA, VENCIDA

  const CuotaVenta({
    required this.id,
    required this.ventaId,
    required this.numero,
    required this.monto,
    required this.montoPagado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
  });

  bool get estaPagada => estado == 'PAGADA';
  bool get estaVencida => estado == 'VENCIDA';
  bool get tieneSaldo => saldoPendiente > 0;

  @override
  List<Object?> get props => [id, ventaId, numero, monto, montoPagado, saldoPendiente, fechaVencimiento, estado];
}
