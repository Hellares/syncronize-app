import 'venta.dart';

/// Agregado por estado sobre TODO el set filtrado (no solo lo cargado):
/// alimenta el chip del total y los conteos de anuladas/borradores.
class VentasResumenEstado {
  final String estado;
  final int cantidad;
  final double total;

  const VentasResumenEstado({
    required this.estado,
    required this.cantidad,
    required this.total,
  });
}

/// Página de ventas (paginación por cursor) + resumen agregado.
class VentasPage {
  final List<Venta> ventas;
  final bool hasMore;
  final String? nextCursor;
  final List<VentasResumenEstado> resumen;

  const VentasPage({
    required this.ventas,
    required this.hasMore,
    this.nextCursor,
    this.resumen = const [],
  });
}
