import 'package:equatable/equatable.dart';
import 'arqueo_caja.dart';
import 'caja.dart';
import 'cierre_caja.dart';
import 'movimiento_caja.dart';
import 'resumen_caja.dart';

/// Snapshot en vivo de saldos de una caja (calculado al momento del request).
/// Si la caja está CERRADA, comparar contra `CierreCaja` para detectar drift
/// (ej: un movimiento anulado después del cierre).
class ResumenActualCaja extends Equatable {
  final double montoApertura;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoActual;
  final double saldoEfectivo;
  final List<DetalleMetodoCaja> detallesPorMetodo;
  final double egresoAnulacionVenta;
  final int cantidadAnulaciones;
  final List<EgresoPorCategoria> egresosPorCategoria;

  const ResumenActualCaja({
    required this.montoApertura,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoActual,
    required this.saldoEfectivo,
    required this.detallesPorMetodo,
    this.egresoAnulacionVenta = 0,
    this.cantidadAnulaciones = 0,
    this.egresosPorCategoria = const [],
  });

  @override
  List<Object?> get props => [
        montoApertura,
        totalIngresos,
        totalEgresos,
        saldoActual,
        saldoEfectivo,
        detallesPorMetodo,
        egresoAnulacionVenta,
        cantidadAnulaciones,
        egresosPorCategoria,
      ];
}

class DetalleMetodoCaja extends Equatable {
  final MetodoPago metodoPago;
  final double apertura;
  final double ingresos;
  final double egresos;
  final double saldo;

  const DetalleMetodoCaja({
    required this.metodoPago,
    required this.apertura,
    required this.ingresos,
    required this.egresos,
    required this.saldo,
  });

  @override
  List<Object?> get props => [metodoPago, apertura, ingresos, egresos, saldo];
}

/// Movimiento enriquecido para auditoría: incluye flag `esContrapartida` para
/// distinguir movimientos auto-generados al anular (que normalmente se ocultan
/// en el listado regular vía `contrapartidaDe`).
class MovimientoAuditoria extends MovimientoCaja {
  final bool esContrapartida;
  final String? anuladoPorNombre;

  const MovimientoAuditoria({
    required super.id,
    required super.cajaId,
    required super.tipo,
    required super.categoria,
    required super.metodoPago,
    required super.monto,
    super.descripcion,
    super.categoriaGastoId,
    super.categoriaGastoNombre,
    super.esManual,
    required super.fechaMovimiento,
    super.ventaId,
    super.ventaCodigo,
    super.pedidoCodigo,
    super.cotizacionId,
    super.cotizacionCodigo,
    super.cotizacionEstado,
    super.registradoPorNombre,
    super.anulado,
    super.motivoAnulacion,
    this.esContrapartida = false,
    this.anuladoPorNombre,
  });
}

/// Respuesta del endpoint GET /caja/:id/auditoria.
class CajaAuditoria extends Equatable {
  final Caja caja;
  final ResumenActualCaja resumenActual;
  final CierreCaja? cierre;
  final List<ArqueoCaja> arqueos;
  final List<MovimientoAuditoria> movimientos;

  const CajaAuditoria({
    required this.caja,
    required this.resumenActual,
    this.cierre,
    required this.arqueos,
    required this.movimientos,
  });

  @override
  List<Object?> get props => [caja, resumenActual, cierre, arqueos, movimientos];
}
