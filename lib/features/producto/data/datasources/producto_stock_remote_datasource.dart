import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/producto_stock_model.dart';
import '../models/movimiento_stock_model.dart';
import '../../domain/entities/movimiento_stock.dart';

/// Data source remoto para operaciones de ProductoStock (inventario por sede)
@lazySingleton
class ProductoStockRemoteDataSource {
  final DioClient _dioClient;

  ProductoStockRemoteDataSource(this._dioClient);

  /// Crea stock inicial en una sede
  ///
  /// POST /api/producto-stock
  Future<ProductoStockModel> crearStock({
    required String empresaId,
    required String sedeId,
    String? productoId,
    String? varianteId,
    required int stockActual,
    int? stockMinimo,
    int? stockMaximo,
    String? ubicacion,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    bool? enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  }) async {
    final response = await _dioClient.post(
      '/producto-stock',
      data: {
        'sedeId': sedeId,
        if (productoId != null) 'productoId': productoId,
        if (varianteId != null) 'varianteId': varianteId,
        'stockActual': stockActual,
        if (stockMinimo != null) 'stockMinimo': stockMinimo,
        if (stockMaximo != null) 'stockMaximo': stockMaximo,
        if (ubicacion != null) 'ubicacion': ubicacion,
        if (precio != null) 'precio': precio,
        if (precioCosto != null) 'precioCosto': precioCosto,
        if (precioOferta != null) 'precioOferta': precioOferta,
        if (enOferta != null) 'enOferta': enOferta,
        if (fechaInicioOferta != null) 'fechaInicioOferta': fechaInicioOferta.toIso8601String(),
        if (fechaFinOferta != null) 'fechaFinOferta': fechaFinOferta.toIso8601String(),
      },
    );

    return ProductoStockModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lista el stock de una sede específica
  ///
  /// GET /api/producto-stock/sede/:sedeId
  Future<Map<String, dynamic>> getStockPorSede({
    required String sedeId,
    required String empresaId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/sede/$sedeId',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene el stock de un producto en una sede específica
  ///
  /// GET /api/producto-stock/producto/:productoId/sede/:sedeId
  Future<ProductoStockModel> getStockProductoEnSede({
    required String productoId,
    required String sedeId,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/producto/$productoId/sede/$sedeId',
    );

    return ProductoStockModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene el stock de una variante en una sede específica
  ///
  /// GET /api/producto-stock/variante/:varianteId/sede/:sedeId
  Future<ProductoStockModel> getStockVarianteEnSede({
    required String varianteId,
    required String sedeId,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/variante/$varianteId/sede/$sedeId',
    );

    return ProductoStockModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene el stock de un producto en TODAS las sedes
  ///
  /// GET /api/producto-stock/producto/:productoId/todas-sedes
  Future<StockTodasSedesModel> getStockTodasSedes({
    required String productoId,
    required String empresaId,
    String? varianteId,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/producto/$productoId/todas-sedes',
      queryParameters: {
        if (varianteId != null) 'varianteId': varianteId,
      },
    );

    return StockTodasSedesModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Ajusta el stock (entrada o salida)
  ///
  /// PUT /api/producto-stock/:id/ajustar
  Future<ProductoStockModel> ajustarStock({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    final response = await _dioClient.put(
      '/producto-stock/$stockId/ajustar',
      data: {
        'tipo': tipo.value,
        'cantidad': cantidad,
        if (motivo != null) 'motivo': motivo,
        if (observaciones != null) 'observaciones': observaciones,
        if (tipoDocumento != null) 'tipoDocumento': tipoDocumento,
        if (numeroDocumento != null) 'numeroDocumento': numeroDocumento,
      },
    );

    return ProductoStockModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza los precios de un ProductoStock
  ///
  /// PATCH /api/producto-stock/:id/precios
  Future<ProductoStockModel> actualizarPrecios({
    required String productoStockId,
    required String empresaId,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    required bool enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
  }) async {
    final response = await _dioClient.patch(
      '/producto-stock/$productoStockId/precios',
      data: {
        if (precio != null) 'precio': precio,
        if (precioCosto != null) 'precioCosto': precioCosto,
        if (precioOferta != null) 'precioOferta': precioOferta,
        'enOferta': enOferta,
        if (fechaInicioOferta != null)
          'fechaInicioOferta': fechaInicioOferta.toIso8601String(),
        if (fechaFinOferta != null)
          'fechaFinOferta': fechaFinOferta.toIso8601String(),
      },
    );

    return ProductoStockModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene el historial de movimientos de un stock
  ///
  /// GET /api/producto-stock/:id/movimientos
  Future<List<MovimientoStockModel>> getHistorialMovimientos({
    required String stockId,
    int limit = 50,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/$stockId/movimientos',
      queryParameters: {
        'limit': limit,
      },
    );

    final List movimientos = response.data as List;
    return movimientos
        .map((e) => MovimientoStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene alertas de productos con stock bajo el mínimo
  ///
  /// GET /api/producto-stock/alertas/bajo-minimo
  Future<Map<String, dynamic>> getAlertasStockBajo({
    required String empresaId,
    String? sedeId,
  }) async {
    final response = await _dioClient.get(
      '/producto-stock/alertas/bajo-minimo',
      queryParameters: {
        if (sedeId != null) 'sedeId': sedeId,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Valida si hay stock suficiente de un combo
  ///
  /// POST /api/producto-stock/combo/validar-stock
  Future<Map<String, dynamic>> validarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
  }) async {
    final response = await _dioClient.post(
      '/producto-stock/combo/validar-stock',
      data: {
        'comboId': comboId,
        'sedeId': sedeId,
        'cantidad': cantidad,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Descuenta el stock de un combo al vender
  ///
  /// POST /api/producto-stock/combo/descontar-stock
  Future<void> descontarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    await _dioClient.post(
      '/producto-stock/combo/descontar-stock',
      data: {
        'comboId': comboId,
        'sedeId': sedeId,
        'cantidad': cantidad,
        if (tipoDocumento != null) 'tipoDocumento': tipoDocumento,
        if (numeroDocumento != null) 'numeroDocumento': numeroDocumento,
      },
    );
  }

  /// Ajuste masivo de precios por sede
  ///
  /// POST /api/producto-stock/sedes/:sedeId/precios/ajuste-masivo
  Future<Map<String, dynamic>> ajusteMasivoPreciosPorSede({
    required String sedeId,
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    final response = await _dioClient.post(
      '/producto-stock/sedes/$sedeId/precios/ajuste-masivo',
      data: dto,
    );

    return response.data as Map<String, dynamic>;
  }
}
