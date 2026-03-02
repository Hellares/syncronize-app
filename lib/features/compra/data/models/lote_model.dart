import '../../domain/entities/lote.dart';

class LoteModel extends Lote {
  const LoteModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.productoStockId,
    super.productoId,
    super.varianteId,
    super.compraId,
    required super.codigo,
    super.numeroLote,
    required super.precioCosto,
    super.moneda,
    required super.cantidadInicial,
    required super.cantidadActual,
    super.cantidadReservada,
    required super.fechaIngreso,
    super.fechaProduccion,
    super.fechaVencimiento,
    super.estado,
    super.proveedorId,
    super.nombreProveedor,
    super.observaciones,
    required super.creadoPor,
    required super.creadoEn,
    required super.actualizadoEn,
    super.productoStock,
    super.sede,
    super.proveedor,
    super.compra,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      productoStockId: json['productoStockId'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      compraId: json['compraId'] as String?,
      codigo: json['codigo'] as String,
      numeroLote: json['numeroLote'] as String?,
      precioCosto: double.parse(json['precioCosto'].toString()),
      moneda: json['moneda'] as String? ?? 'PEN',
      cantidadInicial: json['cantidadInicial'] as int,
      cantidadActual: json['cantidadActual'] as int,
      cantidadReservada: json['cantidadReservada'] as int? ?? 0,
      fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      fechaProduccion: json['fechaProduccion'] != null
          ? DateTime.parse(json['fechaProduccion'] as String)
          : null,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'] as String)
          : null,
      estado: _estadoFromString(json['estado'] as String),
      proveedorId: json['proveedorId'] as String?,
      nombreProveedor: json['nombreProveedor'] as String?,
      observaciones: json['observaciones'] as String?,
      creadoPor: json['creadoPor'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      productoStock: json['productoStock'] as Map<String, dynamic>?,
      sede: json['sede'] as Map<String, dynamic>?,
      proveedor: json['proveedor'] as Map<String, dynamic>?,
      compra: json['compra'] as Map<String, dynamic>?,
    );
  }

  static EstadoLote _estadoFromString(String estado) {
    switch (estado) {
      case 'ACTIVO': return EstadoLote.ACTIVO;
      case 'AGOTADO': return EstadoLote.AGOTADO;
      case 'VENCIDO': return EstadoLote.VENCIDO;
      case 'BLOQUEADO': return EstadoLote.BLOQUEADO;
      default: return EstadoLote.ACTIVO;
    }
  }
}
