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
