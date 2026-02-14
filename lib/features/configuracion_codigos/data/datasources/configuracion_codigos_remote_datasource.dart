import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_codigos_model.dart';

/// Data source remoto para operaciones de configuración de códigos
@lazySingleton
class ConfiguracionCodigosRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionCodigosRemoteDataSource(this._dioClient);

  /// Obtener configuración de códigos de una empresa
  ///
  /// GET /api/configuracion-codigos/:empresaId
  Future<ConfiguracionCodigosModel> getConfiguracion(String empresaId) async {
    final response = await _dioClient.get(
      '${ApiConstants.configuracionCodigos}/$empresaId',
    );

    return ConfiguracionCodigosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Actualizar configuración de productos
  ///
  /// PUT /api/configuracion-codigos/:empresaId/productos
  Future<ConfiguracionCodigosModel> updateConfigProductos({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCodigos}/$empresaId/productos',
      data: data ?? {},
    );

    return ConfiguracionCodigosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Actualizar configuración de variantes
  ///
  /// PUT /api/configuracion-codigos/:empresaId/variantes
  Future<ConfiguracionCodigosModel> updateConfigVariantes({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCodigos}/$empresaId/variantes',
      data: data ?? {},
    );

    return ConfiguracionCodigosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Actualizar configuración de servicios
  ///
  /// PUT /api/configuracion-codigos/:empresaId/servicios
  Future<ConfiguracionCodigosModel> updateConfigServicios({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCodigos}/$empresaId/servicios',
      data: data ?? {},
    );

    return ConfiguracionCodigosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Actualizar configuración de ventas (Notas de Venta)
  ///
  /// PUT /api/configuracion-codigos/:empresaId/ventas
  Future<ConfiguracionCodigosModel> updateConfigVentas({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.configuracionCodigos}/$empresaId/ventas',
      data: data ?? {},
    );

    return ConfiguracionCodigosModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Vista previa de código
  ///
  /// POST /api/configuracion-codigos/:empresaId/preview
  Future<PreviewCodigoModel> previewCodigo({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.configuracionCodigos}/$empresaId/preview',
      data: data,
    );

    return PreviewCodigoModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Sincronizar contador con estado real de BD
  ///
  /// POST /api/configuracion-codigos/:empresaId/sincronizar/:tipo
  Future<Map<String, dynamic>> sincronizarContador({
    required String empresaId,
    required String tipo,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.configuracionCodigos}/$empresaId/sincronizar/$tipo',
    );

    return response.data as Map<String, dynamic>;
  }
}
