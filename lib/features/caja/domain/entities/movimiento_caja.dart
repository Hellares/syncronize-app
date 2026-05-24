import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de movimiento de caja
enum TipoMovimientoCaja {
  ingreso,
  egreso;

  String get label {
    switch (this) {
      case TipoMovimientoCaja.ingreso:
        return 'Ingreso';
      case TipoMovimientoCaja.egreso:
        return 'Egreso';
    }
  }

  String get apiValue => name.toUpperCase();

  Color get color {
    switch (this) {
      case TipoMovimientoCaja.ingreso:
        return const Color(0xFF4CAF50);
      case TipoMovimientoCaja.egreso:
        return const Color(0xFFF54D85);
    }
  }

  IconData get icon {
    switch (this) {
      case TipoMovimientoCaja.ingreso:
        return Icons.arrow_downward_rounded;
      case TipoMovimientoCaja.egreso:
        return Icons.arrow_upward_rounded;
    }
  }

  static TipoMovimientoCaja fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INGRESO':
        return TipoMovimientoCaja.ingreso;
      case 'EGRESO':
        return TipoMovimientoCaja.egreso;
      default:
        return TipoMovimientoCaja.ingreso;
    }
  }
}

/// Categoria del movimiento de caja
enum CategoriaMovimientoCaja {
  venta,
  pedidoMarketplace,
  compra,
  devolucion,
  adelantoServicio,
  adelantoCotizacion,
  devolucionAdelantoCotizacion,
  otroIngreso,
  pagoProveedor,
  gastoOperativo,
  otroEgreso,
  reposicionCajaChica,
  // Tesoreria (Caja Central): generadas auto (barrido al cerrar caja y
  // reverso de caja cerrada) o manual desde la pantalla de Tesoreria.
  // NO aparecen en el form de movimiento manual operativo.
  depositoTesoreria,
  retiroTesoreria,
  ajusteTesoreria,
  reversoCajaCerrada;

  String get label {
    switch (this) {
      case CategoriaMovimientoCaja.venta:
        return 'Venta';
      case CategoriaMovimientoCaja.pedidoMarketplace:
        return 'Pedido Marketplace';
      case CategoriaMovimientoCaja.compra:
        return 'Compra';
      case CategoriaMovimientoCaja.devolucion:
        return 'Devolucion';
      case CategoriaMovimientoCaja.adelantoServicio:
        return 'Adelanto Servicio';
      case CategoriaMovimientoCaja.adelantoCotizacion:
        return 'Adelanto Cotización';
      case CategoriaMovimientoCaja.devolucionAdelantoCotizacion:
        return 'Devolución Adelanto Cotización';
      case CategoriaMovimientoCaja.otroIngreso:
        return 'Otro Ingreso';
      case CategoriaMovimientoCaja.pagoProveedor:
        return 'Pago Proveedor';
      case CategoriaMovimientoCaja.gastoOperativo:
        return 'Gasto Operativo';
      case CategoriaMovimientoCaja.otroEgreso:
        return 'Otro Egreso';
      case CategoriaMovimientoCaja.reposicionCajaChica:
        return 'Reposición Caja Chica';
      case CategoriaMovimientoCaja.depositoTesoreria:
        return 'Depósito a Tesorería';
      case CategoriaMovimientoCaja.retiroTesoreria:
        return 'Retiro de Tesorería';
      case CategoriaMovimientoCaja.ajusteTesoreria:
        return 'Ajuste de Tesorería';
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return 'Reverso (Caja Cerrada)';
    }
  }

  String get apiValue {
    switch (this) {
      case CategoriaMovimientoCaja.venta:
        return 'VENTA';
      case CategoriaMovimientoCaja.pedidoMarketplace:
        return 'PEDIDO_MARKETPLACE';
      case CategoriaMovimientoCaja.compra:
        return 'COMPRA';
      case CategoriaMovimientoCaja.devolucion:
        return 'DEVOLUCION';
      case CategoriaMovimientoCaja.adelantoServicio:
        return 'ADELANTO_SERVICIO';
      case CategoriaMovimientoCaja.adelantoCotizacion:
        return 'ADELANTO_COTIZACION';
      case CategoriaMovimientoCaja.devolucionAdelantoCotizacion:
        return 'DEVOLUCION_ADELANTO_COTIZACION';
      case CategoriaMovimientoCaja.otroIngreso:
        return 'OTRO_INGRESO';
      case CategoriaMovimientoCaja.pagoProveedor:
        return 'PAGO_PROVEEDOR';
      case CategoriaMovimientoCaja.gastoOperativo:
        return 'GASTO_OPERATIVO';
      case CategoriaMovimientoCaja.otroEgreso:
        return 'OTRO_EGRESO';
      case CategoriaMovimientoCaja.reposicionCajaChica:
        return 'REPOSICION_CAJA_CHICA';
      case CategoriaMovimientoCaja.depositoTesoreria:
        return 'DEPOSITO_TESORERIA';
      case CategoriaMovimientoCaja.retiroTesoreria:
        return 'RETIRO_TESORERIA';
      case CategoriaMovimientoCaja.ajusteTesoreria:
        return 'AJUSTE_TESORERIA';
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return 'REVERSO_CAJA_CERRADA';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoriaMovimientoCaja.venta:
        return Icons.shopping_cart_rounded;
      case CategoriaMovimientoCaja.pedidoMarketplace:
        return Icons.storefront_rounded;
      case CategoriaMovimientoCaja.compra:
        return Icons.shopping_bag_rounded;
      case CategoriaMovimientoCaja.devolucion:
        return Icons.assignment_return_rounded;
      case CategoriaMovimientoCaja.adelantoServicio:
        return Icons.handyman_rounded;
      case CategoriaMovimientoCaja.adelantoCotizacion:
        return Icons.request_quote_rounded;
      case CategoriaMovimientoCaja.devolucionAdelantoCotizacion:
        return Icons.assignment_return_outlined;
      case CategoriaMovimientoCaja.otroIngreso:
        return Icons.add_circle_rounded;
      case CategoriaMovimientoCaja.pagoProveedor:
        return Icons.payment_rounded;
      case CategoriaMovimientoCaja.gastoOperativo:
        return Icons.receipt_long_rounded;
      case CategoriaMovimientoCaja.otroEgreso:
        return Icons.remove_circle_rounded;
      case CategoriaMovimientoCaja.reposicionCajaChica:
        return Icons.account_balance_wallet_rounded;
      case CategoriaMovimientoCaja.depositoTesoreria:
        return Icons.savings_rounded;
      case CategoriaMovimientoCaja.retiroTesoreria:
        return Icons.outbox_rounded;
      case CategoriaMovimientoCaja.ajusteTesoreria:
        return Icons.tune_rounded;
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return Icons.undo_rounded;
    }
  }

  bool get esIngreso {
    switch (this) {
      case CategoriaMovimientoCaja.venta:
      case CategoriaMovimientoCaja.pedidoMarketplace:
      case CategoriaMovimientoCaja.adelantoServicio:
      case CategoriaMovimientoCaja.adelantoCotizacion:
      case CategoriaMovimientoCaja.otroIngreso:
        return true;
      // COMPRA: pagamos al proveedor → sale plata de caja.
      // DEVOLUCION: devolvemos al cliente → sale plata de caja.
      case CategoriaMovimientoCaja.compra:
      case CategoriaMovimientoCaja.devolucion:
      case CategoriaMovimientoCaja.devolucionAdelantoCotizacion:
      case CategoriaMovimientoCaja.pagoProveedor:
      case CategoriaMovimientoCaja.gastoOperativo:
      case CategoriaMovimientoCaja.otroEgreso:
      case CategoriaMovimientoCaja.reposicionCajaChica:
      // Categorias de tesoreria: polaridad ambigua (un mismo concepto
      // aparece como INGRESO en central y EGRESO en operativa, o viceversa).
      // El `tipo` del movimiento es la fuente de verdad real; este getter
      // devuelve `false` solo para que el filtro `porTipo` las excluya del
      // form manual operativo (ver `esTesoreria`).
      case CategoriaMovimientoCaja.depositoTesoreria:
      case CategoriaMovimientoCaja.retiroTesoreria:
      case CategoriaMovimientoCaja.ajusteTesoreria:
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return false;
    }
  }

  /// True si la categoria pertenece al modulo Tesoreria (Caja Central).
  /// Se usa para EXCLUIRLAS del form de movimiento manual operativo —
  /// los movs de tesoreria se crean vía endpoint dedicado o auto.
  bool get esTesoreria {
    switch (this) {
      case CategoriaMovimientoCaja.depositoTesoreria:
      case CategoriaMovimientoCaja.retiroTesoreria:
      case CategoriaMovimientoCaja.ajusteTesoreria:
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return true;
      default:
        return false;
    }
  }

  static CategoriaMovimientoCaja fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VENTA':
        return CategoriaMovimientoCaja.venta;
      case 'PEDIDO_MARKETPLACE':
        return CategoriaMovimientoCaja.pedidoMarketplace;
      case 'COMPRA':
        return CategoriaMovimientoCaja.compra;
      case 'DEVOLUCION':
        return CategoriaMovimientoCaja.devolucion;
      case 'ADELANTO_SERVICIO':
        return CategoriaMovimientoCaja.adelantoServicio;
      case 'ADELANTO_COTIZACION':
        return CategoriaMovimientoCaja.adelantoCotizacion;
      case 'DEVOLUCION_ADELANTO_COTIZACION':
        return CategoriaMovimientoCaja.devolucionAdelantoCotizacion;
      case 'OTRO_INGRESO':
        return CategoriaMovimientoCaja.otroIngreso;
      case 'PAGO_PROVEEDOR':
        return CategoriaMovimientoCaja.pagoProveedor;
      case 'GASTO_OPERATIVO':
        return CategoriaMovimientoCaja.gastoOperativo;
      case 'OTRO_EGRESO':
        return CategoriaMovimientoCaja.otroEgreso;
      case 'REPOSICION_CAJA_CHICA':
        return CategoriaMovimientoCaja.reposicionCajaChica;
      case 'DEPOSITO_TESORERIA':
        return CategoriaMovimientoCaja.depositoTesoreria;
      case 'RETIRO_TESORERIA':
        return CategoriaMovimientoCaja.retiroTesoreria;
      case 'AJUSTE_TESORERIA':
        return CategoriaMovimientoCaja.ajusteTesoreria;
      case 'REVERSO_CAJA_CERRADA':
        return CategoriaMovimientoCaja.reversoCajaCerrada;
      default:
        return CategoriaMovimientoCaja.otroIngreso;
    }
  }

  /// Retorna categorias filtradas por tipo. Excluye las de tesoreria
  /// (esas se crean via endpoint dedicado de Caja Central, no desde el
  /// form de movimiento manual operativo).
  static List<CategoriaMovimientoCaja> porTipo(TipoMovimientoCaja tipo) {
    return values.where((c) {
      if (c.esTesoreria) return false;
      if (tipo == TipoMovimientoCaja.ingreso) return c.esIngreso;
      return !c.esIngreso;
    }).toList();
  }
}

/// Metodo de pago
enum MetodoPago {
  efectivo,
  tarjeta,
  yape,
  plin,
  transferencia,
  credito;

  String get label {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.yape:
        return 'Yape';
      case MetodoPago.plin:
        return 'Plin';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.credito:
        return 'Credito';
    }
  }

  String get apiValue => name.toUpperCase();

  IconData get icon {
    switch (this) {
      case MetodoPago.efectivo:
        return Icons.money_rounded;
      case MetodoPago.tarjeta:
        return Icons.credit_card_rounded;
      case MetodoPago.yape:
        return Icons.phone_android_rounded;
      case MetodoPago.plin:
        return Icons.phone_iphone_rounded;
      case MetodoPago.transferencia:
        return Icons.account_balance_rounded;
      case MetodoPago.credito:
        return Icons.schedule_rounded;
    }
  }

  static MetodoPago fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EFECTIVO':
        return MetodoPago.efectivo;
      case 'TARJETA':
        return MetodoPago.tarjeta;
      case 'YAPE':
        return MetodoPago.yape;
      case 'PLIN':
        return MetodoPago.plin;
      case 'TRANSFERENCIA':
        return MetodoPago.transferencia;
      case 'CREDITO':
        return MetodoPago.credito;
      default:
        return MetodoPago.efectivo;
    }
  }
}

/// Entity que representa un movimiento de caja
class MovimientoCaja extends Equatable {
  final String id;
  final String cajaId;
  final TipoMovimientoCaja tipo;
  final CategoriaMovimientoCaja categoria;
  final MetodoPago metodoPago;
  final double monto;
  final String? descripcion;
  final String? categoriaGastoId;
  final String? categoriaGastoNombre;
  final bool esManual;
  final DateTime fechaMovimiento;
  final String? ventaId;
  final String? ventaCodigo;
  final String? pedidoCodigo;
  final String? devolucionId;
  final String? devolucionCodigo;
  final String? compraId;
  final String? compraCodigo;
  final String? cotizacionId;
  final String? cotizacionCodigo;
  /// Estado de la cotización vinculada (si aplica). Apunta a si el
  /// ADELANTO_COTIZACION asociado tuvo su devolución por anulación.
  /// Valores backend: BORRADOR | PENDIENTE | APROBADA | RECHAZADA |
  /// VENCIDA | CONVERTIDA.
  final String? cotizacionEstado;
  /// Nombre del usuario que registró el movimiento (cajero o admin).
  /// Útil en tesorería para identificar quién hizo el barrido/ajuste.
  final String? registradoPorNombre;
  final bool anulado;
  final String? motivoAnulacion;

  /// Metadata libre (JSON). Usado por tesoreria para agrupar movs del
  /// mismo cierre (`cierreId`), trazar el espejo (`movimientoEspejoId`)
  /// y marcar reversos (`esReversoCajaCerrada`).
  final Map<String, dynamic>? metadata;

  const MovimientoCaja({
    required this.id,
    required this.cajaId,
    required this.tipo,
    required this.categoria,
    required this.metodoPago,
    required this.monto,
    this.descripcion,
    this.categoriaGastoId,
    this.categoriaGastoNombre,
    this.esManual = false,
    required this.fechaMovimiento,
    this.ventaId,
    this.ventaCodigo,
    this.pedidoCodigo,
    this.devolucionId,
    this.devolucionCodigo,
    this.compraId,
    this.compraCodigo,
    this.cotizacionId,
    this.cotizacionCodigo,
    this.cotizacionEstado,
    this.registradoPorNombre,
    this.anulado = false,
    this.motivoAnulacion,
    this.metadata,
  });

  /// True si la cotización vinculada a este movimiento de adelanto está
  /// RECHAZADA (anulada). Indica que se generó la devolución correspondiente.
  bool get cotizacionFueAnulada => cotizacionEstado == 'RECHAZADA';

  @override
  List<Object?> get props => [
        id,
        cajaId,
        tipo,
        categoria,
        metodoPago,
        monto,
        descripcion,
        categoriaGastoId,
        categoriaGastoNombre,
        esManual,
        fechaMovimiento,
        ventaId,
        ventaCodigo,
        pedidoCodigo,
        devolucionId,
        devolucionCodigo,
        compraId,
        compraCodigo,
        cotizacionId,
        cotizacionCodigo,
        cotizacionEstado,
        registradoPorNombre,
        anulado,
        motivoAnulacion,
        metadata,
      ];
}
