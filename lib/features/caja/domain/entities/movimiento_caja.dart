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
  otroIngreso,
  pagoProveedor,
  gastoOperativo,
  otroEgreso,
  reposicionCajaChica;

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
    }
  }

  bool get esIngreso {
    switch (this) {
      case CategoriaMovimientoCaja.venta:
      case CategoriaMovimientoCaja.pedidoMarketplace:
      case CategoriaMovimientoCaja.compra:
      case CategoriaMovimientoCaja.devolucion:
      case CategoriaMovimientoCaja.adelantoServicio:
      case CategoriaMovimientoCaja.otroIngreso:
        return true;
      case CategoriaMovimientoCaja.pagoProveedor:
      case CategoriaMovimientoCaja.gastoOperativo:
      case CategoriaMovimientoCaja.otroEgreso:
      case CategoriaMovimientoCaja.reposicionCajaChica:
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
      default:
        return CategoriaMovimientoCaja.otroIngreso;
    }
  }

  /// Retorna categorias filtradas por tipo
  static List<CategoriaMovimientoCaja> porTipo(TipoMovimientoCaja tipo) {
    return values.where((c) {
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
  final String? ventaCodigo;
  final String? pedidoCodigo;
  final bool anulado;
  final String? motivoAnulacion;

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
    this.ventaCodigo,
    this.pedidoCodigo,
    this.anulado = false,
    this.motivoAnulacion,
  });

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
        ventaCodigo,
        pedidoCodigo,
        anulado,
        motivoAnulacion,
      ];
}
