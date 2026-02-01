import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/repositories/producto_stock_repository.dart';
import '../datasources/producto_stock_remote_datasource.dart';

@LazySingleton(as: ProductoStockRepository)
class ProductoStockRepositoryImpl implements ProductoStockRepository {
  final ProductoStockRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ProductoStockRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      );
      return Success(stock);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<MovimientoStock>>> getHistorialMovimientos({
    required String stockId,
    int limit = 50,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final movimientos = await _remoteDataSource.getHistorialMovimientos(
        stockId: stockId,
        limit: limit,
      );
      return Success(movimientos);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<MovimientoStock>>> descontarStockCombo({
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
      final movimientos = await _remoteDataSource.descontarStockCombo(
        empresaId: empresaId,
        comboId: comboId,
        sedeId: sedeId,
        cantidad: cantidad,
        tipoDocumento: tipoDocumento,
        numeroDocumento: numeroDocumento,
      );
      return Success(movimientos);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
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
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }
}
