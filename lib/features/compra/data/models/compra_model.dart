import '../../domain/entities/compra.dart';

class CompraDetalleModel extends CompraDetalle {
  const CompraDetalleModel({
    required super.id,
    required super.compraId,
    super.ordenCompraDetalleId,
    super.productoId,
    super.varianteId,
    required super.descripcion,
    required super.cantidad,
    required super.precioUnitario,
    super.descuento,
    super.porcentajeIGV,
    super.igv,
    super.subtotal,
    super.total,
    super.loteId,
    super.orden,
    super.producto,
    super.variante,
    super.lote,
    super.ordenCompraDetalle,
  });

  factory CompraDetalleModel.fromJson(Map<String, dynamic> json) {
    return CompraDetalleModel(
      id: json['id'] as String,
      compraId: json['compraId'] as String? ?? '',
      ordenCompraDetalleId: json['ordenCompraDetalleId'] as String?,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      descripcion: json['descripcion'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: double.parse(json['precioUnitario'].toString()),
      descuento: double.parse((json['descuento'] ?? 0).toString()),
      porcentajeIGV: double.parse((json['porcentajeIGV'] ?? 18).toString()),
      igv: double.parse((json['igv'] ?? 0).toString()),
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      total: double.parse((json['total'] ?? 0).toString()),
      loteId: json['loteId'] as String?,
      orden: json['orden'] as int? ?? 0,
      producto: json['producto'] as Map<String, dynamic>?,
      variante: json['variante'] as Map<String, dynamic>?,
      lote: json['lote'] as Map<String, dynamic>?,
      ordenCompraDetalle: json['ordenCompraDetalle'] as Map<String, dynamic>?,
    );
  }
}

class CompraModel extends Compra {
  const CompraModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.proveedorId,
    super.ordenCompraId,
    required super.codigo,
    required super.nombreProveedor,
    super.documentoProveedor,
    super.tipoDocumentoProveedor,
    super.serieDocumentoProveedor,
    super.numeroDocumentoProveedor,
    super.terminosPago,
    super.diasCredito,
    super.fechaVencimientoPago,
    super.moneda,
    super.tipoCambio,
    super.subtotal,
    super.descuento,
    super.impuestos,
    super.total,
    required super.fechaRecepcion,
    super.estado,
    super.observaciones,
    required super.creadoPor,
    super.confirmadoPor,
    required super.creadoEn,
    super.confirmadoEn,
    required super.actualizadoEn,
    super.detalles,
    super.sede,
    super.proveedor,
    super.ordenCompra,
    super.lotes,
    super.count,
  });

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    return CompraModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      proveedorId: json['proveedorId'] as String,
      ordenCompraId: json['ordenCompraId'] as String?,
      codigo: json['codigo'] as String,
      nombreProveedor: json['nombreProveedor'] as String,
      documentoProveedor: json['documentoProveedor'] as String?,
      tipoDocumentoProveedor: json['tipoDocumentoProveedor'] as String?,
      serieDocumentoProveedor: json['serieDocumentoProveedor'] as String?,
      numeroDocumentoProveedor: json['numeroDocumentoProveedor'] as String?,
      terminosPago: json['terminosPago'] as String?,
      diasCredito: json['diasCredito'] as int?,
      fechaVencimientoPago: json['fechaVencimientoPago'] != null
          ? DateTime.parse(json['fechaVencimientoPago'] as String)
          : null,
      moneda: json['moneda'] as String? ?? 'PEN',
      tipoCambio: json['tipoCambio'] != null
          ? double.parse(json['tipoCambio'].toString())
          : null,
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      descuento: double.parse((json['descuento'] ?? 0).toString()),
      impuestos: double.parse((json['impuestos'] ?? 0).toString()),
      total: double.parse((json['total'] ?? 0).toString()),
      fechaRecepcion: DateTime.parse(json['fechaRecepcion'] as String),
      estado: _estadoFromString(json['estado'] as String),
      observaciones: json['observaciones'] as String?,
      creadoPor: json['creadoPor'] as String,
      confirmadoPor: json['confirmadoPor'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      confirmadoEn: json['confirmadoEn'] != null
          ? DateTime.parse(json['confirmadoEn'] as String)
          : null,
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((e) => CompraDetalleModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      sede: json['sede'] as Map<String, dynamic>?,
      proveedor: json['proveedor'] as Map<String, dynamic>?,
      ordenCompra: json['ordenCompra'] as Map<String, dynamic>?,
      lotes: json['lotes'] != null
          ? (json['lotes'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      count: json['_count'] as Map<String, dynamic>?,
    );
  }

  static EstadoCompra _estadoFromString(String estado) {
    switch (estado) {
      case 'BORRADOR': return EstadoCompra.BORRADOR;
      case 'CONFIRMADA': return EstadoCompra.CONFIRMADA;
      case 'ANULADA': return EstadoCompra.ANULADA;
      default: return EstadoCompra.BORRADOR;
    }
  }
}
