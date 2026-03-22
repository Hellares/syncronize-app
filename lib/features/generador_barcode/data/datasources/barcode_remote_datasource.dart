import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/barcode_item_model.dart';

@lazySingleton
class BarcodeRemoteDataSource {
  final DioClient _dioClient;
  static const String _basePath = '/productos';

  BarcodeRemoteDataSource(this._dioClient);

  Future<List<BarcodeItemModel>> getProductosSinBarcode({String? sedeId}) async {
    final queryParams = <String, dynamic>{};
    if (sedeId != null) queryParams['sedeId'] = sedeId;

    final response = await _dioClient.get(
      '$_basePath/sin-codigo-barras',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => BarcodeItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GenerarCodigosResultModel> generarCodigos(
    List<String> productoIds,
    String formato,
  ) async {
    final response = await _dioClient.post(
      '$_basePath/generar-codigos-barras',
      data: {
        'productoIds': productoIds,
        'formato': formato,
      },
    );
    return GenerarCodigosResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
