import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/libro_contable_model.dart';

@lazySingleton
class LibroContableRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/libro-contable';

  LibroContableRemoteDataSource(this._dioClient);

  Future<LibroContableModel> getLibro({
    required int mes,
    required int anio,
  }) async {
    final response = await _dioClient.get(
      _basePath,
      queryParameters: {
        'mes': mes,
        'anio': anio,
      },
    );

    return LibroContableModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
