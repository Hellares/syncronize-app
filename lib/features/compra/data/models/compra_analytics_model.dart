import '../../domain/entities/compra_analytics.dart';

class CompraResumenGeneralModel extends CompraResumenGeneral {
  const CompraResumenGeneralModel({
    required super.totalCompras,
    required super.montoTotal,
    required super.promedioPorCompra,
    required super.comprasPendientes,
    required super.totalOrdenesCompra,
    required super.ocPendientes,
  });

  factory CompraResumenGeneralModel.fromJson(Map<String, dynamic> json) {
    return CompraResumenGeneralModel(
      totalCompras: json['totalCompras'] as int? ?? 0,
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0,
      promedioPorCompra: (json['promedioPorCompra'] as num?)?.toDouble() ?? 0,
      comprasPendientes: json['comprasPendientes'] as int? ?? 0,
      totalOrdenesCompra: json['totalOrdenesCompra'] as int? ?? 0,
      ocPendientes: json['ocPendientes'] as int? ?? 0,
    );
  }
}

class GastoPeriodoModel extends GastoPeriodo {
  const GastoPeriodoModel({
    required super.periodo,
    required super.total,
    required super.cantidad,
  });

  factory GastoPeriodoModel.fromJson(Map<String, dynamic> json) {
    return GastoPeriodoModel(
      periodo: json['periodo'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
    );
  }
}

class ProductoTopModel extends ProductoTop {
  const ProductoTopModel({
    required super.productoId,
    required super.nombre,
    required super.codigo,
    required super.cantidad,
    required super.costoTotal,
    required super.precioPromedio,
  });

  factory ProductoTopModel.fromJson(Map<String, dynamic> json) {
    return ProductoTopModel(
      productoId: json['productoId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      costoTotal: (json['costoTotal'] as num?)?.toDouble() ?? 0,
      precioPromedio: (json['precioPromedio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProveedorTopModel extends ProveedorTop {
  const ProveedorTopModel({
    required super.proveedorId,
    required super.nombre,
    required super.totalCompras,
    required super.montoTotal,
  });

  factory ProveedorTopModel.fromJson(Map<String, dynamic> json) {
    return ProveedorTopModel(
      proveedorId: json['proveedorId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      totalCompras: json['totalCompras'] as int? ?? 0,
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HistorialPrecioModel extends HistorialPrecio {
  const HistorialPrecioModel({
    required super.fecha,
    required super.precio,
    required super.tipo,
    super.proveedor,
  });

  factory HistorialPrecioModel.fromJson(Map<String, dynamic> json) {
    return HistorialPrecioModel(
      fecha: DateTime.parse(json['fecha'] as String),
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      tipo: json['tipo'] as String? ?? '',
      proveedor: json['proveedor'] as String?,
    );
  }
}

class PeriodoInfoModel extends PeriodoInfo {
  const PeriodoInfoModel({
    required super.inicio,
    required super.fin,
    required super.total,
    required super.cantidad,
  });

  factory PeriodoInfoModel.fromJson(Map<String, dynamic> json) {
    return PeriodoInfoModel(
      inicio: DateTime.parse(json['inicio'] as String),
      fin: DateTime.parse(json['fin'] as String),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      cantidad: json['cantidad'] as int? ?? 0,
    );
  }
}

class ComparativoCostoModel extends ComparativoCosto {
  const ComparativoCostoModel({
    required super.periodoActual,
    required super.periodoAnterior,
    required super.diferencia,
    required super.porcentajeCambio,
  });

  factory ComparativoCostoModel.fromJson(Map<String, dynamic> json) {
    return ComparativoCostoModel(
      periodoActual: PeriodoInfoModel.fromJson(
          json['periodoActual'] as Map<String, dynamic>),
      periodoAnterior: PeriodoInfoModel.fromJson(
          json['periodoAnterior'] as Map<String, dynamic>),
      diferencia: (json['diferencia'] as num?)?.toDouble() ?? 0,
      porcentajeCambio: (json['porcentajeCambio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AlertaCompraModel extends AlertaCompra {
  const AlertaCompraModel({
    required super.tipo,
    required super.mensaje,
    required super.datos,
  });

  factory AlertaCompraModel.fromJson(Map<String, dynamic> json) {
    return AlertaCompraModel(
      tipo: json['tipo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      datos: json['datos'] as Map<String, dynamic>? ?? {},
    );
  }
}
