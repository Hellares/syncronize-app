import 'package:equatable/equatable.dart';

class PagoSuscripcion extends Equatable {
  final String id;
  final String empresaId;
  final String planSuscripcionId;
  final double monto;
  final String moneda;
  final String periodo;
  final String metodoPago;
  final String? referencia;
  final String? notas;
  final String estado; // PENDIENTE, COMPLETADO, ANULADO
  final DateTime? fechaPago;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? comprobantePagoUrl;
  final String? planNombre;
  final String? motivoRechazo;
  final DateTime? creadoEn;

  const PagoSuscripcion({
    required this.id,
    required this.empresaId,
    required this.planSuscripcionId,
    required this.monto,
    required this.moneda,
    required this.periodo,
    required this.metodoPago,
    this.referencia,
    this.notas,
    required this.estado,
    this.fechaPago,
    this.fechaInicio,
    this.fechaFin,
    this.comprobantePagoUrl,
    this.planNombre,
    this.motivoRechazo,
    this.creadoEn,
  });

  bool get isPendiente => estado == 'PENDIENTE';
  bool get isCompletado => estado == 'COMPLETADO';
  bool get isAnulado => estado == 'ANULADO';

  @override
  List<Object?> get props => [
        id,
        empresaId,
        planSuscripcionId,
        monto,
        moneda,
        periodo,
        metodoPago,
        referencia,
        notas,
        estado,
        fechaPago,
        fechaInicio,
        fechaFin,
        comprobantePagoUrl,
        planNombre,
        motivoRechazo,
        creadoEn,
      ];
}
