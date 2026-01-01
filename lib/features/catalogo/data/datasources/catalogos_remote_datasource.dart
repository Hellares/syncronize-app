import 'package:injectable/injectable.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/catalogo_preview_model.dart';

/// Interfaz del datasource remoto de catálogos
abstract class CatalogosRemoteDataSource {
  /// Obtener preview de catálogos según rubro
  Future<CatalogoPreviewModel> getCatalogoPreview(String rubro);
}

/// Implementación del datasource remoto
@LazySingleton(as: CatalogosRemoteDataSource)
class CatalogosRemoteDataSourceImpl implements CatalogosRemoteDataSource {
  final DioClient _client;

  CatalogosRemoteDataSourceImpl(this._client);

  @override
  Future<CatalogoPreviewModel> getCatalogoPreview(String rubro) async {
    try {
      final response = await _client.get(
        '${ApiConstants.catalogos}/preview/$rubro',
      );

      return CatalogoPreviewModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
