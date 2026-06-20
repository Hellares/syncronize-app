import 'package:equatable/equatable.dart';

class BancoPrincipal extends Equatable {
  final String nombreBanco;
  final String numeroCuenta;

  const BancoPrincipal({required this.nombreBanco, required this.numeroCuenta});

  @override
  List<Object?> get props => [nombreBanco, numeroCuenta];
}

class CuentaPorPagar extends Equatable {
  final String id;
  final String codigo;
  final String nombreProveedor;
  final double saldoPendiente;
  final double totalCompra;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final DateTime? fechaCompra;
  final BancoPrincipal? bancoPrincipal;

  const CuentaPorPagar({
    required this.id,
    required this.codigo,
    required this.nombreProveedor,
    required this.saldoPendiente,
    required this.totalCompra,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.fechaCompra,
    this.bancoPrincipal,
  });

  /// Pagado = total − saldo (el endpoint de lista no trae el pagado por separado).
  double get totalPagado => (totalCompra - saldoPendiente).clamp(0, totalCompra);

  @override
  List<Object?> get props => [id, codigo, nombreProveedor, saldoPendiente, totalCompra, estado];
}

/// Una línea de la compra (qué se compró).
class CompraItem extends Equatable {
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final bool usaUnidadCompra;
  final double? cantidadOriginal;
  final String? unidadOriginalSimbolo;

  const CompraItem({
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    this.usaUnidadCompra = false,
    this.cantidadOriginal,
    this.unidadOriginalSimbolo,
  });

  @override
  List<Object?> get props => [descripcion, cantidad, precioUnitario, total];
}

/// Un pago/abono ya realizado sobre la compra.
class PagoRealizado extends Equatable {
  final String id;
  final String metodoPago;
  final double monto;
  final String? referencia;
  final String? bancoDestino;
  final String? cuentaDestino;
  final String? comprobanteUrl;
  final DateTime? fechaPago;

  const PagoRealizado({
    required this.id,
    required this.metodoPago,
    required this.monto,
    this.referencia,
    this.bancoDestino,
    this.cuentaDestino,
    this.comprobanteUrl,
    this.fechaPago,
  });

  /// Métodos digitales que tienen voucher (habilitan adjuntar comprobante).
  bool get esDigital =>
      metodoPago == 'YAPE' ||
      metodoPago == 'PLIN' ||
      metodoPago == 'TRANSFERENCIA' ||
      metodoPago == 'TARJETA';

  bool get tieneComprobante => comprobanteUrl != null && comprobanteUrl!.isNotEmpty;

  @override
  List<Object?> get props => [id, metodoPago, monto, comprobanteUrl, fechaPago];
}

/// Detalle completo de una cuenta por pagar: cabecera + ítems + historial de pagos.
class CuentaPagarDetalle extends Equatable {
  final String id;
  final String codigo;
  final String nombreProveedor;
  final String? documentoProveedor;
  final String? sedeNombre;
  final String estado;
  final double totalCompra;
  final double totalPagado;
  final double saldoPendiente;
  final double subtotal;
  final double impuestos;
  final double descuento;
  final String? terminosPago;
  final DateTime? fechaCompra;
  final DateTime? fechaVencimiento;
  final int? diasVencimiento;
  final String? observaciones;
  final String? tipoDocumentoProveedor;
  final String? serieDocumentoProveedor;
  final String? numeroDocumentoProveedor;
  final BancoPrincipal? bancoPrincipal;
  final List<CompraItem> detalles;
  final List<PagoRealizado> pagos;

  const CuentaPagarDetalle({
    required this.id,
    required this.codigo,
    required this.nombreProveedor,
    this.documentoProveedor,
    this.sedeNombre,
    required this.estado,
    required this.totalCompra,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.subtotal,
    required this.impuestos,
    required this.descuento,
    this.terminosPago,
    this.fechaCompra,
    this.fechaVencimiento,
    this.diasVencimiento,
    this.observaciones,
    this.tipoDocumentoProveedor,
    this.serieDocumentoProveedor,
    this.numeroDocumentoProveedor,
    this.bancoPrincipal,
    this.detalles = const [],
    this.pagos = const [],
  });

  String? get documentoProveedorCompleto {
    if (serieDocumentoProveedor == null && numeroDocumentoProveedor == null) {
      return null;
    }
    final partes = [
      tipoDocumentoProveedor,
      [serieDocumentoProveedor, numeroDocumentoProveedor].where((e) => e != null && e.isNotEmpty).join('-'),
    ].where((e) => e != null && e.isNotEmpty).join(' ');
    return partes.isEmpty ? null : partes;
  }

  /// Convierte el detalle a la entidad de lista (para reusar el sheet de pago).
  CuentaPorPagar toCuenta() => CuentaPorPagar(
        id: id,
        codigo: codigo,
        nombreProveedor: nombreProveedor,
        saldoPendiente: saldoPendiente,
        totalCompra: totalCompra,
        estado: estado,
        diasVencimiento: diasVencimiento,
        fechaVencimiento: fechaVencimiento,
        fechaCompra: fechaCompra,
        bancoPrincipal: bancoPrincipal,
      );

  @override
  List<Object?> get props => [id, codigo, estado, saldoPendiente, totalPagado, pagos];
}

/// Deuda agregada de un proveedor (vista "Por proveedor").
class DeudaProveedor extends Equatable {
  final String proveedorId;
  final String nombreProveedor;
  final String? documentoProveedor;
  final double totalDeuda;
  final double totalVencido;
  final int cantidadCompras;
  final int cantidadVencidas;
  final DateTime? proximoVencimiento;

  const DeudaProveedor({
    required this.proveedorId,
    required this.nombreProveedor,
    this.documentoProveedor,
    required this.totalDeuda,
    required this.totalVencido,
    required this.cantidadCompras,
    required this.cantidadVencidas,
    this.proximoVencimiento,
  });

  @override
  List<Object?> get props => [proveedorId, totalDeuda, totalVencido, cantidadCompras];
}

class ResumenCuentasPagar extends Equatable {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;

  const ResumenCuentasPagar({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
  });

  double get totalPorPagar => totalPendiente + totalVencido;

  @override
  List<Object?> get props => [totalPendiente, totalVencido, cantidadPendientes, cantidadVencidas];
}
