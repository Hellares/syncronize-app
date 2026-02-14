import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_precio_model.dart';

/// Data source remoto para operaciones de configuraciones de precios
@lazySingleton
class ConfiguracionPrecioRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionPrecioRemoteDataSource(this._dioClient);

  /// Crea una nueva configuración de precios
  ///
  /// POST /api/configuraciones-precio
  Future<ConfiguracionPrecioModel> crear(
    ConfiguracionPrecioDto dto,
  ) async {
    final response = await _dioClient.post(
      ApiConstants.configuracionesPrecios,
      data: dto.toJson(),
    );

    return ConfiguracionPrecioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Obtiene todas las configuraciones de precios de la empresa
  ///
  /// GET /api/configuraciones-precio
  Future<List<ConfiguracionPrecioModel>> obtenerTodas() async {
    final response = await _dioClient.get(
      ApiConstants.configuracionesPrecios,
    );

    final list = response.data as List;
    return list
        .map((json) =>
            ConfiguracionPrecioModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene una configuración por ID
  ///
  /// GET /api/configuraciones-precio/:id
  Future<ConfiguracionPrecioModel> obtenerPorId(
    String configuracionId,
  ) async {
    final response = await _dioClient.get(
      '${ApiConstants.configuracionesPrecios}/$configuracionId',
    );

    return ConfiguracionPrecioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Actualiza una configuración de precios
  ///
  /// PATCH /api/configuraciones-precio/:id
  Future<ConfiguracionPrecioModel> actualizar(
    String configuracionId,
    ConfiguracionPrecioDto dto,
  ) async {
    final response = await _dioClient.patch(
      '${ApiConstants.configuracionesPrecios}/$configuracionId',
      data: dto.toJson(),
    );

    return ConfiguracionPrecioModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Elimina una configuración de precios
  ///
  /// DELETE /api/configuraciones-precio/:id
  Future<void> eliminar(String configuracionId) async {
    await _dioClient.delete(
      '${ApiConstants.configuracionesPrecios}/$configuracionId',
    );
  }
}
