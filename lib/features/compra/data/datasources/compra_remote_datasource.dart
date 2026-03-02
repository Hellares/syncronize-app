import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/orden_compra_model.dart';
import '../models/compra_model.dart';
import '../models/lote_model.dart';

@lazySingleton
class CompraRemoteDataSource {
  final DioClient _dioClient;

  CompraRemoteDataSource(this._dioClient);

  // ===== ORDENES DE COMPRA =====

  Future<List<OrdenCompraModel>> getOrdenesCompra({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? search,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/ordenes-compra',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (proveedorId != null) 'proveedorId': proveedorId,
        if (estado != null) 'estado': estado,
        if (search != null) 'search': search,
      },
    );
    final data = response.data['data'] as List;
    return data
        .map((json) => OrdenCompraModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrdenCompraModel> getOrdenCompra({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/ordenes-compra/$id',
    );
    return OrdenCompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenCompraModel> crearOrdenCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/ordenes-compra',
      data: data,
    );
    return OrdenCompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenCompraModel> actualizarOrdenCompra({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '/empresas/$empresaId/ordenes-compra/$id',
      data: data,
    );
    return OrdenCompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrdenCompraModel> cambiarEstadoOrdenCompra({
    required String empresaId,
    required String id,
    required String estado,
  }) async {
    final response = await _dioClient.patch(
      '/empresas/$empresaId/ordenes-compra/$id/estado',
      data: {'estado': estado},
    );
    return OrdenCompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminarOrdenCompra({
    required String empresaId,
    required String id,
  }) async {
    await _dioClient.delete('/empresas/$empresaId/ordenes-compra/$id');
  }

  Future<List<OrdenCompraDetalleModel>> getLineasPendientes({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/ordenes-compra/$id/lineas-pendientes',
    );
    final data = response.data as List;
    return data
        .map((json) =>
            OrdenCompraDetalleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrdenCompraModel> duplicarOrdenCompra({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/ordenes-compra/$id/duplicar',
    );
    return OrdenCompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ===== COMPRAS =====

  Future<List<CompraModel>> getCompras({
    required String empresaId,
    String? sedeId,
    String? proveedorId,
    String? estado,
    String? ordenCompraId,
    String? search,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compras',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (proveedorId != null) 'proveedorId': proveedorId,
        if (estado != null) 'estado': estado,
        if (ordenCompraId != null) 'ordenCompraId': ordenCompraId,
        if (search != null) 'search': search,
      },
    );
    final data = response.data['data'] as List;
    return data
        .map((json) => CompraModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CompraModel> getCompra({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compras/$id',
    );
    return CompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CompraModel> crearCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/compras',
      data: data,
    );
    return CompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CompraModel> crearCompraDesdeOc({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/compras/desde-orden-compra',
      data: data,
    );
    return CompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CompraModel> confirmarCompra({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/compras/$id/confirmar',
    );
    return CompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CompraModel> anularCompra({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/compras/$id/anular',
    );
    return CompraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminarCompra({
    required String empresaId,
    required String id,
  }) async {
    await _dioClient.delete('/empresas/$empresaId/compras/$id');
  }

  // ===== LOTES =====

  Future<List<LoteModel>> getLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/lotes',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (productoStockId != null) 'productoStockId': productoStockId,
        if (estado != null) 'estado': estado,
        if (search != null) 'search': search,
      },
    );
    final data = response.data['data'] as List;
    return data
        .map((json) => LoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<LoteModel> getLote({
    required String empresaId,
    required String id,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/lotes/$id',
    );
    return LoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<LoteModel>> getLotesPorProductoStock({
    required String empresaId,
    required String productoStockId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/lotes/producto-stock/$productoStockId',
    );
    final data = response.data as List;
    return data
        .map((json) => LoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<LoteModel>> getLotesProximosVencer({
    required String empresaId,
    int dias = 30,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/lotes/proximos-vencer',
      queryParameters: {'dias': dias.toString()},
    );
    final data = response.data as List;
    return data
        .map((json) => LoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getResumenCosto({
    required String empresaId,
    required String productoStockId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/lotes/resumen-costo/$productoStockId',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> marcarLotesVencidos({
    required String empresaId,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/lotes/marcar-vencidos',
    );
    return response.data as Map<String, dynamic>;
  }
}
