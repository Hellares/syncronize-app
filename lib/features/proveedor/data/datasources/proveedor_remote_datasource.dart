import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/proveedor_model.dart';
import '../models/proveedor_evaluacion_model.dart';

/// Data source remoto para operaciones de proveedores
@lazySingleton
class ProveedorRemoteDataSource {
  final DioClient _dioClient;

  ProveedorRemoteDataSource(this._dioClient);

  /// Obtiene lista de proveedores
  ///
  /// GET /api/empresas/:empresaId/proveedores
  Future<List<ProveedorModel>> getProveedores({
    required String empresaId,
    bool includeInactive = false,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/proveedores',
      queryParameters: {
        if (includeInactive) 'includeInactive': 'true',
      },
    );

    final data = response.data as List;
    return data
        .map((json) => ProveedorModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un proveedor por ID
  ///
  /// GET /api/empresas/:empresaId/proveedores/:id
  Future<ProveedorModel> getProveedor({
    required String empresaId,
    required String proveedorId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/proveedores/$proveedorId',
    );

    return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Crea un nuevo proveedor
  ///
  /// POST /api/empresas/:empresaId/proveedores
  Future<ProveedorModel> crearProveedor({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/proveedores',
      data: data,
    );

    return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza un proveedor
  ///
  /// PUT /api/empresas/:empresaId/proveedores/:id
  Future<ProveedorModel> actualizarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '/empresas/$empresaId/proveedores/$proveedorId',
      data: data,
    );

    return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina un proveedor (soft delete)
  ///
  /// DELETE /api/empresas/:empresaId/proveedores/:id
  Future<void> eliminarProveedor({
    required String empresaId,
    required String proveedorId,
    String? motivo,
  }) async {
    await _dioClient.delete(
      '/empresas/$empresaId/proveedores/$proveedorId',
      data: motivo != null ? {'motivo': motivo} : null,
    );
  }

  /// Evalúa un proveedor
  ///
  /// POST /api/empresas/:empresaId/proveedores/:id/evaluar
  Future<ProveedorEvaluacionModel> evaluarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/proveedores/$proveedorId/evaluar',
      data: data,
    );

    return ProveedorEvaluacionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Obtiene evaluaciones de un proveedor
  ///
  /// GET /api/empresas/:empresaId/proveedores/:id/evaluaciones
  Future<List<ProveedorEvaluacionModel>> getEvaluaciones({
    required String empresaId,
    required String proveedorId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/proveedores/$proveedorId/evaluaciones',
    );

    final data = response.data as List;
    return data
        .map((json) =>
            ProveedorEvaluacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
