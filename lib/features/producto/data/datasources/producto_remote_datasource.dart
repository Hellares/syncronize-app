import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/producto_model.dart';
import '../models/producto_variante_model.dart';
import '../models/producto_atributo_model.dart';
import '../../domain/entities/producto_filtros.dart';

/// Data source remoto para operaciones de productos
@lazySingleton
class ProductoRemoteDataSource {
  final DioClient _dioClient;

  ProductoRemoteDataSource(this._dioClient);

  /// Crea un nuevo producto
  ///
  /// POST /api/productos
  Future<ProductoModel> crearProducto(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.productos,
      data: data,
    );

    return ProductoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene lista paginada de productos con filtros
  ///
  /// GET /api/productos?page=1&limit=10&...
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<Map<String, dynamic>> getProductos({
    required String empresaId,
    String? sedeId,
    required ProductoFiltros filtros,
  }) async {
    final queryParams = {
      ...filtros.toQueryParams(),
      if (sedeId != null) 'sedeId': sedeId,
    };

    final response = await _dioClient.get(
      ApiConstants.productos,
      queryParameters: queryParams,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene un producto por ID
  ///
  /// GET /api/productos/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<ProductoModel> getProducto({
    required String productoId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/$productoId',
    );

    return ProductoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza un producto existente
  ///
  /// PUT /api/productos/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<ProductoModel> actualizarProducto({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.productos}/$productoId',
      data: data,
    );

    return ProductoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina un producto (soft delete)
  ///
  /// DELETE /api/productos/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<void> eliminarProducto({
    required String productoId,
    required String empresaId,
  }) async {
    await _dioClient.delete(
      '${ApiConstants.productos}/$productoId',
    );
  }

  /// Obtiene el stock total de un producto (incluyendo variantes)
  ///
  /// GET /api/productos/:id/stock-total
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<int> getStockTotal({
    required String productoId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/$productoId/stock-total',
    );

    final data = response.data as Map<String, dynamic>;
    return data['stockTotal'] as int? ?? 0;
  }

  /// Obtiene productos disponibles para usar como componentes de combo
  ///
  /// GET /api/productos/disponibles-para-combo
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<List<ProductoModel>> getProductosDisponiblesParaCombo({
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/disponibles-para-combo',
    );

    // El backend retorna estructura paginada {data: [...], meta: {...}}
    final responseData = response.data as Map<String, dynamic>;
    final List<dynamic> data = responseData['data'] as List<dynamic>;

    return data
        .map((json) => ProductoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // =========================================
  // MÉTODOS PARA VARIANTES
  // =========================================

  /// Crea una nueva variante para un producto
  ///
  /// POST /api/productos/:productoId/variantes
  Future<ProductoVarianteModel> crearVariante({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.productos}/$productoId/variantes',
      data: data,
    );

    return ProductoVarianteModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Obtiene todas las variantes de un producto
  ///
  /// GET /api/productos/:productoId/variantes
  Future<List<ProductoVarianteModel>> getVariantes({
    required String productoId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/$productoId/variantes',
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) =>
            ProductoVarianteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene una variante por ID
  ///
  /// GET /api/productos/variantes/:varianteId
  Future<ProductoVarianteModel> getVariante({
    required String varianteId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/variantes/$varianteId',
    );

    return ProductoVarianteModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza una variante
  ///
  /// PUT /api/productos/variantes/:varianteId
  Future<ProductoVarianteModel> actualizarVariante({
    required String varianteId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.productos}/variantes/$varianteId',
      data: data,
    );

    return ProductoVarianteModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Elimina una variante
  ///
  /// DELETE /api/productos/variantes/:varianteId
  Future<void> eliminarVariante({
    required String varianteId,
    required String empresaId,
  }) async {
    await _dioClient.delete(
      '${ApiConstants.productos}/variantes/$varianteId',
    );
  }

  /// Actualiza el stock de una variante
  ///
  /// PATCH /api/productos/variantes/:varianteId/stock
  Future<ProductoVarianteModel> actualizarStockVariante({
    required String varianteId,
    required String empresaId,
    required int cantidad,
  }) async {
    final response = await _dioClient.patch(
      '${ApiConstants.productos}/variantes/$varianteId/stock',
      data: {'cantidad': cantidad},
    );

    return ProductoVarianteModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Genera variantes automáticamente por combinación de atributos
  ///
  /// POST /api/productos/:productoId/variantes/generar-combinaciones
  Future<List<ProductoVarianteModel>> generarCombinaciones({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.productos}/$productoId/variantes/generar-combinaciones',
      data: data,
    );

    final List<dynamic> responseData = response.data as List<dynamic>;
    return responseData
        .map((e) =>
            ProductoVarianteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========================================
  // MÉTODOS PARA ATRIBUTOS (PLANTILLAS)
  // =========================================

  /// Crea un nuevo atributo de producto (plantilla)
  ///
  /// POST /api/producto-atributos
  Future<ProductoAtributoModel> crearAtributo({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/producto-atributos',
      data: data,
    );

    return ProductoAtributoModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Obtiene todos los atributos de la empresa (plantillas)
  ///
  /// GET /api/producto-atributos
  Future<List<ProductoAtributoModel>> getAtributos({
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '/producto-atributos',
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) =>
            ProductoAtributoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene atributos por categoría
  ///
  /// GET /api/producto-atributos/categoria/:categoriaId
  Future<List<ProductoAtributoModel>> getAtributosPorCategoria({
    required String categoriaId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '/producto-atributos/categoria/$categoriaId',
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) =>
            ProductoAtributoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un atributo por ID
  ///
  /// GET /api/producto-atributos/:atributoId
  Future<ProductoAtributoModel> getAtributo({
    required String atributoId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '/producto-atributos/$atributoId',
    );

    return ProductoAtributoModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza un atributo
  ///
  /// PUT /api/producto-atributos/:atributoId
  Future<ProductoAtributoModel> actualizarAtributo({
    required String atributoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '/producto-atributos/$atributoId',
      data: data,
    );

    return ProductoAtributoModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Elimina un atributo
  ///
  /// DELETE /api/producto-atributos/:atributoId
  Future<void> eliminarAtributo({
    required String atributoId,
    required String empresaId,
  }) async {
    await _dioClient.delete(
      '/producto-atributos/$atributoId',
    );
  }

  // =========================================
  // MÉTODOS PARA VALORES DE ATRIBUTOS
  // =========================================

  /// Asigna atributos a un producto base
  ///
  /// POST /api/productos/:productoId/atributos
  Future<void> setProductoAtributos({
    required String productoId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    await _dioClient.post(
      '${ApiConstants.productos}/$productoId/atributos',
      data: data,
    );
  }

  /// Obtiene los atributos de un producto base
  ///
  /// GET /api/productos/:productoId/atributos
  Future<List<Map<String, dynamic>>> getProductoAtributos({
    required String productoId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/$productoId/atributos',
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Asigna atributos a una variante
  ///
  /// POST /api/productos/variantes/:varianteId/atributos
  Future<void> setVarianteAtributos({
    required String varianteId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    await _dioClient.post(
      '${ApiConstants.productos}/variantes/$varianteId/atributos',
      data: data,
    );
  }

  /// Obtiene los atributos de una variante
  ///
  /// GET /api/productos/variantes/:varianteId/atributos
  Future<List<Map<String, dynamic>>> getVarianteAtributos({
    required String varianteId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.productos}/variantes/$varianteId/atributos',
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Ajuste masivo de precios
  ///
  /// POST /api/productos/ajuste-masivo-precios
  Future<Map<String, dynamic>> ajusteMasivoPrecios({
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.productos}/ajuste-masivo-precios',
      data: dto,
    );

    return response.data as Map<String, dynamic>;
  }

  // ========================================
  // INCIDENCIAS DE TRANSFERENCIAS
  // ========================================

  /// Recibe una transferencia con manejo detallado de incidencias
  ///
  /// POST /transferencias-stock/:transferenciaId/recibir-con-incidencias
  Future<Map<String, dynamic>> recibirTransferenciaConIncidencias({
    required String transferenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dioClient.post(
      '/transferencias-stock/$transferenciaId/recibir-con-incidencias',
      data: request,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Lista incidencias de transferencias con filtros
  ///
  /// GET /transferencias-stock/incidencias
  Future<List<Map<String, dynamic>>> listarIncidencias({
    required String empresaId,
    bool? resuelto,
    String? tipo,
    String? sedeId,
    String? transferenciaId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (resuelto != null) queryParameters['resuelto'] = resuelto.toString();
    if (tipo != null) queryParameters['tipo'] = tipo;
    if (sedeId != null) queryParameters['sedeId'] = sedeId;
    if (transferenciaId != null) {
      queryParameters['transferenciaId'] = transferenciaId;
    }

    final response = await _dioClient.get(
      '/transferencias-stock/incidencias',
      queryParameters: queryParameters,
    );

    return (response.data as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// Resuelve una incidencia tomando una acción específica
  ///
  /// POST /transferencias-stock/incidencias/:incidenciaId/resolver
  Future<Map<String, dynamic>> resolverIncidencia({
    required String incidenciaId,
    required String empresaId,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dioClient.post(
      '/transferencias-stock/incidencias/$incidenciaId/resolver',
      data: request,
    );

    return response.data as Map<String, dynamic>;
  }
}
