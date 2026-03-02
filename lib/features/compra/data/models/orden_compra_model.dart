import '../../domain/entities/orden_compra.dart';

class OrdenCompraDetalleModel extends OrdenCompraDetalle {
  const OrdenCompraDetalleModel({
    required super.id,
    required super.ordenCompraId,
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
    super.cantidadRecibida,
    required super.cantidadPendiente,
    super.orden,
    super.producto,
    super.variante,
  });

  factory OrdenCompraDetalleModel.fromJson(Map<String, dynamic> json) {
    return OrdenCompraDetalleModel(
      id: json['id'] as String,
      ordenCompraId: json['ordenCompraId'] as String? ?? '',
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
      cantidadRecibida: json['cantidadRecibida'] as int? ?? 0,
      cantidadPendiente: json['cantidadPendiente'] as int? ?? 0,
      orden: json['orden'] as int? ?? 0,
      producto: json['producto'] as Map<String, dynamic>?,
      variante: json['variante'] as Map<String, dynamic>?,
    );
  }
}

class OrdenCompraModel extends OrdenCompra {
  const OrdenCompraModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.proveedorId,
    required super.codigo,
    required super.nombreProveedor,
    super.documentoProveedor,
    super.emailProveedor,
    super.telefonoProveedor,
    super.direccionProveedor,
    super.terminosPago,
    super.diasCredito,
    super.moneda,
    super.tipoCambio,
    super.subtotal,
    super.descuento,
    super.impuestos,
    super.total,
    required super.fechaEmision,
    super.fechaEntregaEsperada,
    super.fechaAprobacion,
    super.estado,
    super.observaciones,
    super.condiciones,
    required super.creadoPor,
    super.aprobadoPor,
    required super.creadoEn,
    required super.actualizadoEn,
    super.detalles,
    super.sede,
    super.proveedor,
    super.compras,
    super.count,
  });

  factory OrdenCompraModel.fromJson(Map<String, dynamic> json) {
    return OrdenCompraModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      proveedorId: json['proveedorId'] as String,
      codigo: json['codigo'] as String,
      nombreProveedor: json['nombreProveedor'] as String,
      documentoProveedor: json['documentoProveedor'] as String?,
      emailProveedor: json['emailProveedor'] as String?,
      telefonoProveedor: json['telefonoProveedor'] as String?,
      direccionProveedor: json['direccionProveedor'] as String?,
      terminosPago: json['terminosPago'] as String?,
      diasCredito: json['diasCredito'] as int?,
      moneda: json['moneda'] as String? ?? 'PEN',
      tipoCambio: json['tipoCambio'] != null
          ? double.parse(json['tipoCambio'].toString())
          : null,
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      descuento: double.parse((json['descuento'] ?? 0).toString()),
      impuestos: double.parse((json['impuestos'] ?? 0).toString()),
      total: double.parse((json['total'] ?? 0).toString()),
      fechaEmision: DateTime.parse(json['fechaEmision'] as String),
      fechaEntregaEsperada: json['fechaEntregaEsperada'] != null
          ? DateTime.parse(json['fechaEntregaEsperada'] as String)
          : null,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      estado: _estadoFromString(json['estado'] as String),
      observaciones: json['observaciones'] as String?,
      condiciones: json['condiciones'] as String?,
      creadoPor: json['creadoPor'] as String,
      aprobadoPor: json['aprobadoPor'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((e) => OrdenCompraDetalleModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      sede: json['sede'] as Map<String, dynamic>?,
      proveedor: json['proveedor'] as Map<String, dynamic>?,
      compras: json['compras'] != null
          ? (json['compras'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
      count: json['_count'] as Map<String, dynamic>?,
    );
  }

  static EstadoOrdenCompra _estadoFromString(String estado) {
    switch (estado) {
      case 'BORRADOR': return EstadoOrdenCompra.BORRADOR;
      case 'PENDIENTE': return EstadoOrdenCompra.PENDIENTE;
      case 'APROBADA': return EstadoOrdenCompra.APROBADA;
      case 'PARCIAL': return EstadoOrdenCompra.PARCIAL;
      case 'COMPLETADA': return EstadoOrdenCompra.COMPLETADA;
      case 'CANCELADA': return EstadoOrdenCompra.CANCELADA;
      default: return EstadoOrdenCompra.BORRADOR;
    }
  }
}
