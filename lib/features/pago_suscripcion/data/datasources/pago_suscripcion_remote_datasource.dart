import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/pago_suscripcion_model.dart';

abstract class PagoSuscripcionRemoteDataSource {
  Future<PagoSuscripcionModel> solicitarPago({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  });
  Future<String> subirComprobante(String pagoId, File file);
  Future<List<PagoSuscripcionModel>> getMisPagos({int page, int pageSize});
  Future<PagoSuscripcionModel> getPagoById(String id);
}

@LazySingleton(as: PagoSuscripcionRemoteDataSource)
class PagoSuscripcionRemoteDataSourceImpl
    implements PagoSuscripcionRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = ApiConstants.pagosSuscripcion;

  PagoSuscripcionRemoteDataSourceImpl(this._dioClient);

  @override
  Future<PagoSuscripcionModel> solicitarPago({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  }) async {
    final response = await _dioClient.post(
      '$_basePath/solicitar',
      data: {
        'planSuscripcionId': planSuscripcionId,
        'periodo': periodo,
        'metodoPago': metodoPago,
      },
    );

    return PagoSuscripcionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<String> subirComprobante(String pagoId, File file) async {
    final fileName = file.path.split('/').last.isNotEmpty
        ? file.path.split('/').last
        : file.path.split('\\').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dioClient.post(
      '$_basePath/$pagoId/comprobante',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    // La API puede retornar la URL directamente o dentro de un objeto
    final responseData = response.data;
    if (responseData is String) return responseData;
    if (responseData is Map) {
      return responseData['comprobantePagoUrl'] as String? ??
          responseData['url'] as String? ??
          '';
    }
    return '';
  }

  @override
  Future<List<PagoSuscripcionModel>> getMisPagos({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dioClient.get(
      '$_basePath/mis-pagos',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    final responseData = response.data;
    final List items;
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map && data['items'] is List) {
        items = data['items'] as List;
      } else if (data is List) {
        items = data;
      } else if (responseData['items'] is List) {
        items = responseData['items'] as List;
      } else {
        items = [];
      }
    } else if (responseData is List) {
      items = responseData;
    } else {
      items = [];
    }
    return items
        .map((e) => PagoSuscripcionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PagoSuscripcionModel> getPagoById(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return PagoSuscripcionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
