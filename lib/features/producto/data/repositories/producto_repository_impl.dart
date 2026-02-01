import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/producto.dart';
import '../../domain/entities/producto_filtros.dart';
import '../../domain/repositories/producto_repository.dart';
import '../datasources/producto_remote_datasource.dart';
import '../models/producto_list_item_model.dart';
import '../models/producto_model.dart';

@LazySingleton(as: ProductoRepository)
class ProductoRepositoryImpl implements ProductoRepository {
  final ProductoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ProductoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<Producto>> crearProducto({
    required String empresaId,
    List<String>? sedesIds,
    String? unidadMedidaId,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sku,
    String? codigoBarras,
    required String nombre,
    String? descripcion,
    // ❌ DEPRECADO: precio, precioCosto, stock, stockMinimo ahora se manejan en ProductoStock
    double? precio,
    double? precioCosto,
    int? stock,
    int? stockMinimo,
    double? peso,
    Map<String, dynamic>? dimensiones,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? descuentoMaximo,
    bool? visibleMarketplace,
    bool? destacado,
    bool? enOferta,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    double? precioOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        'empresaId': empresaId,
        if (sedesIds != null && sedesIds.isNotEmpty) 'sedesIds': sedesIds,
        if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
        if (empresaCategoriaId != null)
          'empresaCategoriaId': empresaCategoriaId,
        if (empresaMarcaId != null) 'empresaMarcaId': empresaMarcaId,
        if (sku != null) 'sku': sku,
        if (codigoBarras != null) 'codigoBarras': codigoBarras,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        // ❌ DEPRECADO: precio, precioCosto, stock, stockMinimo, enOferta, precioOferta
        // Ahora se gestionan en ProductoStock por sede
        // Usar POST /producto-stock después de crear el producto
        // 'precio': precio,
        // if (precioCosto != null) 'precioCosto': precioCosto,
        // if (stock != null) 'stock': stock,
        // if (stockMinimo != null) 'stockMinimo': stockMinimo,
        if (peso != null) 'peso': peso,
        if (dimensiones != null) 'dimensiones': dimensiones,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (impuestoPorcentaje != null)
          'impuestoPorcentaje': impuestoPorcentaje,
        if (descuentoMaximo != null) 'descuentoMaximo': descuentoMaximo,
        if (visibleMarketplace != null)
          'visibleMarketplace': visibleMarketplace,
        if (destacado != null) 'destacado': destacado,
        // ❌ DEPRECADO: enOferta, precioOferta, fechas
        // Ahora se gestionan en ProductoStock por sede
        // if (enOferta != null) 'enOferta': enOferta,
        // if (precioOferta != null) 'precioOferta': precioOferta,
        // if (fechaInicioOferta != null)
        //   'fechaInicioOferta': fechaInicioOferta.toIso8601String(),
        // if (fechaFinOferta != null)
        //   'fechaFinOferta': fechaFinOferta.toIso8601String(),
        if (tieneVariantes != null) 'tieneVariantes': tieneVariantes,
        if (esCombo != null) 'esCombo': esCombo,
        if (tipoPrecioCombo != null) 'tipoPrecioCombo': tipoPrecioCombo,
        if (imagenesIds != null) 'imagenesIds': imagenesIds,
        if (configuracionPrecioId != null)
          'configuracionPrecioId': configuracionPrecioId,
      };

      final producto = await _remoteDataSource.crearProducto(data);
      return Success(producto.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<ProductosPaginados>> getProductos({
    required String empresaId,
    String? sedeId,
    required ProductoFiltros filtros,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final response = await _remoteDataSource.getProductos(
        empresaId: empresaId,
        sedeId: sedeId,
        filtros: filtros,
      );

      final dataList = response['data'] as List;

      // Parsear los productos del campo 'data' como ProductoListItem para la lista
      final productos = dataList
          .map((json) =>
              ProductoListItemModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // También parsear como Producto completo para el cache (evita peticiones duplicadas)
      final fullProductosCache = <String, dynamic>{};
      for (final json in dataList) {
        final productoCompleto = ProductoModel.fromJson(json as Map<String, dynamic>);
        fullProductosCache[productoCompleto.id] = productoCompleto.toEntity();
      }

      // Parsear la metadata de paginación
      final meta = response['meta'] as Map<String, dynamic>;

      final paginados = ProductosPaginados(
        data: productos,
        total: meta['total'] as int,
        page: meta['page'] as int,
        pageSize: meta['pageSize'] as int,
        totalPages: meta['totalPages'] as int,
        offset: meta['offset'] as int,
        hasNext: meta['hasNext'] as bool,
        hasPrevious: meta['hasPrevious'] as bool,
        fullProductosCache: fullProductosCache, // ✅ Cache de productos completos
      );

      return Success(paginados);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Producto>> getProducto({
    required String productoId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final producto = await _remoteDataSource.getProducto(
        productoId: productoId,
        empresaId: empresaId,
      );
      return Success(producto.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Producto>> actualizarProducto({
    required String productoId,
    required String empresaId,
    String? sedeId,
    String? unidadMedidaId,
    String? empresaCategoriaId,
    String? empresaMarcaId,
    String? sku,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioCosto,
    // DEPRECATED: Stock ahora se maneja mediante ProductoStock por sede
    // int? stock,
    // int? stockMinimo,
    double? peso,
    Map<String, dynamic>? dimensiones,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? descuentoMaximo,
    bool? visibleMarketplace,
    bool? destacado,
    int? ordenMarketplace,
    bool? enOferta,
    bool? tieneVariantes,
    bool? esCombo,
    String? tipoPrecioCombo,
    double? precioOferta,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    List<String>? imagenesIds,
    String? configuracionPrecioId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        // NO enviar sedeId - la sede no se puede cambiar después de crear el producto
        if (unidadMedidaId != null) 'unidadMedidaId': unidadMedidaId,
        if (empresaCategoriaId != null)
          'empresaCategoriaId': empresaCategoriaId,
        if (empresaMarcaId != null) 'empresaMarcaId': empresaMarcaId,
        if (sku != null) 'sku': sku,
        if (codigoBarras != null) 'codigoBarras': codigoBarras,
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        // ❌ DEPRECADO: Precio, precioCosto y ofertas ahora se manejan en ProductoStock por sede
        // NO se deben enviar al actualizar el producto base
        // if (precio != null) 'precio': precio,
        // if (precioCosto != null) 'precioCosto': precioCosto,
        // if (enOferta != null) 'enOferta': enOferta,
        // if (precioOferta != null) 'precioOferta': precioOferta,
        // if (fechaInicioOferta != null) 'fechaInicioOferta': fechaInicioOferta.toIso8601String(),
        // if (fechaFinOferta != null) 'fechaFinOferta': fechaFinOferta.toIso8601String(),
        // DEPRECATED: Stock ahora se maneja mediante ProductoStock por sede
        // if (stock != null) 'stock': stock,
        // if (stockMinimo != null) 'stockMinimo': stockMinimo,
        if (peso != null) 'peso': peso,
        if (dimensiones != null) 'dimensiones': dimensiones,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (impuestoPorcentaje != null)
          'impuestoPorcentaje': impuestoPorcentaje,
        if (descuentoMaximo != null) 'descuentoMaximo': descuentoMaximo,
        if (visibleMarketplace != null)
          'visibleMarketplace': visibleMarketplace,
        if (destacado != null) 'destacado': destacado,
        if (ordenMarketplace != null) 'ordenMarketplace': ordenMarketplace,
        if (tieneVariantes != null) 'tieneVariantes': tieneVariantes,
        if (esCombo != null) 'esCombo': esCombo,
        if (tipoPrecioCombo != null) 'tipoPrecioCombo': tipoPrecioCombo,
        if (imagenesIds != null) 'imagenesIds': imagenesIds,
        if (configuracionPrecioId != null)
          'configuracionPrecioId': configuracionPrecioId,
      };

      final producto = await _remoteDataSource.actualizarProducto(
        productoId: productoId,
        empresaId: empresaId,
        data: data,
      );
      return Success(producto.toEntity());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> eliminarProducto({
    required String productoId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarProducto(
        productoId: productoId,
        empresaId: empresaId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> actualizarStock({
    required String productoId,
    required String empresaId,
    required String sedeId,
    required int cantidad,
    required String operacion,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.actualizarStock(
        productoId: productoId,
        empresaId: empresaId,
        sedeId: sedeId,
        cantidad: cantidad,
        operacion: operacion,
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
  Future<Resource<int>> getStockTotal({
    required String productoId,
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final stockTotal = await _remoteDataSource.getStockTotal(
        productoId: productoId,
        empresaId: empresaId,
      );
      return Success(stockTotal);
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Producto>>> getProductosDisponiblesParaCombo({
    required String empresaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final productos = await _remoteDataSource.getProductosDisponiblesParaCombo(
        empresaId: empresaId,
      );
      return Success(productos.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Error(
        e.toString().replaceFirst('Exception: ', ''),
        errorCode: 'SERVER_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> ajusteMasivoPrecios({
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
      final resultado = await _remoteDataSource.ajusteMasivoPrecios(
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

  // ========================================
  // INCIDENCIAS DE TRANSFERENCIAS
  // ========================================

  @override
  Future<Resource<dynamic>> recibirTransferenciaConIncidencias({
    required String transferenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.recibirTransferenciaConIncidencias(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        request: request,
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
  Future<Resource<List<dynamic>>> listarIncidencias({
    required String empresaId,
    bool? resuelto,
    String? tipo,
    String? sedeId,
    String? transferenciaId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.listarIncidencias(
        empresaId: empresaId,
        resuelto: resuelto,
        tipo: tipo,
        sedeId: sedeId,
        transferenciaId: transferenciaId,
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
  Future<Resource<dynamic>> resolverIncidencia({
    required String incidenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final resultado = await _remoteDataSource.resolverIncidencia(
        incidenciaId: incidenciaId,
        empresaId: empresaId,
        request: request,
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
