import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campana_model.dart';

@lazySingleton
class PromocionRemoteDataSource {
  final DioClient _dioClient;

  PromocionRemoteDataSource(this._dioClient);

  /// GET /promociones/campanas
  Future<Map<String, dynamic>> getCampanas({
    required int page,
    required int limit,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.promociones}/campanas',
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /promociones/campana
  Future<CampanaModel> crearCampana(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      '${ApiConstants.promociones}/campana',
      data: data,
    );
    return CampanaModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /promociones/productos-en-oferta
  Future<List<ProductoEnOfertaModel>> getProductosEnOferta() async {
    final response = await _dioClient.get(
      '${ApiConstants.promociones}/productos-en-oferta',
    );
    final list = response.data as List;
    return list
        .map((e) => ProductoEnOfertaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
