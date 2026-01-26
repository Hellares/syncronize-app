import '../../../../core/utils/resource.dart';
import '../entities/proveedor.dart';
import '../entities/proveedor_evaluacion.dart';

/// Repository interface para operaciones de proveedores
abstract class ProveedorRepository {
  /// Obtiene la lista de proveedores de una empresa
  Future<Resource<List<Proveedor>>> getProveedores({
    required String empresaId,
    bool includeInactive = false,
  });

  /// Obtiene un proveedor específico por ID
  Future<Resource<Proveedor>> getProveedor({
    required String empresaId,
    required String proveedorId,
  });

  /// Crea un nuevo proveedor
  Future<Resource<Proveedor>> crearProveedor({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  /// Actualiza los datos de un proveedor
  Future<Resource<Proveedor>> actualizarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  });

  /// Elimina un proveedor (soft delete)
  Future<Resource<void>> eliminarProveedor({
    required String empresaId,
    required String proveedorId,
    String? motivo,
  });

  /// Evalúa un proveedor
  Future<Resource<ProveedorEvaluacion>> evaluarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  });

  /// Obtiene las evaluaciones de un proveedor
  Future<Resource<List<ProveedorEvaluacion>>> getEvaluaciones({
    required String empresaId,
    required String proveedorId,
  });
}
