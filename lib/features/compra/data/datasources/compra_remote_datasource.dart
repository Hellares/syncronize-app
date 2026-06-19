import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/orden_compra_model.dart';
import '../models/compra_model.dart';
import '../models/lote_model.dart';
import '../models/compra_analytics_model.dart';
import '../models/historial_compras_model.dart';
import '../models/reposicion_model.dart';
import '../models/guia_remision_consulta_model.dart';

@lazySingleton
class CompraRemoteDataSource {
  final DioClient _dioClient;

  CompraRemoteDataSource(this._dioClient);

  /// Historial de compras de un producto (para mostrar al comprar): últimas
  /// compras + agregado por proveedor + último costo + mejor proveedor.
  Future<HistorialComprasResult> getHistorialComprasProducto({
    required String productoId,
    String? varianteId,
    int limit = 10,
  }) async {
    final resp = await _dioClient.get(
      '/productos/$productoId/historial-compras',
      queryParameters: {
        if (varianteId != null) 'varianteId': varianteId,
        'limit': limit.toString(),
      },
    );
    return HistorialComprasResult.fromJson(resp.data as Map<String, dynamic>);
  }

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

  /// Consulta una Guía de Remisión (GRE) en SUNAT vía el backend (proxy a
  /// Factiliza con token server-side). `numero` = RUC-tipo-serie-número.
  Future<GuiaRemisionConsulta> consultarGuiaRemision(String numero) async {
    final response = await _dioClient.get('/consultas/guia/$numero');
    return GuiaRemisionConsulta.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sugiere el mapeo de bienes de una guía → catálogo (alias proveedor + similitud).
  /// `bienes`: [{descripcion, cantidad?, unidad?}]. Devuelve cada uno enriquecido
  /// con productoId/productoNombre/factorCompra/unidadCompraSimbolo/fuente.
  Future<List<Map<String, dynamic>>> sugerirMapeoGuia({
    required String empresaId,
    required String proveedorId,
    required List<Map<String, dynamic>> bienes,
  }) async {
    final r = await _dioClient.post(
      '/empresas/$empresaId/compras/guia/sugerir-mapeo',
      data: {'proveedorId': proveedorId, 'bienes': bienes},
    );
    final list = r.data as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Guarda el alias del proveedor para tus productos (recordar nombres).
  /// `items`: [{descripcionProveedor, productoId, varianteId?, precioCompra?}].
  Future<void> guardarAliasProveedor({
    required String empresaId,
    required String proveedorId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _dioClient.post(
      '/empresas/$empresaId/compras/proveedor-alias',
      data: {'proveedorId': proveedorId, 'items': items},
    );
  }

  /// Reposición sugerida: productos con stock ≤ mínimo + mejor proveedor.
  Future<List<ReposicionItem>> getReposicionSugerida({
    required String empresaId,
    String? sedeId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compras/reposicion-sugerida',
      queryParameters: {if (sedeId != null) 'sedeId': sedeId},
    );
    final data = response.data as List? ?? [];
    return data
        .map((e) => ReposicionItem.fromJson(e as Map<String, dynamic>))
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

  // ===== ANALYTICS =====

  Future<CompraResumenGeneralModel> getAnalyticsResumen({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/resumen',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (fechaInicio != null) 'fechaInicio': fechaInicio,
        if (fechaFin != null) 'fechaFin': fechaFin,
      },
    );
    return CompraResumenGeneralModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<GastoPeriodoModel>> getAnalyticsGastosPeriodo({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/gastos-periodo',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (fechaInicio != null) 'fechaInicio': fechaInicio,
        if (fechaFin != null) 'fechaFin': fechaFin,
        if (periodo != null) 'periodo': periodo,
      },
    );
    final data = response.data as List;
    return data
        .map((json) =>
            GastoPeriodoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductoTopModel>> getAnalyticsTopProductos({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/top-productos',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (fechaInicio != null) 'fechaInicio': fechaInicio,
        if (fechaFin != null) 'fechaFin': fechaFin,
      },
    );
    final data = response.data as List;
    return data
        .map((json) =>
            ProductoTopModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProveedorTopModel>> getAnalyticsTopProveedores({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/top-proveedores',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (fechaInicio != null) 'fechaInicio': fechaInicio,
        if (fechaFin != null) 'fechaFin': fechaFin,
      },
    );
    final data = response.data as List;
    return data
        .map((json) =>
            ProveedorTopModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<HistorialPrecioModel>> getAnalyticsHistorialPrecios({
    required String empresaId,
    required String productoId,
    String? sedeId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/historial-precios/$productoId',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
      },
    );
    final data = response.data as List;
    return data
        .map((json) =>
            HistorialPrecioModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ComparativoCostoModel> getAnalyticsComparativoCostos({
    required String empresaId,
    String? sedeId,
    String? periodo,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/comparativo-costos',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
        if (periodo != null) 'periodo': periodo,
      },
    );
    return ComparativoCostoModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<AlertaCompraModel>> getAnalyticsAlertas({
    required String empresaId,
    String? sedeId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/alertas',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
      },
    );
    final data = response.data as List;
    return data
        .map((json) =>
            AlertaCompraModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===== EXPORT EXCEL =====

  Future<List<int>> exportComprasPorProducto({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/export/productos',
      queryParameters: {
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        if (sedeId != null) 'sedeId': sedeId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return response.data as List<int>;
  }

  Future<List<int>> exportComprasPorProveedor({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/compra/analytics/export/proveedores',
      queryParameters: {
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        if (sedeId != null) 'sedeId': sedeId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
      onReceiveProgress: onReceiveProgress,
    );
    return response.data as List<int>;
  }
}
