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
  final double montoMora;
  final int diasVencido;
  final double montoPrincipal;
  final double montoInteresCuota;
  final double montoPagadoPrincipal;
  final double montoPagadoInteres;
  final double montoPagadoMora;

  const CuotaVenta({
    required this.id,
    required this.ventaId,
    required this.numero,
    required this.monto,
    required this.montoPagado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
    this.montoMora = 0,
    this.diasVencido = 0,
    this.montoPrincipal = 0,
    this.montoInteresCuota = 0,
    this.montoPagadoPrincipal = 0,
    this.montoPagadoInteres = 0,
    this.montoPagadoMora = 0,
  });

  bool get estaPagada => estado == 'PAGADA';
  bool get estaVencida => estado == 'VENCIDA';
  bool get tieneSaldo => saldoPendiente > 0;
  bool get tieneMora => montoMora > 0;
  double get totalConMora => saldoPendiente + montoMora;

  @override
  List<Object?> get props => [id, ventaId, numero, monto, montoPagado, saldoPendiente, fechaVencimiento, estado, montoMora, diasVencido, montoPrincipal, montoInteresCuota, montoPagadoPrincipal, montoPagadoInteres, montoPagadoMora];
}
