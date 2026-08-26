class CompraResumenGeneral {
  final int totalCompras;
  final double montoTotal;
  final double promedioPorCompra;
  final int comprasPendientes;
  final int totalOrdenesCompra;
  final int ocPendientes;

  const CompraResumenGeneral({
    required this.totalCompras,
    required this.montoTotal,
    required this.promedioPorCompra,
    required this.comprasPendientes,
    required this.totalOrdenesCompra,
    required this.ocPendientes,
  });
}

class GastoPeriodo {
  final String periodo;
  final double total;
  final int cantidad;

  const GastoPeriodo({
    required this.periodo,
    required this.total,
    required this.cantidad,
  });
}

class ProductoTop {
  final String productoId;
  final String nombre;
  final String codigo;
  final int cantidad;
  final double costoTotal;
  final double precioPromedio;

  const ProductoTop({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.cantidad,
    required this.costoTotal,
    required this.precioPromedio,
  });
}

class ProveedorTop {
  final String proveedorId;
  final String nombre;
  final int totalCompras;
  final double montoTotal;

  const ProveedorTop({
    required this.proveedorId,
    required this.nombre,
    required this.totalCompras,
    required this.montoTotal,
  });
}

class HistorialPrecio {
  final DateTime fecha;
  final double precio;
  final String tipo;
  final String? proveedor;

  const HistorialPrecio({
    required this.fecha,
    required this.precio,
    required this.tipo,
    this.proveedor,
  });
}

class ComparativoCosto {
  final PeriodoInfo periodoActual;
  final PeriodoInfo periodoAnterior;
  final double diferencia;
  final double porcentajeCambio;

  const ComparativoCosto({
    required this.periodoActual,
    required this.periodoAnterior,
    required this.diferencia,
    required this.porcentajeCambio,
  });
}

class PeriodoInfo {
  final DateTime inicio;
  final DateTime fin;
  final double total;
  final int cantidad;

  const PeriodoInfo({
    required this.inicio,
    required this.fin,
    required this.total,
    required this.cantidad,
  });
}

class AlertaCompra {
  final String tipo;
  final String mensaje;
  final Map<String, dynamic> datos;

  const AlertaCompra({
    required this.tipo,
    required this.mensaje,
    required this.datos,
  });
}

/// Reporte de los GASTOS DE LA FACTURA del proveedor: flete, movilidad,
/// embalaje, intereses.
///
/// 🔴 No es lo mismo que [GastoPeriodo], que suma el total de las compras —o
/// sea cuánta plata se puso en mercadería—. Esto es cuánto costó TRAERLA.
class GastosFacturaReporte {
  final GastosFacturaResumen resumen;
  final List<GastoAgrupado> porCategoria;
  final List<GastoAgrupado> porPeriodo;
  final List<GastoAgrupado> porProveedor;

  const GastosFacturaReporte({
    required this.resumen,
    required this.porCategoria,
    required this.porPeriodo,
    required this.porProveedor,
  });

  bool get vacio => resumen.total <= 0;

  /// Cuánto hay sin clasificar. Mientras haya, el reporte por categoría no
  /// contesta del todo "cuánto va en movilidad".
  double get sinCategoria => porCategoria
      .where((c) => c.id == null)
      .fold(0.0, (sum, c) => sum + c.total);
}

class GastosFacturaResumen {
  final double total;

  /// Los que prorratean: entran al costo del inventario.
  final double alCosto;

  /// Los que no: interés por pago diferido, multas. Es costo financiero, no
  /// costo de la mercadería, y sumarlos juntos miente el margen.
  final double financiero;

  final int cantidadGastos;
  final int comprasConGasto;
  final double totalComprado;

  /// Cuánto pesó el flete sobre lo comprado. Es el número con el que se
  /// decide si vale la pena negociarlo con el proveedor.
  final double porcentajeSobreCompras;

  const GastosFacturaResumen({
    required this.total,
    required this.alCosto,
    required this.financiero,
    required this.cantidadGastos,
    required this.comprasConGasto,
    required this.totalComprado,
    required this.porcentajeSobreCompras,
  });
}

/// Una fila de cualquiera de los tres cortes. [id] es null para el balde de
/// "Sin categoría"/"Sin proveedor", y no aplica en el corte por período.
class GastoAgrupado {
  final String? id;
  final String nombre;
  final double total;
  final double alCosto;
  final double financiero;
  final int cantidad;
  final String? icono;
  final String? color;

  const GastoAgrupado({
    this.id,
    required this.nombre,
    required this.total,
    this.alCosto = 0,
    this.financiero = 0,
    this.cantidad = 0,
    this.icono,
    this.color,
  });
}
