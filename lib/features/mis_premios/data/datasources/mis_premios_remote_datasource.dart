import 'package:injectable/injectable.dart';

import '../../../../core/network/dio_client.dart';
import '../models/premio_cliente_model.dart';

@lazySingleton
class MisPremiosRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/marketplace/mis-premios';

  MisPremiosRemoteDataSource(this._dioClient);

  /// GET /marketplace/mis-premios
  Future<List<PremioClienteModel>> getMisPremios() async {
    final response = await _dioClient.get(_basePath);
    final responseData = response.data;
    final List items = responseData is List ? responseData : const [];
    return items
        .map((e) => PremioClienteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /marketplace/mis-premios/:id
  Future<PremioClienteModel> getMiPremio(String id) async {
    final response = await _dioClient.get('$_basePath/$id');
    return PremioClienteModel.fromJson(response.data as Map<String, dynamic>);
  }
}
