import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/orden_compra.dart';
import '../../domain/entities/compra.dart';
import '../../domain/entities/lote.dart';
import '../../domain/entities/compra_analytics.dart';
import '../../domain/repositories/compra_repository.dart';
import '../datasources/compra_remote_datasource.dart';

@LazySingleton(as: CompraRepository)
class CompraRepositoryImpl implements CompraRepository {
  final CompraRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  CompraRepositoryImpl(this._remoteDataSource, this._networkInfo);

  Future<Resource<T>> _execute<T>(Future<T> Function() call) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await call();
      return Success(result);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  // ===== ORDENES DE COMPRA =====

  @override
  Future<Resource<List<OrdenCompra>>> getOrdenesCompra({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? search,
  }) => _execute(() => _remoteDataSource.getOrdenesCompra(
        empresaId: empresaId,
        sedeId: sedeId,
        proveedorId: proveedorId,
        estado: estado,
        search: search,
      ));

  @override
  Future<Resource<OrdenCompra>> getOrdenCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.getOrdenCompra(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<OrdenCompra>> crearOrdenCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) => _execute(() => _remoteDataSource.crearOrdenCompra(
        empresaId: empresaId, data: data));

  @override
  Future<Resource<OrdenCompra>> actualizarOrdenCompra({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  }) => _execute(() => _remoteDataSource.actualizarOrdenCompra(
        empresaId: empresaId, id: id, data: data));

  @override
  Future<Resource<OrdenCompra>> cambiarEstadoOrdenCompra({
    required String empresaId,
    required String id,
    required String estado,
  }) => _execute(() => _remoteDataSource.cambiarEstadoOrdenCompra(
        empresaId: empresaId, id: id, estado: estado));

  @override
  Future<Resource<void>> eliminarOrdenCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.eliminarOrdenCompra(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<List<OrdenCompraDetalle>>> getLineasPendientes({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.getLineasPendientes(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<OrdenCompra>> duplicarOrdenCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.duplicarOrdenCompra(
        empresaId: empresaId, id: id));

  // ===== COMPRAS =====

  @override
  Future<Resource<List<Compra>>> getCompras({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? ordenCompraId,
    String? search,
  }) => _execute(() => _remoteDataSource.getCompras(
        empresaId: empresaId,
        sedeId: sedeId,
        proveedorId: proveedorId,
        estado: estado,
        ordenCompraId: ordenCompraId,
        search: search,
      ));

  @override
  Future<Resource<Compra>> getCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.getCompra(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<Compra>> crearCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) => _execute(() => _remoteDataSource.crearCompra(
        empresaId: empresaId, data: data));

  @override
  Future<Resource<Compra>> crearCompraDesdeOc({
    required String empresaId,
    required Map<String, dynamic> data,
  }) => _execute(() => _remoteDataSource.crearCompraDesdeOc(
        empresaId: empresaId, data: data));

  @override
  Future<Resource<Compra>> confirmarCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.confirmarCompra(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<Compra>> anularCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.anularCompra(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<void>> eliminarCompra({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.eliminarCompra(
        empresaId: empresaId, id: id));

  // ===== LOTES =====

  @override
  Future<Resource<List<Lote>>> getLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
  }) => _execute(() => _remoteDataSource.getLotes(
        empresaId: empresaId,
        sedeId: sedeId,
        productoStockId: productoStockId,
        estado: estado,
        search: search,
      ));

  @override
  Future<Resource<Lote>> getLote({
    required String empresaId,
    required String id,
  }) => _execute(() => _remoteDataSource.getLote(
        empresaId: empresaId, id: id));

  @override
  Future<Resource<List<Lote>>> getLotesPorProductoStock({
    required String empresaId,
    required String productoStockId,
  }) => _execute(() => _remoteDataSource.getLotesPorProductoStock(
        empresaId: empresaId, productoStockId: productoStockId));

  @override
  Future<Resource<List<Lote>>> getLotesProximosVencer({
    required String empresaId,
    int dias = 30,
  }) => _execute(() => _remoteDataSource.getLotesProximosVencer(
        empresaId: empresaId, dias: dias));

  @override
  Future<Resource<Map<String, dynamic>>> getResumenCosto({
    required String empresaId,
    required String productoStockId,
  }) => _execute(() => _remoteDataSource.getResumenCosto(
        empresaId: empresaId, productoStockId: productoStockId));

  @override
  Future<Resource<Map<String, dynamic>>> marcarLotesVencidos({
    required String empresaId,
  }) => _execute(() => _remoteDataSource.marcarLotesVencidos(
        empresaId: empresaId));

  // ===== ANALYTICS =====

  @override
  Future<Resource<CompraResumenGeneral>> getAnalyticsResumen({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) => _execute(() => _remoteDataSource.getAnalyticsResumen(
        empresaId: empresaId,
        sedeId: sedeId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ));

  @override
  Future<Resource<List<GastoPeriodo>>> getAnalyticsGastosPeriodo({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  }) => _execute(() => _remoteDataSource.getAnalyticsGastosPeriodo(
        empresaId: empresaId,
        sedeId: sedeId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        periodo: periodo,
      ));

  @override
  Future<Resource<List<ProductoTop>>> getAnalyticsTopProductos({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) => _execute(() => _remoteDataSource.getAnalyticsTopProductos(
        empresaId: empresaId,
        sedeId: sedeId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ));

  @override
  Future<Resource<List<ProveedorTop>>> getAnalyticsTopProveedores({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) => _execute(() => _remoteDataSource.getAnalyticsTopProveedores(
        empresaId: empresaId,
        sedeId: sedeId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ));

  @override
  Future<Resource<List<HistorialPrecio>>> getAnalyticsHistorialPrecios({
    required String empresaId,
    required String productoId,
    String? sedeId,
  }) => _execute(() => _remoteDataSource.getAnalyticsHistorialPrecios(
        empresaId: empresaId,
        productoId: productoId,
        sedeId: sedeId,
      ));

  @override
  Future<Resource<ComparativoCosto>> getAnalyticsComparativoCostos({
    required String empresaId,
    String? sedeId,
    String? periodo,
  }) => _execute(() => _remoteDataSource.getAnalyticsComparativoCostos(
        empresaId: empresaId,
        sedeId: sedeId,
        periodo: periodo,
      ));

  @override
  Future<Resource<List<AlertaCompra>>> getAnalyticsAlertas({
    required String empresaId,
    String? sedeId,
  }) => _execute(() => _remoteDataSource.getAnalyticsAlertas(
        empresaId: empresaId,
        sedeId: sedeId,
      ));

  // ===== EXPORT EXCEL =====

  @override
  Future<Resource<List<int>>> exportComprasPorProducto({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) => _execute(() => _remoteDataSource.exportComprasPorProducto(
        empresaId: empresaId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sedeId: sedeId,
        onReceiveProgress: onReceiveProgress,
      ));

  @override
  Future<Resource<List<int>>> exportComprasPorProveedor({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) => _execute(() => _remoteDataSource.exportComprasPorProveedor(
        empresaId: empresaId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sedeId: sedeId,
        onReceiveProgress: onReceiveProgress,
      ));
}
