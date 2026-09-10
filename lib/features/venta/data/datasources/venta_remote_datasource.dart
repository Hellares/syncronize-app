import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
import '../../domain/entities/reversion_total.dart';
import '../models/venta_model.dart';

@lazySingleton
class VentaRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/ventas';

  VentaRemoteDataSource(this._dioClient);

  // --- Fotos de la venta (como se vendio, como se entrega) ------------
  //
  // Es evidencia INTERNA: no viaja al comprobante ni al ticket del cliente.
  //
  // 🔴 Van por `/ventas/...` y no por `/storage/upload`: ese exige
  // `MANAGE_SETTINGS`, que es de administrador, y quien saca estas fotos es el
  // CAJERO.

  /// Sube una foto ANTES de que la venta exista; su id viaja en `evidenciaIds`.
  Future<Map<String, dynamic>> subirEvidencia(String filePath) async {
    final nombre = filePath.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(File(filePath).path, filename: nombre),
    });
    final res = await _dioClient.post(
      '$_basePath/evidencia',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  /// Adjunta una foto a una venta YA hecha: la entrega suele pasar horas
  /// despues del cobro, y ahi es cuando se saca la foto de como se entrego.
  Future<Map<String, dynamic>> adjuntarEvidencia(
    String ventaId,
    String filePath,
  ) async {
    final nombre = filePath.split(RegExp(r'[\\/]')).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(File(filePath).path, filename: nombre),
    });
    final res = await _dioClient.post(
      '$_basePath/$ventaId/evidencia',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getEvidencias(String ventaId) async {
    final res = await _dioClient.get('$_basePath/$ventaId/evidencia');
    final data = res.data;
    if (data is! List) return const [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> eliminarEvidencia(String ventaId, String archivoId) async {
    await _dioClient.delete('$_basePath/$ventaId/evidencia/$archivoId');
  }

  Future<VentaModel> crearVenta(Map<String, dynamic> data) async {
    final response = await _dioClient.post(_basePath, data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> crearVentaDesdeCotizacion(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/desde-cotizacion/$cotizacionId',
      data: data,
    );
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> crearYCobrar(Map<String, dynamic> data) async {
    final response = await _dioClient.post('$_basePath/cobrar', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<VentaModel>> getVentas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (estado != null) queryParams['estado'] = estado;
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;
    if (clienteId != null) queryParams['clienteId'] = clienteId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    final data = response.data as List;
    return data
        .map((e) => VentaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /ventas con paginación por CURSOR (patrón estándar — ver
  /// cotizaciones). Con `limit` el backend responde
  /// `{ data, hasMore, nextCursor, resumen }` donde `resumen` agrega TODO
  /// el set filtrado por estado (para el chip del total).
  Future<
      ({
        List<VentaModel> items,
        bool hasMore,
        String? nextCursor,
        List<Map<String, dynamic>> resumen,
      })> getVentasPaginadas({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? search,
    String? canalVenta,
    String? tipoEntrega,
    String? entregaBusqueda,
    String? rucEmisor,
    required int limit,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (sedeId != null) queryParams['sedeId'] = sedeId;
    if (estado != null) queryParams['estado'] = estado;
    if (fechaDesde != null) queryParams['fechaDesde'] = fechaDesde;
    if (fechaHasta != null) queryParams['fechaHasta'] = fechaHasta;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (canalVenta != null) queryParams['canalVenta'] = canalVenta;
    if (tipoEntrega != null) queryParams['tipoEntrega'] = tipoEntrega;
    if (entregaBusqueda != null && entregaBusqueda.isNotEmpty) {
      queryParams['entregaBusqueda'] = entregaBusqueda;
    }
    if (rucEmisor != null) queryParams['rucEmisor'] = rucEmisor;
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    return (
      items: (body['data'] as List)
          .map((e) => VentaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: body['hasMore'] as bool? ?? false,
      nextCursor: body['nextCursor'] as String?,
      resumen: ((body['resumen'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }

  Future<VentaModel> getVenta(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> actualizarVenta(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.put('$_basePath/$id', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> confirmarVenta(String id) async {
    final response = await _dioClient.post('$_basePath/$id/confirmar');
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> procesarPago(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post('$_basePath/$id/pago', data: data);
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> anularVenta(String id, {
    required String autorizadoPorId,
    required String motivo,
  }) async {
    final response = await _dioClient.post('$_basePath/$id/anular', data: {
      'autorizadoPorId': autorizadoPorId,
      'motivo': motivo,
    });
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VentaModel> generarComprobante(String id, {
    required String tipoComprobante,
    String? tipoDocumentoCliente,
    String? documentoCliente,
  }) async {
    final response = await _dioClient.post('$_basePath/$id/generar-comprobante', data: {
      'tipoComprobante': tipoComprobante,
      if (tipoDocumentoCliente != null) 'tipoDocumentoCliente': tipoDocumentoCliente,
      if (documentoCliente != null) 'documentoCliente': documentoCliente,
    });
    return VentaModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── SUNAT / Nubefact ──

  Future<Map<String, dynamic>> reenviarASunat(String comprobanteId) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/enviar');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> anularComprobante(String comprobanteId, String motivo) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/anular', data: {
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Reversión total post-anulación ──

  Future<ReversionTotal> crearReversionTotal(String ventaId, {String? motivo}) async {
    final response = await _dioClient.post(
      '/devoluciones-venta/venta/$ventaId/reversion-total',
      data: { if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim() },
    );
    return ReversionTotal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReversionTotal?> obtenerReversionTotal(String ventaId) async {
    final response = await _dioClient.get(
      '/devoluciones-venta/venta/$ventaId/reversion-total',
    );
    final data = response.data;
    if (data == null || data is! Map<String, dynamic> || data.isEmpty) {
      return null;
    }
    return ReversionTotal.fromJson(data);
  }

  Future<Map<String, dynamic>> crearNotaCredito(String comprobanteId, {
    required String sedeId,
    required int tipoNota,
    required String motivo,
  }) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/nota-credito', data: {
      'sedeId': sedeId,
      'tipoNota': tipoNota,
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> crearNotaDebito(String comprobanteId, {
    required String sedeId,
    required int tipoNota,
    required String motivo,
  }) async {
    final response = await _dioClient.post('/sunat/comprobantes/$comprobanteId/nota-debito', data: {
      'sedeId': sedeId,
      'tipoNota': tipoNota,
      'motivo': motivo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<EmisorItem>> listarEmisores() async {
    final response = await _dioClient.get('/sunat/emisores');
    final list = response.data as List<dynamic>;
    return list.map((e) => EmisorItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getConfiguracionSunat({String? sedeId}) async {
    final params = <String, dynamic>{};
    if (sedeId != null) params['sedeId'] = sedeId;
    final response = await _dioClient.get('/sunat/configuracion', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /ventas/:id/envio — upsert de los datos del despacho (marca la
  /// venta como conEnvio).
  Future<void> upsertEnvio(String ventaId, Map<String, dynamic> data) async {
    await _dioClient.put('/ventas/$ventaId/envio', data: data);
  }

  /// PATCH /ventas/:id/envio/rotulo-impreso
  Future<void> marcarRotuloEnvioImpreso(String ventaId) async {
    await _dioClient.patch('/ventas/$ventaId/envio/rotulo-impreso');
  }

  /// GET /ventas/envio/ultimo?clienteId= — último envío registrado para el
  /// cliente (prefill del sheet: la agencia/destino se repite entre ventas).
  Future<Map<String, dynamic>?> getUltimoEnvioCliente(String clienteId) async {
    final response = await _dioClient.get(
      '/ventas/envio/ultimo',
      queryParameters: {'clienteId': clienteId},
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  Future<VentaModel?> buscarPorCodigo(String codigo) async {
    try {
      final response = await _dioClient.get(
        '$_basePath/buscar',
        queryParameters: {'codigo': codigo},
      );
      if (response.data == null) return null;
      return VentaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getResumen({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/resumen',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
