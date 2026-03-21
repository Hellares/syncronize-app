import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categoria_gasto_model.dart';

@lazySingleton
class CategoriaGastoRemoteDataSource {
  final DioClient _dioClient;

  static const String _basePath = '/categorias-gasto';

  CategoriaGastoRemoteDataSource(this._dioClient);

  Future<List<CategoriaGastoModel>> listar({String? tipo}) async {
    final queryParams = <String, dynamic>{};
    if (tipo != null) queryParams['tipo'] = tipo;

    final response = await _dioClient.get(
      _basePath,
      queryParameters: queryParams,
    );

    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => CategoriaGastoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoriaGastoModel> crear({
    required String nombre,
    required String tipo,
    String? color,
    String? icono,
  }) async {
    final data = <String, dynamic>{
      'nombre': nombre,
      'tipo': tipo,
    };
    if (color != null) data['color'] = color;
    if (icono != null) data['icono'] = icono;

    final response = await _dioClient.post(_basePath, data: data);
    return CategoriaGastoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CategoriaGastoModel> actualizar({
    required String id,
    String? nombre,
    String? color,
    String? icono,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (color != null) data['color'] = color;
    if (icono != null) data['icono'] = icono;

    final response = await _dioClient.patch('$_basePath/$id', data: data);
    return CategoriaGastoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar({required String id}) async {
    await _dioClient.delete('$_basePath/$id');
  }
}
