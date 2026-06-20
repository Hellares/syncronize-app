import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../models/cuenta_pagar_model.dart';

@lazySingleton
class CuentasPagarRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/cuentas-por-pagar';

  CuentasPagarRemoteDataSource(this._dioClient);

  Future<List<CuentaPagarModel>> listar({String? estado, String? proveedorId}) async {
    final queryParams = <String, dynamic>{};
    if (estado != null) queryParams['estado'] = estado;
    if (proveedorId != null) queryParams['proveedorId'] = proveedorId;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => CuentaPagarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deuda agrupada por proveedor (vista "Por proveedor").
  Future<List<DeudaProveedor>> getPorProveedor() async {
    final response = await _dioClient.get('$_basePath/por-proveedor');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => DeudaProveedorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Detalle de una cuenta por pagar: ítems comprados + historial de pagos.
  Future<CuentaPagarDetalleModel> getDetalle(String compraId) async {
    final response = await _dioClient.get('$_basePath/$compraId/detalle');
    return CuentaPagarDetalleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ResumenCuentasPagarModel> getResumen() async {
    final response = await _dioClient.get('$_basePath/resumen');
    return ResumenCuentasPagarModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Registra un pago a proveedor sobre una compra (CxP). Backend valida que el
  /// monto no exceda el saldo y registra el EGRESO en caja.
  Future<void> registrarPago(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
    String? comprobanteUrl,
    String? fuente,
    String? bancoId,
  }) async {
    await _dioClient.post(
      '$_basePath/$compraId/pago',
      data: {
        'metodoPago': metodoPago,
        'monto': monto,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
        if (bancoDestino != null && bancoDestino.isNotEmpty) 'bancoDestino': bancoDestino,
        if (cuentaDestino != null && cuentaDestino.isNotEmpty) 'cuentaDestino': cuentaDestino,
        if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) 'comprobanteUrl': comprobanteUrl,
        if (fuente != null) 'fuente': fuente,
        if (bancoId != null && bancoId.isNotEmpty) 'bancoId': bancoId,
      },
    );
  }

  /// Sube un comprobante a S3 SIN asociarlo a un pago. Devuelve la URL para
  /// mandarla en registrarPago (subir al momento de pagar).
  Future<String> subirComprobante(String filePath) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(File(filePath).path, filename: fileName),
    });
    final res = await _dioClient.post(
      '$_basePath/comprobante',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (res.data as Map<String, dynamic>)['url'] as String;
  }

  /// Anula un pago a proveedor (revierte el egreso y devuelve el saldo).
  Future<void> anularPago(String pagoId, {String? motivo}) async {
    await _dioClient.post(
      '$_basePath/pagos/$pagoId/anular',
      data: {if (motivo != null && motivo.isNotEmpty) 'motivo': motivo},
    );
  }

  /// Adjunta un comprobante a un pago YA registrado. Devuelve la URL.
  Future<String> adjuntarComprobantePago(String pagoId, String filePath) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(File(filePath).path, filename: fileName),
    });
    final res = await _dioClient.post(
      '$_basePath/pagos/$pagoId/comprobante',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (res.data as Map<String, dynamic>)['url'] as String;
  }
}
