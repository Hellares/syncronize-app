// Los valores del enum mapean directamente a los strings que devuelve
// el backend (`'BORRADOR'`, `'CONFIRMADA'`, `'ANULADA'`). Renombrarlos a
// lowerCamelCase rompería `byName(...)` y comparaciones con strings.
// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';

enum EstadoCompra {
  BORRADOR,
  CONFIRMADA,
  ANULADA,
}

/// Gasto de la factura del proveedor que NO es un producto: flete, movilidad,
/// embalaje, interés por pago diferido.
///
/// Siempre suma al total de la compra —si no, no cuadra con la factura ni con
/// la cuenta por pagar—. Sube el costo de los productos solo si [prorratea]:
/// un flete sí (es lo que cuesta poner la mercadería en el almacén), un
/// interés por pagar a 30 días no (es costo financiero).
class CompraGasto extends Equatable {
  final String id;
  final String concepto;

  /// Lo que cobra el proveedor, con IGV adentro si lo tiene.
  final double monto;
  final double porcentajeIGV;
  final double igv;
  final double base;
  final bool prorratea;

  /// VALOR (proporcional al total de cada línea) o CANTIDAD (por unidades).
  final String criterio;

  /// Categoría del catálogo de gastos, la misma de caja chica. Es lo que
  /// permite sumar "movilidad del año"; [concepto] es el detalle libre.
  ///
  /// 🔴 Se conserva al editar: guardar gastos REEMPLAZA la lista entera, así
  /// que un gasto que vuelva sin su categoría la pierde.
  final String? categoriaGastoId;
  final String? categoriaNombre;
  final String? categoriaIcono;
  final String? categoriaColor;

  final int orden;

  const CompraGasto({
    required this.id,
    required this.concepto,
    required this.monto,
    this.porcentajeIGV = 0,
    this.igv = 0,
    this.base = 0,
    this.prorratea = true,
    this.criterio = 'VALOR',
    this.categoriaGastoId,
    this.categoriaNombre,
    this.categoriaIcono,
    this.categoriaColor,
    this.orden = 0,
  });

  @override
  List<Object?> get props =>
      [id, concepto, monto, prorratea, criterio, categoriaGastoId];
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

  /// Parte del flete/movilidad que se le cargó a esta línea al confirmar.
  /// Es la diferencia entre lo que facturó el proveedor y lo que realmente
  /// costó traer el producto.
  final double gastoProrrateado;
  final Map<String, dynamic>? producto;
  final Map<String, dynamic>? variante;
  final Map<String, dynamic>? lote;
  final Map<String, dynamic>? ordenCompraDetalle;

  // Snapshot Unidad de Compra (Fase B). Si la línea fue cargada por
  // unidad de compra, estos campos guardan cuántas unidades originales,
  // qué símbolo y qué factor se aplicó. `cantidad` y `precioUnitario`
  // SIEMPRE son los convertidos a unidad atómica.
  final bool usaUnidadCompra;
  final double? cantidadOriginal;
  final String? unidadOriginalSimbolo;
  final double? factorAplicado;

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
    this.gastoProrrateado = 0,
    this.producto,
    this.variante,
    this.lote,
    this.ordenCompraDetalle,
    this.usaUnidadCompra = false,
    this.cantidadOriginal,
    this.unidadOriginalSimbolo,
    this.factorAplicado,
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

  /// Suma de los gastos (fletes, intereses). Ya está incluida en [total];
  /// se expone aparte para poder mostrarla como renglón propio.
  final double totalGastos;
  final DateTime fechaRecepcion;
  final EstadoCompra estado;
  final String? observaciones;
  final String creadoPor;
  final String? confirmadoPor;
  final DateTime creadoEn;
  final DateTime? confirmadoEn;
  final DateTime actualizadoEn;
  final List<CompraDetalle>? detalles;
  final List<CompraGasto>? gastos;
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
    this.totalGastos = 0,
    required this.fechaRecepcion,
    this.estado = EstadoCompra.BORRADOR,
    this.observaciones,
    required this.creadoPor,
    this.confirmadoPor,
    required this.creadoEn,
    this.confirmadoEn,
    required this.actualizadoEn,
    this.detalles,
    this.gastos,
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

  /// El comprobante del proveedor listo para mostrar: "FACTURA F001-000123".
  /// null cuando no se registró ninguno.
  ///
  /// Serie y número pueden faltar por separado —una boleta cargada a mano
  /// suele traer solo el número—, así que se arma con las partes que hay:
  /// concatenar a ciegas dejaba cosas como "FACTURA -000123".
  String? get documentoProveedorTexto {
    final tipo = tipoDocumentoProveedor?.trim();
    if (tipo == null || tipo.isEmpty) return null;
    final partes = [
      serieDocumentoProveedor?.trim() ?? '',
      numeroDocumentoProveedor?.trim() ?? '',
    ].where((p) => p.isNotEmpty);
    return partes.isEmpty ? tipo : '$tipo ${partes.join('-')}';
  }

  @override
  List<Object?> get props => [id, estado, actualizadoEn];
}
