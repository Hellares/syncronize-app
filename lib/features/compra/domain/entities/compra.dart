import 'package:equatable/equatable.dart';

enum EstadoCompra {
  BORRADOR,
  CONFIRMADA,
  ANULADA,
}

class CompraDetalle extends Equatable {
  final String id;
  final String compraId;
  final String? ordenCompraDetalleId;
  final String? productoId;
  final String? varianteId;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double porcentajeIGV;
  final double igv;
  final double subtotal;
  final double total;
  final String? loteId;
  final int orden;
  final Map<String, dynamic>? producto;
  final Map<String, dynamic>? variante;
  final Map<String, dynamic>? lote;
  final Map<String, dynamic>? ordenCompraDetalle;

  const CompraDetalle({
    required this.id,
    required this.compraId,
    this.ordenCompraDetalleId,
    this.productoId,
    this.varianteId,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0,
    this.porcentajeIGV = 18,
    this.igv = 0,
    this.subtotal = 0,
    this.total = 0,
    this.loteId,
    this.orden = 0,
    this.producto,
    this.variante,
    this.lote,
    this.ordenCompraDetalle,
  });

  String get nombreProducto {
    if (variante != null) return variante!['nombre'] ?? descripcion;
    if (producto != null) return producto!['nombre'] ?? descripcion;
    return descripcion;
  }

  @override
  List<Object?> get props => [id];
}

class Compra extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String proveedorId;
  final String? ordenCompraId;
  final String codigo;
  final String nombreProveedor;
  final String? documentoProveedor;
  final String? tipoDocumentoProveedor;
  final String? serieDocumentoProveedor;
  final String? numeroDocumentoProveedor;
  final String? terminosPago;
  final int? diasCredito;
  final DateTime? fechaVencimientoPago;
  final String moneda;
  final double? tipoCambio;
  final double subtotal;
  final double descuento;
  final double impuestos;
  final double total;
  final DateTime fechaRecepcion;
  final EstadoCompra estado;
  final String? observaciones;
  final String creadoPor;
  final String? confirmadoPor;
  final DateTime creadoEn;
  final DateTime? confirmadoEn;
  final DateTime actualizadoEn;
  final List<CompraDetalle>? detalles;
  final Map<String, dynamic>? sede;
  final Map<String, dynamic>? proveedor;
  final Map<String, dynamic>? ordenCompra;
  final List<Map<String, dynamic>>? lotes;
  final Map<String, dynamic>? count;

  const Compra({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.proveedorId,
    this.ordenCompraId,
    required this.codigo,
    required this.nombreProveedor,
    this.documentoProveedor,
    this.tipoDocumentoProveedor,
    this.serieDocumentoProveedor,
    this.numeroDocumentoProveedor,
    this.terminosPago,
    this.diasCredito,
    this.fechaVencimientoPago,
    this.moneda = 'PEN',
    this.tipoCambio,
    this.subtotal = 0,
    this.descuento = 0,
    this.impuestos = 0,
    this.total = 0,
    required this.fechaRecepcion,
    this.estado = EstadoCompra.BORRADOR,
    this.observaciones,
    required this.creadoPor,
    this.confirmadoPor,
    required this.creadoEn,
    this.confirmadoEn,
    required this.actualizadoEn,
    this.detalles,
    this.sede,
    this.proveedor,
    this.ordenCompra,
    this.lotes,
    this.count,
  });

  String get estadoTexto {
    switch (estado) {
      case EstadoCompra.BORRADOR:
        return 'Borrador';
      case EstadoCompra.CONFIRMADA:
        return 'Confirmada';
      case EstadoCompra.ANULADA:
        return 'Anulada';
    }
  }

  bool get esBorrador => estado == EstadoCompra.BORRADOR;
  bool get esConfirmada => estado == EstadoCompra.CONFIRMADA;
  bool get puedeEditar => estado == EstadoCompra.BORRADOR;
  bool get puedeConfirmar => estado == EstadoCompra.BORRADOR;
  bool get puedeAnular => estado == EstadoCompra.CONFIRMADA;
  String get sedeNombre => sede?['nombre'] ?? '';
  String get proveedorNombre => proveedor?['nombre'] ?? nombreProveedor;
  String? get ordenCompraCodigo => ordenCompra?['codigo'];

  @override
  List<Object?> get props => [id, estado, actualizadoEn];
}
