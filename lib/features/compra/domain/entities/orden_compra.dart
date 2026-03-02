import 'package:equatable/equatable.dart';

enum EstadoOrdenCompra {
  BORRADOR,
  PENDIENTE,
  APROBADA,
  PARCIAL,
  COMPLETADA,
  CANCELADA,
}

class OrdenCompraDetalle extends Equatable {
  final String id;
  final String ordenCompraId;
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
  final int cantidadRecibida;
  final int cantidadPendiente;
  final int orden;
  // Relaciones expandidas
  final Map<String, dynamic>? producto;
  final Map<String, dynamic>? variante;

  const OrdenCompraDetalle({
    required this.id,
    required this.ordenCompraId,
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
    this.cantidadRecibida = 0,
    required this.cantidadPendiente,
    this.orden = 0,
    this.producto,
    this.variante,
  });

  String get nombreProducto {
    if (variante != null) return variante!['nombre'] ?? descripcion;
    if (producto != null) return producto!['nombre'] ?? descripcion;
    return descripcion;
  }

  double get porcentajeRecibido =>
      cantidad > 0 ? (cantidadRecibida / cantidad) * 100 : 0;

  @override
  List<Object?> get props => [id];
}

class OrdenCompra extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String proveedorId;
  final String codigo;
  final String nombreProveedor;
  final String? documentoProveedor;
  final String? emailProveedor;
  final String? telefonoProveedor;
  final String? direccionProveedor;
  final String? terminosPago;
  final int? diasCredito;
  final String moneda;
  final double? tipoCambio;
  final double subtotal;
  final double descuento;
  final double impuestos;
  final double total;
  final DateTime fechaEmision;
  final DateTime? fechaEntregaEsperada;
  final DateTime? fechaAprobacion;
  final EstadoOrdenCompra estado;
  final String? observaciones;
  final String? condiciones;
  final String creadoPor;
  final String? aprobadoPor;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<OrdenCompraDetalle>? detalles;
  final Map<String, dynamic>? sede;
  final Map<String, dynamic>? proveedor;
  final List<Map<String, dynamic>>? compras;
  final Map<String, dynamic>? count;

  const OrdenCompra({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.proveedorId,
    required this.codigo,
    required this.nombreProveedor,
    this.documentoProveedor,
    this.emailProveedor,
    this.telefonoProveedor,
    this.direccionProveedor,
    this.terminosPago,
    this.diasCredito,
    this.moneda = 'PEN',
    this.tipoCambio,
    this.subtotal = 0,
    this.descuento = 0,
    this.impuestos = 0,
    this.total = 0,
    required this.fechaEmision,
    this.fechaEntregaEsperada,
    this.fechaAprobacion,
    this.estado = EstadoOrdenCompra.BORRADOR,
    this.observaciones,
    this.condiciones,
    required this.creadoPor,
    this.aprobadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.detalles,
    this.sede,
    this.proveedor,
    this.compras,
    this.count,
  });

  String get estadoTexto {
    switch (estado) {
      case EstadoOrdenCompra.BORRADOR:
        return 'Borrador';
      case EstadoOrdenCompra.PENDIENTE:
        return 'Pendiente';
      case EstadoOrdenCompra.APROBADA:
        return 'Aprobada';
      case EstadoOrdenCompra.PARCIAL:
        return 'Parcial';
      case EstadoOrdenCompra.COMPLETADA:
        return 'Completada';
      case EstadoOrdenCompra.CANCELADA:
        return 'Cancelada';
    }
  }

  bool get esBorrador => estado == EstadoOrdenCompra.BORRADOR;
  bool get puedeEditar => estado == EstadoOrdenCompra.BORRADOR;
  String get sedeNombre => sede?['nombre'] ?? '';
  String get proveedorNombre => proveedor?['nombre'] ?? nombreProveedor;
  int get totalDetalles => count?['detalles'] ?? detalles?.length ?? 0;

  @override
  List<Object?> get props => [id, estado, actualizadoEn];
}
