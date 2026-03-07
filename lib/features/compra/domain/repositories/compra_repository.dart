import '../../../../core/utils/resource.dart';
import '../entities/orden_compra.dart';
import '../entities/compra.dart';
import '../entities/lote.dart';
import '../entities/compra_analytics.dart';

abstract class CompraRepository {
  // ===== ORDENES DE COMPRA =====
  Future<Resource<List<OrdenCompra>>> getOrdenesCompra({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? search,
  });

  Future<Resource<OrdenCompra>> getOrdenCompra({
    required String empresaId,
    required String id,
  });

  Future<Resource<OrdenCompra>> crearOrdenCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  Future<Resource<OrdenCompra>> actualizarOrdenCompra({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  });

  Future<Resource<OrdenCompra>> cambiarEstadoOrdenCompra({
    required String empresaId,
    required String id,
    required String estado,
  });

  Future<Resource<void>> eliminarOrdenCompra({
    required String empresaId,
    required String id,
  });

  Future<Resource<List<OrdenCompraDetalle>>> getLineasPendientes({
    required String empresaId,
    required String id,
  });

  Future<Resource<OrdenCompra>> duplicarOrdenCompra({
    required String empresaId,
    required String id,
  });

  // ===== COMPRAS =====
  Future<Resource<List<Compra>>> getCompras({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? ordenCompraId,
    String? search,
  });

  Future<Resource<Compra>> getCompra({
    required String empresaId,
    required String id,
  });

  Future<Resource<Compra>> crearCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  Future<Resource<Compra>> crearCompraDesdeOc({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  Future<Resource<Compra>> confirmarCompra({
    required String empresaId,
    required String id,
  });

  Future<Resource<Compra>> anularCompra({
    required String empresaId,
    required String id,
  });

  Future<Resource<void>> eliminarCompra({
    required String empresaId,
    required String id,
  });

  // ===== LOTES =====
  Future<Resource<List<Lote>>> getLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
  });

  Future<Resource<Lote>> getLote({
    required String empresaId,
    required String id,
  });

  Future<Resource<List<Lote>>> getLotesPorProductoStock({
    required String empresaId,
    required String productoStockId,
  });

  Future<Resource<List<Lote>>> getLotesProximosVencer({
    required String empresaId,
    int dias,
  });

  Future<Resource<Map<String, dynamic>>> getResumenCosto({
    required String empresaId,
    required String productoStockId,
  });

  Future<Resource<Map<String, dynamic>>> marcarLotesVencidos({
    required String empresaId,
  });

  // ===== ANALYTICS =====
  Future<Resource<CompraResumenGeneral>> getAnalyticsResumen({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  });

  Future<Resource<List<GastoPeriodo>>> getAnalyticsGastosPeriodo({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  });

  Future<Resource<List<ProductoTop>>> getAnalyticsTopProductos({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  });

  Future<Resource<List<ProveedorTop>>> getAnalyticsTopProveedores({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  });

  Future<Resource<List<HistorialPrecio>>> getAnalyticsHistorialPrecios({
    required String empresaId,
    required String productoId,
    String? sedeId,
  });

  Future<Resource<ComparativoCosto>> getAnalyticsComparativoCostos({
    required String empresaId,
    String? sedeId,
    String? periodo,
  });

  Future<Resource<List<AlertaCompra>>> getAnalyticsAlertas({
    required String empresaId,
    String? sedeId,
  });

  // ===== EXPORT EXCEL =====
  Future<Resource<List<int>>> exportComprasPorProducto({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  });

  Future<Resource<List<int>>> exportComprasPorProveedor({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  });
}
