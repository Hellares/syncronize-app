import 'package:equatable/equatable.dart';

enum FuentePagoGasto {
  caja,
  banco;

  String get label => this == caja ? 'Caja' : 'Banco';
  String get apiValue => name.toUpperCase();

  static FuentePagoGasto fromString(String value) {
    return value.toUpperCase() == 'BANCO'
        ? FuentePagoGasto.banco
        : FuentePagoGasto.caja;
  }
}

enum MetodoPagoGasto {
  efectivo,
  tarjeta,
  yape,
  plin,
  transferencia;

  String get label {
    switch (this) {
      case MetodoPagoGasto.efectivo:
        return 'Efectivo';
      case MetodoPagoGasto.tarjeta:
        return 'Tarjeta';
      case MetodoPagoGasto.yape:
        return 'Yape';
      case MetodoPagoGasto.plin:
        return 'Plin';
      case MetodoPagoGasto.transferencia:
        return 'Transferencia';
    }
  }

  String get apiValue => name.toUpperCase();

  static MetodoPagoGasto fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TARJETA':
        return MetodoPagoGasto.tarjeta;
      case 'YAPE':
        return MetodoPagoGasto.yape;
      case 'PLIN':
        return MetodoPagoGasto.plin;
      case 'TRANSFERENCIA':
        return MetodoPagoGasto.transferencia;
      case 'EFECTIVO':
      default:
        return MetodoPagoGasto.efectivo;
    }
  }
}

enum EstadoPeriodoGasto {
  pagado,
  pendiente,
  vencido;

  String get label {
    switch (this) {
      case EstadoPeriodoGasto.pagado:
        return 'Pagado';
      case EstadoPeriodoGasto.pendiente:
        return 'Pendiente';
      case EstadoPeriodoGasto.vencido:
        return 'Vencido';
    }
  }

  static EstadoPeriodoGasto fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PAGADO':
        return EstadoPeriodoGasto.pagado;
      case 'VENCIDO':
        return EstadoPeriodoGasto.vencido;
      case 'PENDIENTE':
      default:
        return EstadoPeriodoGasto.pendiente;
    }
  }
}

class PagoGastoRecurrente extends Equatable {
  final String id;
  final String gastoRecurrenteId;
  final String periodo; // "YYYY-MM"
  final double montoReal;
  final DateTime fechaPago;
  final FuentePagoGasto fuente;
  final MetodoPagoGasto metodoPago;
  final String? bancoId;
  final String? bancoNombre;
  final String? bancoNumeroCuenta;
  final String? movimientoCajaId;
  final String? comprobanteUrl;
  final String? notas;
  final String? registradoPorNombre;

  const PagoGastoRecurrente({
    required this.id,
    required this.gastoRecurrenteId,
    required this.periodo,
    required this.montoReal,
    required this.fechaPago,
    required this.fuente,
    required this.metodoPago,
    this.bancoId,
    this.bancoNombre,
    this.bancoNumeroCuenta,
    this.movimientoCajaId,
    this.comprobanteUrl,
    this.notas,
    this.registradoPorNombre,
  });

  @override
  List<Object?> get props => [
        id,
        gastoRecurrenteId,
        periodo,
        montoReal,
        fechaPago,
        fuente,
        metodoPago,
        bancoId,
        movimientoCajaId,
        comprobanteUrl,
      ];
}
