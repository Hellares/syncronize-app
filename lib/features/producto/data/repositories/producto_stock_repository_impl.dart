import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/cursor_page.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/entities/precio_historial_sede.dart';
import '../../domain/repositories/producto_stock_repository.dart';
import '../datasources/producto_stock_remote_datasource.dart';
import '../models/movimiento_stock_model.dart';
import '../models/precio_historial_sede_model.dart';

@LazySingleton(as: ProductoStockRepository)
class ProductoStockRepositoryImpl implements ProductoStockRepository {
  final ProductoStockRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ProductoStockRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ProductoStock>> crearStock({
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
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.crearStock(
        empresaId: empresaId,
        sedeId: sedeId,
        productoId: productoId,
        varianteId: varianteId,
        stockActual: stockActual,
        stockMinimo: stockMinimo,
        stockMaximo: stockMaximo,
        ubicacion: ubicacion,
        precio: precio,
        precioCosto: precioCosto,
        precioOferta: precioOferta,
        enOferta: enOferta,
        fechaInicioOferta: fechaInicioOferta,
        fechaFinOferta: fechaFinOferta,
      );
      return Success(stock);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> getStockPorSede({
    required String sedeId,
    required String empresaId,
    int page = 1,
    int limit = 50,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.getStockPorSede(
        sedeId: sedeId,
        empresaId: empresaId,
        page: page,
        limit: limit,
      );
      return Success(resultado);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<ProductoStock>> getStockProductoEnSede({
    required String productoId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.getStockProductoEnSede(
        productoId: productoId,
        sedeId: sedeId,
      );
      return Success(stock);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<ProductoStock>> getStockVarianteEnSede({
    required String varianteId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.getStockVarianteEnSede(
        varianteId: varianteId,
        sedeId: sedeId,
      );
      return Success(stock);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> getStockTodasSedes({
    required String productoId,
    required String empresaId,
    String? varianteId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.getStockTodasSedes(
        productoId: productoId,
        empresaId: empresaId,
        varianteId: varianteId,
      );
      // Convertir el modelo a un Map para mantener la flexibilidad
      return Success(stock.toJson());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<ProductoStock>> ajustarStock({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.ajustarStock(
        stockId: stockId,
        empresaId: empresaId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        observaciones: observaciones,
        tipoDocumento: tipoDocumento,
        numeroDocumento: numeroDocumento,
      );
      return Success(stock);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<ProductoStock>> actualizarPrecios({
    required String productoStockId,
    required String empresaId,
    double? precio,
    double? precioCosto,
    double? precioOferta,
    required bool enOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    bool precioIncluyeIgv = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stock = await _remoteDataSource.actualizarPrecios(
        productoStockId: productoStockId,
        empresaId: empresaId,
        precio: precio,
        precioCosto: precioCosto,
        precioOferta: precioOferta,
        enOferta: enOferta,
        fechaInicioOferta: fechaInicioOferta,
        fechaFinOferta: fechaFinOferta,
        precioIncluyeIgv: precioIncluyeIgv,
      );
      return Success(stock);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<KardexData>> getHistorialMovimientos({
    required String stockId,
    int limit = 100,
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final response = await _remoteDataSource.getHistorialMovimientos(
        stockId: stockId,
        limit: limit,
        tipo: tipo,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      // Parsear movimientos
      final rawMovimientos = response['movimientos'] as List? ?? [];
      final movimientos = rawMovimientos
          .map((e) => MovimientoStockModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parsear resumen
      final rawResumen = response['resumen'] as List? ?? [];
      final resumen = rawResumen
          .map((e) => KardexResumenItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(KardexData(movimientos: movimientos, resumen: resumen));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> getAlertasStockBajo({
    required String empresaId,
    String? sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final alertas = await _remoteDataSource.getAlertasStockBajo(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(alertas);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> validarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.validarStockCombo(
        empresaId: empresaId,
        comboId: comboId,
        sedeId: sedeId,
        cantidad: cantidad,
      );
      return Success(resultado);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<void>> descontarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
    String? tipoDocumento,
    String? numeroDocumento,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.descontarStockCombo(
        empresaId: empresaId,
        comboId: comboId,
        sedeId: sedeId,
        cantidad: cantidad,
        tipoDocumento: tipoDocumento,
        numeroDocumento: numeroDocumento,
      );
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> ajusteMasivoPreciosPorSede({
    required String sedeId,
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.ajusteMasivoPreciosPorSede(
        sedeId: sedeId,
        empresaId: empresaId,
        dto: dto,
      );
      return Success(resultado);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  // ===== HISTORIAL DE PRECIOS GLOBAL =====

  @override
  Future<Resource<CursorPage<PrecioHistorialSede>>> getHistorialPreciosGlobal({
    required String empresaId,
    String? sedeId,
    String? productoId,
    String? fechaInicio,
    String? fechaFin,
    String? tipoCambio,
    String? search,
    String? cursor,
    int limit = 50,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final response = await _remoteDataSource.getHistorialPreciosGlobal(
        empresaId: empresaId,
        sedeId: sedeId,
        productoId: productoId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        tipoCambio: tipoCambio,
        search: search,
        cursor: cursor,
        limit: limit,
      );
      final dataList = response['data'] as List? ?? [];
      final meta = response['meta'] as Map<String, dynamic>? ?? {};
      final items = dataList
          .map((json) => PrecioHistorialSedeModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(CursorPage(
        items: items,
        hasNext: meta['hasNext'] as bool? ?? false,
        nextCursor: meta['nextCursor'] as String?,
      ));
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }

  @override
  Future<Resource<List<int>>> exportHistorialPrecios({
    required String empresaId,
    required String fechaInicio,
    required String fechaFin,
    String? sedeId,
    String? productoId,
    String? tipoCambio,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final bytes = await _remoteDataSource.exportHistorialPrecios(
        empresaId: empresaId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sedeId: sedeId,
        productoId: productoId,
        tipoCambio: tipoCambio,
        onReceiveProgress: onReceiveProgress,
      );
      return Success(bytes);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ProductoStock');
    }
  }
}
